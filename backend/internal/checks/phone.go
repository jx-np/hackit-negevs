package checks

import (
	"context"
	"regexp"
	"strings"
	"time"
)

// Phone-number trust scoring. A trust score is an integer in [0, 100] where 0
// means highly likely to be a scam and 100 means highly trustworthy. A number
// with no data in the scam database scores the neutral default below.
const (
	// TrustScoreMin / TrustScoreMax bound the trust score.
	TrustScoreMin = 0
	TrustScoreMax = 100

	// DefaultTrustScore is returned for a number the database has never seen. It
	// is deliberately mid-range (neither trusted nor risky) so an unknown number
	// is not treated as safe.
	DefaultTrustScore = 60
)

// Trust rating buckets derived from the numeric score. These give clients a
// stable label to render without hard-coding thresholds.
const (
	RatingHighRisk = "high_risk" // 0–39
	RatingUnknown  = "unknown"   // 40–69 (includes the default for unseen numbers)
	RatingTrusted  = "trusted"   // 70–100
)

// ErrInvalidPhoneNumber is returned when a phone number cannot be normalized to
// anything usable (e.g. it contains no digits).
var phoneStripPattern = regexp.MustCompile(`[^\d+]`)

// PhoneTrust is the result of a phone-number trust lookup.
type PhoneTrust struct {
	// PhoneNumber is the normalized number the score applies to.
	PhoneNumber string
	// TrustScore is in [0, 100]; higher is more trustworthy.
	TrustScore int
	// Rating is the categorical bucket for TrustScore.
	Rating string
	// ReportCount is how many scam reports back this number (0 when unseen).
	ReportCount int64
	// Known indicates whether the number was found in the scam database. When
	// false, TrustScore is DefaultTrustScore and ReportCount is 0.
	Known bool
	// Classification is the label assigned by the (separate) classification
	// system for the number's current reporting window. It is an empty string
	// when no active classification applies. The set of possible values is
	// owned by the classification system and intentionally free-form here.
	Classification string
}

// PhoneReputation is the raw datum the repository returns for a number. It is
// derived from community reports within the active reputation window plus any
// active classification. A number with no reports in the window returns
// Found=false.
type PhoneReputation struct {
	Found bool
	// ReportCount is the number of reports within the reputation window.
	ReportCount int64
	// Classification is the active classification label for the number, or an
	// empty string when none applies. It is populated independently of Found so
	// a classified number with no in-window reports still surfaces its label.
	Classification string
}

// PhoneReport is a single community report that a phone number is scam, spam,
// or otherwise unwanted. It is the input to ReportPhoneNumber.
type PhoneReport struct {
	// PhoneNumber is the normalized number being reported.
	PhoneNumber string
	// Reason is a short free-form label (e.g. "scam", "spam", "others"),
	// bounded to maxReasonLength characters.
	Reason string
	// ReporterUserID is the authenticated user who filed the report.
	ReporterUserID int64
}

// maxReasonLength bounds the report reason to keep it a short label rather than
// free text. It matches the CHECK constraint on phone_reports.reason.
const maxReasonLength = 32

// reputationWindow is how far back community reports are counted when deriving
// a number's reputation. Reports older than this stop influencing the score so
// a number that was spoofed or recycled is not penalised forever. It is also the
// cooldown that limits a user to one report per number: a user's previous report
// only blocks a new one while it still falls inside this window, so report expiry
// and the duplicate-report limit always use the same configured period.
const reputationWindow = 30 * 24 * time.Hour

// PhoneRepository is the persistence contract for phone-number reputation
// lookups. It is separate from the main checks Repository so the (future)
// phone-number data source can be implemented and injected independently.
type PhoneRepository interface {
	// GetPhoneReputation returns reputation data for a normalized phone number
	// as of the given time, counting only reports within the reputation window.
	// A number with no in-window reports and no active classification returns
	// Found=false (not an error).
	GetPhoneReputation(ctx context.Context, normalized string, now time.Time) (PhoneReputation, error)
	// InsertPhoneReport appends a community report to the ledger. It is
	// append-only; the classification system reads the ledger separately.
	// It returns ErrPhoneReportDuplicate when the reporter already has an
	// unexpired report for this number.
	InsertPhoneReport(ctx context.Context, report PhoneReport, now time.Time) error
}

// LookupPhoneTrust normalizes the number, queries the reputation source, and
// maps the result to a bounded trust score and rating. Unknown numbers return
// the neutral default score. It never returns an error for an unseen number.
func (s *Service) LookupPhoneTrust(ctx context.Context, rawPhoneNumber string) (PhoneTrust, error) {
	normalized := normalizePhoneNumber(rawPhoneNumber)

	// A number with no usable digits still yields a well-formed neutral result
	// rather than an error, keeping the endpoint simple for clients.
	if normalized == "" {
		return PhoneTrust{
			PhoneNumber: strings.TrimSpace(rawPhoneNumber),
			TrustScore:  DefaultTrustScore,
			Rating:      ratingForScore(DefaultTrustScore),
			ReportCount: 0,
			Known:       false,
		}, nil
	}

	rep, err := s.phones.GetPhoneReputation(ctx, normalized, s.now())
	if err != nil {
		return PhoneTrust{}, err
	}

	if !rep.Found {
		return PhoneTrust{
			PhoneNumber:    normalized,
			TrustScore:     DefaultTrustScore,
			Rating:         ratingForScore(DefaultTrustScore),
			ReportCount:    0,
			Known:          false,
			Classification: rep.Classification,
		}, nil
	}

	score := scoreForReportCount(rep.ReportCount)
	return PhoneTrust{
		PhoneNumber:    normalized,
		TrustScore:     score,
		Rating:         ratingForScore(score),
		ReportCount:    rep.ReportCount,
		Known:          true,
		Classification: rep.Classification,
	}, nil
}

// ReportPhoneNumber records a community report that a phone number is scam,
// spam, or otherwise unwanted. The number is normalized before storage so
// reports and lookups agree. The reason is trimmed and bounded; an empty or
// over-long reason is rejected. The report is appended to the ledger and the
// (separate) classification system derives ratings from the ledger later.
//
// A user may report a given number only once per reputationWindow: a second
// report while the first is still in the window returns ErrPhoneReportDuplicate.
// This bounds the damage a single (or many colluding) account can do to a
// number's reputation by spamming reports, and the limit lapses on its own as
// the earlier report ages out of the window.
func (s *Service) ReportPhoneNumber(ctx context.Context, in PhoneReport) error {
	normalized := normalizePhoneNumber(in.PhoneNumber)
	if normalized == "" {
		return ErrPhoneNumberRequired
	}

	reason := strings.TrimSpace(in.Reason)
	if reason == "" {
		return ErrReasonRequired
	}
	if len(reason) > maxReasonLength {
		return ErrReasonTooLong
	}

	return s.phones.InsertPhoneReport(ctx, PhoneReport{
		PhoneNumber:    normalized,
		Reason:         reason,
		ReporterUserID: in.ReporterUserID,
	}, s.now())
}

// scoreForReportCount derives a bounded trust score from the number of
// community reports within the reputation window. More reports lower the
// score. The mapping is deliberately simple and monotonic: zero reports keeps
// the neutral default, and each report subtracts a fixed amount until the score
// floors at TrustScoreMin. The (future) classification system may supersede
// this heuristic.
func scoreForReportCount(reportCount int64) int {
	if reportCount <= 0 {
		return DefaultTrustScore
	}
	const perReportPenalty = 15
	score := DefaultTrustScore - int(reportCount)*perReportPenalty
	return clampScore(score)
}

// normalizePhoneNumber strips formatting so lookups are consistent. It keeps a
// single leading '+' (country prefix) and digits only; all spaces, hyphens,
// parentheses and other characters are removed.
func normalizePhoneNumber(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}
	hasPlus := strings.HasPrefix(trimmed, "+")
	digits := phoneStripPattern.ReplaceAllString(trimmed, "")
	digits = strings.ReplaceAll(digits, "+", "")
	if digits == "" {
		return ""
	}
	if hasPlus {
		return "+" + digits
	}
	return digits
}

// clampScore constrains a raw score to [TrustScoreMin, TrustScoreMax].
func clampScore(score int) int {
	if score < TrustScoreMin {
		return TrustScoreMin
	}
	if score > TrustScoreMax {
		return TrustScoreMax
	}
	return score
}

// ratingForScore maps a numeric trust score to its categorical bucket.
func ratingForScore(score int) string {
	switch {
	case score < 40:
		return RatingHighRisk
	case score < 70:
		return RatingUnknown
	default:
		return RatingTrusted
	}
}
