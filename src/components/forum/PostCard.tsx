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
  Pencil,
  ShieldAlert,
  ShieldCheck,
  Trash2,
  TriangleAlert,
  X,
} from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate } from 'react-router-dom';
import type { FlagReason, Post } from '../../types';
import { deletePost, flagPost, updatePost } from '../../api/posts';
import { ApiError } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { formatAbsoluteDate, relativeDate } from '../../lib/date';
import { useReaction } from '../../hooks/useReaction';
import { CommentBox } from './CommentBox';
import { CommentList } from './CommentList';
import { ShareMenu } from './ShareMenu';

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

const REPORT_REASONS: { label: string; reason: FlagReason }[] = [
  { label: 'Spam or misleading', reason: 'spam' },
  { label: 'Scam or fraud', reason: 'harmful' },
  { label: 'Harassment or hate speech', reason: 'harmful' },
  { label: 'False information', reason: 'misinformation' },
  { label: 'Exposes personal information', reason: 'personal_information' },
  { label: 'Other', reason: 'other' },
];

/**
 * Kebab (triple-dots) menu shown at the top-right of a post's body area.
 * Currently offers a single "Report post" action; more can be added later.
 */
export function PostMenu({
  onReport,
  onEdit,
  onDelete,
}: {
  onReport: () => void;
  onEdit?: () => void;
  onDelete?: () => void;
}) {
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
            {onEdit && (
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setOpen(false);
                  onEdit();
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
              >
                <Pencil size={15} /> Edit post
              </button>
            )}
            {onDelete && (
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setOpen(false);
                  onDelete();
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-risk-high transition hover:bg-scam-800"
              >
                <Trash2 size={15} /> Delete post
              </button>
            )}
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
export function ReportModal({
  open,
  onClose,
  postId,
}: {
  open: boolean;
  onClose: () => void;
  postId: string;
}) {
  const [selected, setSelected] = useState<string | null>(null);
  const [details, setDetails] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset internal state whenever the modal is (re)opened.
  useEffect(() => {
    if (open) {
      setSelected(null);
      setDetails('');
      setSubmitted(false);
      setSubmitting(false);
      setError(null);
    }
  }, [open]);

  async function handleSubmit() {
    const match = REPORT_REASONS.find((r) => r.label === selected);
    if (!match) return;
    setSubmitting(true);
    setError(null);
    try {
      await flagPost(postId, match.reason, details.trim() || undefined);
      setSubmitted(true);
    } catch (err) {
      if (err instanceof ApiError && err.status === 409) {
        // Already reported — treat as success so the user isn't nagged.
        setSubmitted(true);
      } else {
        setError(
          err instanceof ApiError && err.message
            ? err.message
            : 'Something went wrong. Please try again.',
        );
      }
    } finally {
      setSubmitting(false);
    }
  }

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
                    {REPORT_REASONS.map(({ label }) => (
                      <label
                        key={label}
                        className={`flex cursor-pointer items-center gap-3 rounded-md border px-3 py-2.5 text-sm transition ${
                          selected === label
                            ? 'border-trust-400 bg-trust-400/10 text-scam-text'
                            : 'border-scam-line text-scam-muted hover:border-scam-muted'
                        }`}
                      >
                        <input
                          type="radio"
                          name="report-reason"
                          value={label}
                          checked={selected === label}
                          onChange={() => setSelected(label)}
                          className="h-4 w-4 accent-trust-500"
                        />
                        {label}
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

                  {error && (
                    <p
                      role="alert"
                      className="mt-3 text-sm font-medium text-risk-high"
                    >
                      {error}
                    </p>
                  )}

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
                      disabled={
                        !selected ||
                        submitting ||
                        (selected === 'Other' && !details.trim())
                      }
                      onClick={handleSubmit}
                      className="sr-btn-primary px-5 py-2 disabled:cursor-not-allowed disabled:opacity-40"
                    >
                      {submitting ? 'Submitting…' : 'Submit report'}
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

/**
 * Modal for editing an existing post (author/moderator only). Mirrors the
 * ReportModal's overlay/dialog styling. Submits title, redacted text, and tags
 * via PATCH; the backend resets review status to unverified when the redacted
 * text changes.
 */
export function EditPostModal({
  open,
  onClose,
  post,
}: {
  open: boolean;
  onClose: () => void;
  post: Post;
}) {
  const queryClient = useQueryClient();
  const [title, setTitle] = useState(post.title);
  const [excerpt, setExcerpt] = useState(post.excerpt);
  const [tags, setTags] = useState(post.tags.map((t) => t.name).join(', '));
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setTitle(post.title);
      setExcerpt(post.excerpt);
      setTags(post.tags.map((t) => t.name).join(', '));
      setError(null);
    }
  }, [open, post]);

  const mutation = useMutation({
    mutationFn: () =>
      updatePost(post.id, {
        title: title.trim(),
        excerpt: excerpt.trim(),
        tags: tags
          .split(',')
          .map((t) => t.trim())
          .filter(Boolean),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['post', post.id] });
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      onClose();
    },
    onError: (err) =>
      setError(err instanceof Error ? err.message : 'Could not save changes.'),
  });

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
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="fixed inset-0 z-[100] bg-scam-950/70 backdrop-blur-sm"
          />
          <div className="fixed inset-0 z-[101] flex items-center justify-center p-4">
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-labelledby="edit-modal-title"
              initial={{ opacity: 0, scale: 0.96, y: 8 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 8 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-md rounded-lg border border-scam-line bg-scam-850 p-6 shadow-2xl"
            >
              <div className="flex items-start justify-between gap-4">
                <h2
                  id="edit-modal-title"
                  className="text-lg font-semibold text-scam-text"
                >
                  Edit post
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

              <div className="mt-4 space-y-3">
                <div>
                  <label
                    htmlFor="edit-title"
                    className="text-xs font-semibold text-scam-muted"
                  >
                    Title
                  </label>
                  <input
                    id="edit-title"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="sr-input mt-1.5"
                  />
                </div>
                <div>
                  <label
                    htmlFor="edit-excerpt"
                    className="text-xs font-semibold text-scam-muted"
                  >
                    Details
                  </label>
                  <textarea
                    id="edit-excerpt"
                    value={excerpt}
                    onChange={(e) => setExcerpt(e.target.value)}
                    rows={5}
                    className="sr-input mt-1.5 resize-none"
                  />
                  <p className="mt-1 text-xs text-scam-dim">
                    Editing the details resets this post to unverified for
                    re-review.
                  </p>
                </div>
                <div>
                  <label
                    htmlFor="edit-tags"
                    className="text-xs font-semibold text-scam-muted"
                  >
                    Tags (comma-separated)
                  </label>
                  <input
                    id="edit-tags"
                    value={tags}
                    onChange={(e) => setTags(e.target.value)}
                    className="sr-input mt-1.5"
                  />
                </div>
              </div>

              {error && (
                <p role="alert" className="mt-3 text-sm font-medium text-risk-high">
                  {error}
                </p>
              )}

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
                  disabled={!title.trim() || !excerpt.trim() || mutation.isPending}
                  onClick={() => mutation.mutate()}
                  className="sr-btn-primary px-5 py-2 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  {mutation.isPending ? 'Saving…' : 'Save changes'}
                </button>
              </div>
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
  const [editOpen, setEditOpen] = useState(false);
  const [following, setFollowing] = useState(false);
  const [revealed, setRevealed] = useState(false);
  const [saved, setSaved] = useState(false);
  const reaction = useReaction(post);
  const { isLoggedIn } = useAuth();
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  // Whole-card click navigates to the post, but only when the click didn't
  // land on (or inside) a genuinely interactive control. This avoids a
  // positioned overlay and the z-index stacking fights it caused.
  function handleCardClick(e: React.MouseEvent<HTMLElement>) {
    if (e.defaultPrevented) return;
    if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    const target = e.target as HTMLElement;
    if (target.closest('a, button, input, textarea, select, [role="menu"], [role="dialog"]')) {
      return;
    }
    navigate(`/forum/${post.id}`);
  }

  const deleteMutation = useMutation({
    mutationFn: () => deletePost(post.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      queryClient.invalidateQueries({ queryKey: ['post', post.id] });
      queryClient.invalidateQueries({ queryKey: ['myPosts'] });
    },
  });

  function handleDelete() {
    if (window.confirm('Delete this post? This cannot be undone.')) {
      deleteMutation.mutate();
    }
  }

  const category = post.tags[0]?.name ?? 'Report';
  const risk = RISK_META[riskKey(post.risk)];
  const verified = post.reviewStatus === 'reviewed';

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      onClick={handleCardClick}
      className="group relative mb-5 cursor-pointer overflow-hidden rounded-lg border border-scam-line bg-scam-800 shadow-card transition hover:border-scam-muted/60 hover:bg-scam-750 hover:shadow-card-hover"
    >
      {/* Colored left-border risk strip — triage the feed at a glance. */}
      {post.risk && (
        <span
          className={`absolute inset-y-0 left-0 w-1 ${risk.strip}`}
          aria-hidden
        />
      )}

      <div className="relative p-6 pl-7">
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
                · posted by u/{post.author.name} · {relativeDate(post.createdAt)}
              </span>
            </div>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <RiskFlair risk={post.risk} />
              {post.tags.map((tag) => (
                <span
                  key={tag.id}
                  className="relative z-20 rounded-full border border-scam-line px-2 py-0.5 text-xs font-medium text-scam-muted transition hover:border-trust-500/50 hover:text-trust-400"
                >
                  #{tag.name}
                </span>
              ))}
            </div>
          </div>

          {/* Follow + author avatar initials (kept for test) + menu */}
          <div className="relative z-20 flex shrink-0 items-center gap-2">
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
            <PostMenu
              onReport={() => setReportOpen(true)}
              onEdit={isLoggedIn && post.isMine ? () => setEditOpen(true) : undefined}
              onDelete={isLoggedIn && post.isMine ? handleDelete : undefined}
            />
          </div>
        </div>

        {/* Author line (plain name kept for test lookup) */}
        <p className="sr-only">{post.author.name}</p>

        {/* Title — the clear focal point of the record. */}
        <h3 className="relative z-20 mt-4 inline-block text-xl font-bold leading-snug tracking-tight text-scam-text transition group-hover:text-trust-400">
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
              <span className="sr-chip">📅 {formatAbsoluteDate(post.incidentDate)}</span>
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
      <div className="relative z-20 flex flex-wrap items-center gap-1 border-t border-scam-line px-4 py-2.5 pl-7 text-sm text-scam-muted">
        {/* Vote control — "did this happen to you too?" (social proof) */}
        <div className="flex items-center gap-2 rounded-md border border-scam-line bg-scam-800/60 px-1 py-0.5">
          {/* Up group: arrow hugs its count */}
          <div className="flex items-center gap-0.5">
            <motion.button
              type="button"
              whileTap={{ scale: 0.8 }}
              transition={{ type: 'spring', stiffness: 500, damping: 15 }}
              onClick={reaction.upvote}
              disabled={reaction.pending}
              aria-label="This happened to me too"
              aria-pressed={reaction.myVote === 1}
              className={`grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-750 hover:text-trust-400 disabled:opacity-50 ${
                reaction.myVote === 1 ? 'text-trust-400' : ''
              }`}
            >
              <motion.span
                key={reaction.myVote === 1 ? 'up-on' : 'up-off'}
                initial={{ scale: 0.6 }}
                animate={{ scale: 1 }}
                transition={{ type: 'spring', stiffness: 500, damping: 12 }}
              >
                <ArrowBigUp size={18} fill={reaction.myVote === 1 ? 'currentColor' : 'none'} />
              </motion.span>
            </motion.button>
            <motion.span
              key={`up-${reaction.upCount}`}
              initial={{ y: -4, opacity: 0.4 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.18 }}
              className={`min-w-[1.5rem] pr-1 text-center text-sm font-semibold tabular-nums ${
                reaction.myVote === 1 ? 'text-trust-400' : 'text-scam-text'
              }`}
            >
              {reaction.upCount}
            </motion.span>
          </div>

          {/* Divider between the up and down groups */}
          <span className="h-5 w-px bg-scam-line" aria-hidden />

          {/* Down group: arrow hugs its count */}
          <div className="flex items-center gap-0.5">
            <motion.button
              type="button"
              whileTap={{ scale: 0.8 }}
              transition={{ type: 'spring', stiffness: 500, damping: 15 }}
              onClick={reaction.downvote}
              disabled={reaction.pending}
              aria-label="Downvote"
              aria-pressed={reaction.myVote === -1}
              className={`grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-750 hover:text-risk-high disabled:opacity-50 ${
                reaction.myVote === -1 ? 'text-risk-high' : ''
              }`}
            >
              <motion.span
                key={reaction.myVote === -1 ? 'down-on' : 'down-off'}
                initial={{ scale: 0.6 }}
                animate={{ scale: 1 }}
                transition={{ type: 'spring', stiffness: 500, damping: 12 }}
              >
                <ArrowBigDown size={18} fill={reaction.myVote === -1 ? 'currentColor' : 'none'} />
              </motion.span>
            </motion.button>
            <motion.span
              key={`down-${reaction.downCount}`}
              initial={{ y: -4, opacity: 0.4 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.18 }}
              className={`min-w-[1.5rem] pr-1 text-center text-sm font-semibold tabular-nums ${
                reaction.myVote === -1 ? 'text-risk-high' : 'text-scam-text'
              }`}
            >
              {reaction.downCount}
            </motion.span>
          </div>
        </div>

        {/* Prominent social proof — reassuring on a safety site. */}
        <span className="ml-1 mr-1 hidden items-center gap-1.5 text-xs font-medium text-risk-low sm:inline-flex">
          <ShieldCheck size={14} /> {reaction.upCount} confirmed
        </span>

        <button
          type="button"
          onClick={() => setShowComments((s) => !s)}
          aria-expanded={showComments}
          className="flex items-center gap-1.5 rounded-md px-2.5 py-1.5 transition hover:bg-scam-800 hover:text-trust-400"
        >
          <MessageCircle size={16} /> {post.replyCount}
        </button>

        <div className="ml-auto flex items-center gap-1">
          <ShareMenu post={post} />
          <motion.button
            type="button"
            whileTap={{ scale: 0.8 }}
            transition={{ type: 'spring', stiffness: 500, damping: 15 }}
            onClick={() => setSaved((s) => !s)}
            aria-label={saved ? 'Remove from saved' : 'Save'}
            aria-pressed={saved}
            className={`grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400 ${
              saved ? 'text-trust-400' : ''
            }`}
          >
            <motion.span
              key={saved ? 'saved' : 'unsaved'}
              initial={{ scale: 0.5, rotate: saved ? -12 : 0 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: 'spring', stiffness: 500, damping: 12 }}
            >
              <Bookmark size={16} fill={saved ? 'currentColor' : 'none'} />
            </motion.span>
          </motion.button>
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
            className="relative z-20 overflow-hidden border-t border-scam-line"
          >
            <div className="space-y-4 px-6 py-4 pl-7">
              {showComments && <CommentList postId={post.id} />}
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <ReportModal
        open={reportOpen}
        onClose={() => setReportOpen(false)}
        postId={post.id}
      />

      <EditPostModal
        open={editOpen}
        onClose={() => setEditOpen(false)}
        post={post}
      />
    </motion.article>
  );
}
