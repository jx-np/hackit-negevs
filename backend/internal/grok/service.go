package grok

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"strings"
	"sync"
	"time"
	"unicode"

	"scamshield/internal/moderation"
	"scamshield/internal/reports"
	"scamshield/internal/storage"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Reply-job terminal failure reasons, carried by GrokFailed.
const (
	// ReasonSkipped means no reply was posted because the job was no longer
	// applicable: the post or trigger is invisible, the bot user is missing,
	// the author is the bot itself, or the process is shutting down.
	ReasonSkipped = "skipped"
	// ReasonError means the job ended in an unexpected failure (database
	// error, failed insert, panic).
	ReasonError = "error"
)

// EventPublisher receives progress events for an accepted @help job. It is a
// small interface defined here, where it is consumed, so this package never
// imports the SSE transport. Implementations are called from the request path
// (GrokThinking) and from the job goroutine and must never block.
//
// Contract: every GrokThinking is followed by exactly one GrokReplied or
// GrokFailed, including on panic recovery and process-context cancellation.
type EventPublisher interface {
	// GrokThinking is emitted as soon as a mention is accepted, before the job
	// waits for a concurrency slot.
	GrokThinking(postID, triggerCommentID int64)
	// GrokReplied is emitted after the bot's reply comment is stored. reply is
	// the full stored comment, or nil if loading it back failed.
	GrokReplied(postID, triggerCommentID, replyCommentID int64, fallback bool, reply *moderation.CommentDTO)
	// GrokFailed is emitted when the job ends without a reply being posted.
	GrokFailed(postID, triggerCommentID int64, reason string)
}

// Defaults applied when the caller leaves a field unset.
const (
	// DefaultTimeout is the per-job budget. A reasoning model can be slow, so
	// this is deliberately generous.
	DefaultTimeout = 5 * time.Minute
	// DefaultMaxConcurrent caps how many reply jobs run at once. Jobs beyond it
	// wait for a slot rather than being dropped.
	DefaultMaxConcurrent = 32

	// maxReplyRunes bounds the posted reply. Anything longer is cut at a
	// sentence (or failing that, word) boundary.
	maxReplyRunes = 2000
)

// FallbackReply is posted when the model fails or returns nothing usable. It is
// a calm, non-committal prompt to try again.
const FallbackReply = "Sorry, I couldn't answer that just now. Please try asking again in a little while."

// Job outcomes, used as the "outcome" log field.
const (
	outcomeReplied      = "replied"
	outcomeSkipped      = "skipped"
	outcomeLLMFailed    = "llm_failed"
	outcomeInsertFailed = "insert_failed"
)

// Config configures the production Service.
type Config struct {
	// BaseURL is the OpenAI-compatible API root, e.g.
	// "https://litellm.chimmy.xyz/v1". Requests go to BaseURL +
	// "/chat/completions"; a trailing slash is tolerated.
	BaseURL string
	// APIKey is sent as "Authorization: Bearer <APIKey>". Never logged.
	APIKey string
	// Model is the model name sent in each request.
	Model string
	// Timeout is the per-LLM-request budget. Non-positive falls back to
	// DefaultTimeout.
	Timeout time.Duration
	// MaxConcurrent is the maximum number of simultaneous LLM jobs.
	// Non-positive falls back to DefaultMaxConcurrent.
	MaxConcurrent int
}

// Options configures the transport-agnostic Service built by NewService.
type Options struct {
	// Timeout is the per-job budget. Non-positive falls back to DefaultTimeout.
	Timeout time.Duration
	// MaxConcurrent caps simultaneous jobs. Non-positive falls back to
	// DefaultMaxConcurrent.
	MaxConcurrent int
	// Publisher receives progress events (thinking/replied/failed). Nil is
	// safe and disables event emission.
	Publisher EventPublisher
}

// Service answers @help mentions on community comments. It satisfies the
// moderation.CommentObserver hook: CommentCreated is called synchronously right
// after a comment is stored, so it only filters cheaply and then hands all real
// work (including the database lookups) to a bounded background goroutine.
//
// Jobs derive from the process-lifetime context passed to New/NewService, so
// shutting the process down cancels them.
type Service struct {
	repo      Repository
	llm       LLM
	store     storage.Store
	logger    *slog.Logger
	ctx       context.Context
	timeout   time.Duration
	publisher EventPublisher

	sem chan struct{}
	wg  sync.WaitGroup

	botMu    sync.Mutex
	botID    int64
	botKnown bool
}

// New builds the production Service from a pgx pool, a blob store and an HTTP
// LLM client. ctx is the process lifetime context: background jobs derive from
// it and are cancelled when it is done. store is used only to read a public
// post's already-published PII-redacted images; raw uploads are never read.
// publisher may be nil, which disables progress events.
func New(ctx context.Context, pool *pgxpool.Pool, store storage.Store, cfg Config, logger *slog.Logger, publisher EventPublisher) *Service {
	return NewService(ctx, NewPostgresRepository(pool), NewHTTPLLM(cfg), store, Options{
		Timeout:       cfg.Timeout,
		MaxConcurrent: cfg.MaxConcurrent,
		Publisher:     publisher,
	}, logger)
}

// NewService builds a Service from its ports. It is the seam used by tests. A
// nil ctx falls back to context.Background(); a nil logger to slog.Default(). A
// nil store simply yields text-only replies.
func NewService(ctx context.Context, repo Repository, llm LLM, store storage.Store, opts Options, logger *slog.Logger) *Service {
	if ctx == nil {
		ctx = context.Background()
	}
	if logger == nil {
		logger = slog.Default()
	}
	timeout := opts.Timeout
	if timeout <= 0 {
		timeout = DefaultTimeout
	}
	maxConcurrent := opts.MaxConcurrent
	if maxConcurrent <= 0 {
		maxConcurrent = DefaultMaxConcurrent
	}
	return &Service{
		repo:      repo,
		llm:       llm,
		store:     store,
		logger:    logger,
		ctx:       ctx,
		timeout:   timeout,
		publisher: opts.Publisher,
		sem:       make(chan struct{}, maxConcurrent),
	}
}

// CommentCreated implements the moderation.CommentObserver hook. It is
// non-blocking: it does only constant-time filtering inline, emits the
// grok_thinking progress event, and schedules the real work (database lookups,
// the model call, the reply insert) in a background goroutine.
func (s *Service) CommentCreated(c moderation.Comment) {
	if c.Status != moderation.CommentVisible {
		return
	}
	if !MentionsBot(c.Body) {
		return
	}
	// Emitted here, at the point the job is accepted, so the UI can show
	// "NegevAI is thinking..." immediately even while the job waits for a slot.
	s.publishThinking(c.ReportID, c.ID)
	s.schedule(c.ReportID, c.ID, func() replyResult { return s.handle(c) })
}

// replyResult is the terminal outcome of one job. Exactly one of replied or
// reason drives the event emitted by schedule.
type replyResult struct {
	replied  bool
	replyID  int64
	comment  *moderation.CommentDTO
	fallback bool
	reason   string
}

// schedule runs fn in its own goroutine, bounded by the concurrency semaphore
// and cancelled if the process context is done. It recovers panics so a single
// bad job can never take the process down, and guarantees a terminal event
// after the thinking event: replied on success, failed on every other path
// (including a panic or a context cancellation while waiting for a slot).
func (s *Service) schedule(postID, triggerCommentID int64, fn func() replyResult) {
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()

		terminal := false
		defer func() {
			if r := recover(); r != nil {
				s.logger.Error("grok: reply job panicked",
					"report_id", postID, "comment_id", triggerCommentID, "panic", fmt.Sprint(r))
				if !terminal {
					s.publishFailed(postID, triggerCommentID, ReasonError)
				}
			}
		}()

		select {
		case s.sem <- struct{}{}:
			defer func() { <-s.sem }()
		case <-s.ctx.Done():
			s.publishFailed(postID, triggerCommentID, ReasonSkipped)
			terminal = true
			return
		}

		res := fn()
		if res.replied {
			s.publishReplied(postID, triggerCommentID, res)
		} else {
			reason := res.reason
			if reason == "" {
				reason = ReasonError
			}
			s.publishFailed(postID, triggerCommentID, reason)
		}
		terminal = true
	}()
}

// publishThinking / publishReplied / publishFailed are nil-safe wrappers around
// the optional publisher.
func (s *Service) publishThinking(postID, triggerCommentID int64) {
	if s.publisher != nil {
		s.publisher.GrokThinking(postID, triggerCommentID)
	}
}

func (s *Service) publishReplied(postID, triggerCommentID int64, res replyResult) {
	if s.publisher != nil {
		s.publisher.GrokReplied(postID, triggerCommentID, res.replyID, res.fallback, res.comment)
	}
}

func (s *Service) publishFailed(postID, triggerCommentID int64, reason string) {
	if s.publisher != nil {
		s.publisher.GrokFailed(postID, triggerCommentID, reason)
	}
}

// failure builds a terminal result, downgrading to "skipped" when the process
// context is being cancelled (shutdown is not a bot error).
func (s *Service) failure(reason string) replyResult {
	if s.ctx.Err() != nil {
		reason = ReasonSkipped
	}
	return replyResult{reason: reason}
}

// handle does the actual work for one triggering comment: resolve the bot user,
// assemble the (public only) context, ask the model, and post the reply. It
// always returns a terminal result; every early exit maps to skipped or error.
func (s *Service) handle(c moderation.Comment) replyResult {
	start := time.Now()

	ctx, cancel := context.WithTimeout(s.ctx, s.timeout)
	defer cancel()

	botID, ok := s.botUserID(ctx)
	if !ok {
		return s.failure(ReasonSkipped)
	}
	// Loop prevention. The hook fires for every comment, including the bot's own
	// replies if they ever contained the mention.
	if c.AuthorUserID != nil && *c.AuthorUserID == botID {
		s.logger.Debug("grok: skipped bot-authored comment",
			"comment_id", c.ID, "report_id", c.ReportID, "outcome", outcomeSkipped)
		return s.failure(ReasonSkipped)
	}

	post, found, err := s.repo.PostContext(ctx, c.ReportID)
	if err != nil {
		s.logger.Error("grok: load post context failed",
			"comment_id", c.ID, "report_id", c.ReportID, "error", err)
		return s.failure(ReasonError)
	}
	if !found {
		s.logger.Debug("grok: skipped, post not publicly visible",
			"comment_id", c.ID, "report_id", c.ReportID, "outcome", outcomeSkipped)
		return s.failure(ReasonSkipped)
	}

	// Comment context is advisory: a failure here degrades the answer rather
	// than skipping the reply.
	comments, err := s.repo.RecentComments(ctx, c.ReportID, maxContextComments)
	if err != nil {
		s.logger.Warn("grok: load recent comments failed",
			"comment_id", c.ID, "report_id", c.ReportID, "error", err)
		comments = nil
	}

	// Images are best-effort context: a listing or read failure degrades to a
	// text-only reply rather than skipping. Only a public post's published,
	// PII-redacted report_images are read.
	images := s.loadPostImages(ctx, c.ReportID)

	question := truncateRunes(StripMentions(c.Body), maxQuestionRunes)

	body, retriedTextOnly, llmErr := s.answer(ctx, c.ReportID, post, comments, question, images)

	reply := BotReply{
		ReportID:         c.ReportID,
		AuthorUserID:     botID,
		ParentCommentID:  parentFor(c),
		TriggerCommentID: c.ID,
		Body:             body,
	}
	replyID, inserted, err := s.repo.InsertBotReply(ctx, reply)
	if err != nil {
		s.logger.Error("grok: insert reply failed",
			"comment_id", c.ID, "report_id", c.ReportID,
			"outcome", outcomeInsertFailed, "error", err)
		return s.failure(ReasonError)
	}
	if !inserted {
		s.logger.Debug("grok: skipped, post or trigger no longer visible",
			"comment_id", c.ID, "report_id", c.ReportID, "outcome", outcomeSkipped)
		return s.failure(ReasonSkipped)
	}

	// Load the stored reply so the SSE event carries the same comment shape as
	// the comments endpoint (author label, is_bot, timestamps). A load failure
	// degrades to "no comment payload" rather than losing the terminal event.
	var commentDTO *moderation.CommentDTO
	stored, err := s.repo.GetComment(ctx, replyID)
	if err != nil {
		s.logger.Warn("grok: load stored reply failed",
			"reply_id", replyID, "report_id", c.ReportID, "error", err)
	} else {
		dto := moderation.ToCommentDTO(stored)
		commentDTO = &dto
	}

	s.logger.Info("grok: replied",
		"comment_id", c.ID,
		"reply_id", replyID,
		"report_id", c.ReportID,
		"images", len(images),
		"image_retry_text_only", retriedTextOnly,
		"fallback", llmErr != nil,
		"outcome", outcomeReplied,
		"duration_ms", time.Since(start).Milliseconds(),
	)

	return replyResult{
		replied:  true,
		replyID:  replyID,
		comment:  commentDTO,
		fallback: llmErr != nil,
	}
}

// Wait blocks until every scheduled job has finished, or until ctx is done
// (best-effort drain). It is intended for tests and shutdown.
func (s *Service) Wait(ctx context.Context) {
	if ctx == nil {
		ctx = context.Background()
	}
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()
	select {
	case <-done:
	case <-ctx.Done():
	}
}

// loadPostImages lists and reads a post's published images for model context.
// Any failure degrades to no images so the reply still proceeds text-only.
func (s *Service) loadPostImages(ctx context.Context, reportID int64) []Image {
	refs, err := s.repo.PostImages(ctx, reportID)
	if err != nil {
		s.logger.Warn("grok: load post images failed",
			"report_id", reportID, "error", err)
		return nil
	}
	return loadImages(ctx, s.store, reportID, refs, s.logger)
}

// answer produces the reply body. On any model failure (transport error, empty
// or unusable reply) it logs the failure and returns FallbackReply, so the bot
// always posts exactly one comment. When the model rejects a request that
// carried images with a 4xx, it is retried exactly once without images before
// falling back; 5xx and transport errors are not retried (the gateway already
// retries those). The retried bool reports whether the text-only retry ran. The
// returned error is non-nil whenever the fallback is used; its text never
// contains prompt or model content.
func (s *Service) answer(ctx context.Context, reportID int64, post PostContext, comments []CommentSummary, question string, images []Image) (string, bool, error) {
	raw, err := s.llm.Complete(ctx, buildMessages(post, comments, question, images))
	retriedTextOnly := false
	if err != nil && len(images) > 0 && isLLM4xx(err) {
		// The gateway or model rejected the image payload. Retry once with the
		// same prompt minus the images.
		retriedTextOnly = true
		s.logger.Warn("grok: llm rejected images; retrying text-only",
			"report_id", reportID, "images", len(images))
		raw, err = s.llm.Complete(ctx, buildMessages(post, comments, question, nil))
	}
	if err != nil {
		s.logger.Warn("grok: llm completion failed",
			"report_id", reportID, "outcome", outcomeLLMFailed, "error", err)
		return FallbackReply, retriedTextOnly, err
	}

	body := sanitizeReply(raw)
	if body == "" {
		s.logger.Warn("grok: llm returned empty reply",
			"report_id", reportID, "outcome", outcomeLLMFailed)
		return FallbackReply, retriedTextOnly, ErrEmptyCompletion
	}
	return body, retriedTextOnly, nil
}

// isLLM4xx reports whether err is a *StatusError carrying a 4xx status. It is
// used to decide whether a failed image request is worth retrying text-only.
func isLLM4xx(err error) bool {
	var se *StatusError
	if errors.As(err, &se) {
		return se.Code >= 400 && se.Code < 500
	}
	return false
}

// sanitizeReply post-processes model output before it is stored: it re-scrubs
// for PII (the server never trusts model text), trims, collapses excessive
// blank lines, and caps the length at a boundary.
func sanitizeReply(s string) string {
	s = reports.Scrub(s)
	s = strings.TrimSpace(s)
	s = blankLinePattern.ReplaceAllString(s, "\n\n")
	s = strings.TrimSpace(s)
	return capRunesBoundary(s, maxReplyRunes)
}

// blankLinePattern collapses runs of three or more newlines (optionally with
// intervening spaces/tabs) into a single blank line.
var blankLinePattern = regexp.MustCompile(`\n[ \t]*\n(?:[ \t]*\n)+`)

// capRunesBoundary caps s at max runes, preferring to cut at the last sentence
// boundary, then the last whitespace, and only then mid-word.
func capRunesBoundary(s string, max int) string {
	if max <= 0 {
		return ""
	}
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	// Search the tail quarter for a natural break so short replies are not
	// over-trimmed.
	floor := max - max/4
	for i := max - 1; i >= floor; i-- {
		if isSentenceBoundary(runes[i]) {
			return strings.TrimSpace(string(runes[:i+1]))
		}
	}
	for i := max - 1; i >= floor; i-- {
		if unicode.IsSpace(runes[i]) {
			return strings.TrimSpace(string(runes[:i]))
		}
	}
	return strings.TrimSpace(string(runes[:max]))
}

// isSentenceBoundary reports whether r ends a sentence in one of the scripts the
// pilot targets.
func isSentenceBoundary(r rune) bool {
	switch r {
	case '.', '!', '?', '\n', '。', '！', '？':
		return true
	default:
		return false
	}
}

// parentFor applies the one-level reply rule: a reply to a top-level comment
// threads under it, and a reply to an existing reply threads under that reply's
// parent so the discussion never nests deeper than one level.
func parentFor(c moderation.Comment) *int64 {
	if c.ParentCommentID != nil {
		return c.ParentCommentID
	}
	id := c.ID
	return &id
}

// botUserID resolves and caches the seeded bot user's id. A lookup failure or a
// missing bot user is logged once and reported as not found; the bot never
// creates a user itself.
func (s *Service) botUserID(ctx context.Context) (int64, bool) {
	s.botMu.Lock()
	if s.botKnown {
		id := s.botID
		s.botMu.Unlock()
		return id, id != 0
	}
	s.botMu.Unlock()

	id, found, err := s.repo.BotUserID(ctx)
	if err != nil {
		s.logger.Warn("grok: bot user lookup failed", "error", err)
		return 0, false
	}
	if !found {
		s.logger.Warn("grok: bot user not found; skipping reply")
		return 0, false
	}

	s.botMu.Lock()
	s.botID = id
	s.botKnown = true
	s.botMu.Unlock()
	return id, true
}
