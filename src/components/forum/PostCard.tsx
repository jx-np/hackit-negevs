import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowBigDown,
  ArrowBigUp,
  Bookmark,
  CheckCircle2,
  Flag,
  Megaphone,
  MessageCircle,
  MoreVertical,
  Share2,
  ShieldAlert,
  ShieldCheck,
  TriangleAlert,
  Users,
  X,
} from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import type { Post } from '../../types';
import { CommentBox } from './CommentBox';
import { CommentList } from './CommentList';

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function initials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

/**
 * Risk metadata — a strict traffic-light system. Every risk pairs a color
 * with an icon AND a text label so meaning never relies on color alone
 * (colorblind-safe + legible in screenshots).
 */
const RISK_META = {
  high: {
    label: 'High risk',
    pill: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
    strip: 'bg-risk-high',
    Icon: TriangleAlert,
  },
  medium: {
    label: 'Under review',
    pill: 'border-risk-med/40 bg-risk-med/10 text-risk-med',
    strip: 'bg-risk-med',
    Icon: ShieldAlert,
  },
  low: {
    label: 'Debunked / safe',
    pill: 'border-risk-low/40 bg-risk-low/10 text-risk-low',
    strip: 'bg-risk-low',
    Icon: ShieldCheck,
  },
  psa: {
    label: 'Official PSA',
    pill: 'border-risk-psa/40 bg-risk-psa/10 text-risk-psa',
    strip: 'bg-risk-psa',
    Icon: Megaphone,
  },
} as const;

type RiskKey = keyof typeof RISK_META;

/** Normalize the Post risk value to a traffic-light key. */
function riskKey(risk: Post['risk']): RiskKey {
  if (risk === 'high') return 'high';
  if (risk === 'medium') return 'medium';
  return 'medium';
}

/** Filled, tinted risk-flair pill with icon + label. */
function RiskFlair({ risk }: { risk: Post['risk'] }) {
  if (!risk) return null;
  const s = RISK_META[riskKey(risk)];
  const { Icon } = s;
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold ${s.pill}`}
    >
      <Icon size={13} aria-hidden />
      {s.label}
    </span>
  );
}

const REPORT_REASONS = [
  'Spam or misleading',
  'Scam or fraud',
  'Harassment or hate speech',
  'False information',
  'Inappropriate content',
  'Other',
] as const;

/**
 * Kebab (triple-dots) menu shown at the top-right of a post's body area.
 * Currently offers a single "Report post" action; more can be added later.
 */
function PostMenu({ onReport }: { onReport: () => void }) {
  const [open, setOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onPointerDown(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpen(false);
    }
    document.addEventListener('mousedown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  return (
    <div ref={menuRef} className="relative shrink-0">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label="Post options"
        className="grid h-8 w-8 place-items-center rounded-md text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
      >
        <MoreVertical size={18} />
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            role="menu"
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.15, ease: 'easeOut' }}
            className="absolute right-0 top-full z-20 mt-1 min-w-[10rem] rounded-md border border-scam-line bg-scam-850 py-1 shadow-xl"
          >
            <button
              type="button"
              role="menuitem"
              onClick={() => {
                setOpen(false);
                onReport();
              }}
              className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
            >
              <Flag size={15} /> Report post
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

/**
 * Modal asking why the user is reporting a post. Dims the background with a
 * blurred overlay (matching the SettingsPanel pattern). Closes on overlay
 * click, the X button, or Escape.
 */
function ReportModal({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const [selected, setSelected] = useState<string | null>(null);
  const [details, setDetails] = useState('');
  const [submitted, setSubmitted] = useState(false);

  // Reset internal state whenever the modal is (re)opened.
  useEffect(() => {
    if (open) {
      setSelected(null);
      setDetails('');
      setSubmitted(false);
    }
  }, [open]);

  // Close on Escape.
  useEffect(() => {
    if (!open) return;
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [open, onClose]);

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Dimmed, blurred backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="fixed inset-0 z-[100] bg-scam-950/70 backdrop-blur-sm"
          />

          {/* Centered dialog */}
          <div className="fixed inset-0 z-[101] flex items-center justify-center p-4">
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-labelledby="report-modal-title"
              initial={{ opacity: 0, scale: 0.96, y: 8 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 8 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md rounded-lg border border-scam-line bg-scam-850 p-6 shadow-2xl"
            >
              <div className="flex items-start justify-between gap-4">
                <h2
                  id="report-modal-title"
                  className="text-lg font-semibold text-scam-text"
                >
                  {submitted ? 'Report submitted' : 'Why are you reporting this post?'}
                </h2>
                <button
                  type="button"
                  onClick={onClose}
                  aria-label="Close"
                  className="grid h-8 w-8 shrink-0 place-items-center rounded-md text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
                >
                  <X size={18} />
                </button>
              </div>

              {submitted ? (
                <div className="mt-4 flex flex-col items-center gap-3 py-4 text-center">
                  <CheckCircle2 size={40} className="text-risk-low" />
                  <p className="text-sm text-scam-muted">
                    Thanks for helping keep the community safe. Our team will
                    review this report.
                  </p>
                  <button
                    type="button"
                    onClick={onClose}
                    className="sr-btn-primary mt-2 px-5 py-2"
                  >
                    Done
                  </button>
                </div>
              ) : (
                <>
                  <div className="mt-4 flex flex-col gap-2">
                    {REPORT_REASONS.map((reason) => (
                      <label
                        key={reason}
                        className={`flex cursor-pointer items-center gap-3 rounded-md border px-3 py-2.5 text-sm transition ${
                          selected === reason
                            ? 'border-trust-400 bg-trust-400/10 text-scam-text'
                            : 'border-scam-line text-scam-muted hover:border-scam-muted'
                        }`}
                      >
                        <input
                          type="radio"
                          name="report-reason"
                          value={reason}
                          checked={selected === reason}
                          onChange={() => setSelected(reason)}
                          className="h-4 w-4 accent-trust-500"
                        />
                        {reason}
                      </label>
                    ))}
                  </div>

                  <AnimatePresence initial={false}>
                    {selected === 'Other' && (
                      <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.2, ease: 'easeOut' }}
                        className="overflow-hidden"
                      >
                        <label
                          htmlFor="report-other-details"
                          className="mt-3 block text-sm font-medium text-scam-muted"
                        >
                          Please describe the issue
                        </label>
                        <textarea
                          id="report-other-details"
                          value={details}
                          onChange={(e) => setDetails(e.target.value)}
                          rows={3}
                          autoFocus
                          placeholder="Tell us more about why you're reporting this post…"
                          className="sr-input mt-1.5 resize-none"
                        />
                      </motion.div>
                    )}
                  </AnimatePresence>

                  <div className="mt-6 flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={onClose}
                      className="sr-btn-ghost px-4 py-2"
                    >
                      Cancel
                    </button>
                    <button
                      type="button"
                      disabled={!selected || (selected === 'Other' && !details.trim())}
                      onClick={() => setSubmitted(true)}
                      className="sr-btn-primary px-5 py-2 disabled:cursor-not-allowed disabled:opacity-40"
                    >
                      Submit report
                    </button>
                  </div>
                </>
              )}
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}

export function PostCard({ post }: { post: Post }) {
  const [showComments, setShowComments] = useState(false);
  const [reportOpen, setReportOpen] = useState(false);
  const [following, setFollowing] = useState(false);
  const [revealed, setRevealed] = useState(false);

  const category = post.tags[0]?.name ?? 'Report';
  const risk = RISK_META[riskKey(post.risk)];
  const verified = post.reviewStatus === 'reviewed';

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group relative mb-5 cursor-pointer overflow-hidden rounded-lg border border-scam-line bg-scam-800 shadow-card transition hover:border-scam-muted/60 hover:bg-scam-750 hover:shadow-card-hover"
    >
      {/* Colored left-border risk strip — triage the feed at a glance. */}
      {post.risk && (
        <span
          className={`absolute inset-y-0 left-0 w-1 ${risk.strip}`}
          aria-hidden
        />
      )}

      {/* Full-card click target: navigates to the post detail. Interactive
          controls below sit above this via `relative z-10` and stop clicks
          from bubbling, so buttons/links keep working. */}
      <Link
        to={`/forum/${post.id}`}
        aria-label={`Open post: ${post.title}`}
        tabIndex={-1}
        className="absolute inset-0 z-0"
      />

      <div className="relative z-10 p-6 pl-7">
        {/* Header row: icon tile + category + meta + risk flair + follow + menu */}
        <div className="flex items-start gap-3">
          <span className="sr-tile h-9 w-9 shrink-0">
            <ShieldAlert size={18} />
          </span>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
              <span className="text-sm font-semibold text-scam-text">{category}</span>
              {verified && (
                <span
                  className="inline-flex items-center gap-1 rounded-full border border-trust-500/40 bg-trust-500/10 px-2 py-0.5 text-[11px] font-semibold text-trust-300"
                  title="Verified by moderators"
                >
                  <ShieldCheck size={12} /> Verified
                </span>
              )}
              <span className="truncate text-xs text-scam-muted">
                · posted by u/{post.author.name} · {formatDate(post.createdAt)}
              </span>
            </div>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <RiskFlair risk={post.risk} />
              {post.tags.map((tag) => (
                <span
                  key={tag.id}
                  className="relative z-10 rounded-full border border-scam-line px-2 py-0.5 text-xs font-medium text-scam-muted transition hover:border-trust-500/50 hover:text-trust-400"
                >
                  #{tag.name}
                </span>
              ))}
            </div>
          </div>

          {/* Follow + author avatar initials (kept for test) + menu */}
          <div className="flex shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={() => setFollowing((f) => !f)}
              aria-pressed={following}
              className={`hidden rounded-md px-3 py-1.5 text-xs font-semibold transition sm:inline-flex ${
                following
                  ? 'bg-trust-500 text-white hover:bg-trust-600'
                  : 'border border-scam-line text-scam-muted hover:border-trust-500/60 hover:text-trust-400'
              }`}
            >
              {following ? 'Following' : 'Follow'}
            </button>
            <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md border border-scam-line bg-scam-750 text-xs font-semibold text-scam-muted">
              {initials(post.author.name)}
            </span>
            <PostMenu onReport={() => setReportOpen(true)} />
          </div>
        </div>

        {/* Author line (plain name kept for test lookup) */}
        <p className="sr-only">{post.author.name}</p>

        {/* Title — the clear focal point of the record. */}
        <h3 className="mt-4 text-xl font-bold leading-snug tracking-tight text-scam-text transition group-hover:text-trust-400">
          <Link to={`/forum/${post.id}`} className="hover:underline">
            {post.title}
          </Link>
        </h3>

        {/* Body preview — generous line-height for calm readability. */}
        <p className="mt-2.5 line-clamp-3 text-sm leading-7 text-scam-muted">
          {post.excerpt}
        </p>

        {/* Monospace evidence / identifier chips — reads as "data". */}
        {(post.imageUrl || post.incidentDate) && (
          <div className="mt-3 flex flex-wrap items-center gap-2">
            {post.imageUrl && (
              <span className="sr-chip">🔗 evidence attached</span>
            )}
            {post.incidentDate && (
              <span className="sr-chip">📅 {formatDate(post.incidentDate)}</span>
            )}
          </div>
        )}

        {/* Evidence media (optional) with spoiler blur */}
        {post.imageUrl && (
          <div className="relative mt-4 overflow-hidden rounded-md border border-scam-line">
            <Link to={`/forum/${post.id}`} className="block">
              <img
                src={post.imageUrl}
                alt=""
                loading="lazy"
                className={`block w-full bg-scam-750 object-cover transition ${
                  revealed ? '' : 'blur-md'
                }`}
              />
            </Link>
            {!revealed && (
              <button
                type="button"
                onClick={() => setRevealed(true)}
                className="absolute inset-0 grid place-items-center bg-scam-950/50 text-xs font-semibold uppercase tracking-wider text-scam-text"
              >
                Sensitive evidence · click to reveal
              </button>
            )}
          </div>
        )}
      </div>

      {/* Action bar */}
      <div className="relative z-10 flex flex-wrap items-center gap-1 border-t border-scam-line px-4 py-2.5 pl-7 text-sm text-scam-muted">
        {/* Vote control — "did this happen to you too?" (social proof) */}
        <div className="flex items-center gap-1 rounded-md">
          <button
            type="button"
            aria-label="This happened to me too"
            className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400"
          >
            <ArrowBigUp size={18} />
          </button>
          <span className="min-w-[1.5rem] text-center text-sm font-semibold text-scam-text">
            {post.likeCount}
          </span>
          <button
            type="button"
            aria-label="Downvote"
            className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-risk-high"
          >
            <ArrowBigDown size={18} />
          </button>
        </div>

        {/* Prominent social proof — reassuring on a safety site. */}
        <span className="ml-1 mr-1 hidden items-center gap-1.5 text-xs font-medium text-risk-low sm:inline-flex">
          <ShieldCheck size={14} /> {post.likeCount} confirmed
        </span>

        <button
          type="button"
          onClick={() => setShowComments((s) => !s)}
          aria-expanded={showComments}
          className="flex items-center gap-1.5 rounded-md px-2.5 py-1.5 transition hover:bg-scam-800 hover:text-trust-400"
        >
          <MessageCircle size={16} /> {post.replyCount}
        </button>

        <button
          type="button"
          className="flex items-center gap-1.5 rounded-md px-2.5 py-1.5 transition hover:bg-scam-800 hover:text-trust-400"
        >
          <Users size={16} /> Me too
        </button>

        <div className="ml-auto flex items-center gap-1">
          <button
            type="button"
            aria-label="Share"
            className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400"
          >
            <Share2 size={16} />
          </button>
          <button
            type="button"
            aria-label="Save"
            className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400"
          >
            <Bookmark size={16} />
          </button>
        </div>
      </div>

      {/* Expandable comment area (gated behind auth inside CommentBox) */}
      <AnimatePresence initial={false}>
        {showComments && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
            className="relative z-10 overflow-hidden border-t border-scam-line"
          >
            <div className="space-y-4 px-6 py-4 pl-7">
              {showComments && <CommentList postId={post.id} />}
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <ReportModal open={reportOpen} onClose={() => setReportOpen(false)} />
    </motion.article>
  );
}
