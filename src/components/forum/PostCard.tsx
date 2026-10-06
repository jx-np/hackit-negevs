import { AnimatePresence, motion } from 'framer-motion';
import { CheckCircle2, Flag, Heart, MessageCircle, MoreVertical, X } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import type { Post } from '../../types';
import { CommentBox } from './CommentBox';

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

function RiskBadge({ risk }: { risk: Post['risk'] }) {
  if (!risk) return null;
  const styles =
    risk === 'high'
      ? 'bg-risk-600 text-white'
      : 'bg-caution-500 text-ink-900';
  const label = risk === 'high' ? 'High risk' : 'Caution';
  return (
    <span
      className={`absolute left-3 top-3 ia-label px-2 py-1 ${styles}`}
    >
      {label}
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
        className="grid h-8 w-8 place-items-center text-ink-400 transition hover:bg-ink-100 hover:text-ink-900 dark:hover:bg-ink-800 dark:hover:text-white"
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
            className="absolute right-0 top-full z-20 mt-1 min-w-[10rem] border border-ink-200 bg-paper py-1 shadow-ia dark:border-ink-700 dark:bg-ink-900"
          >
            <button
              type="button"
              role="menuitem"
              onClick={() => {
                setOpen(false);
                onReport();
              }}
              className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-ink-700 transition hover:bg-ink-100 hover:text-ink-900 dark:text-ink-300 dark:hover:bg-ink-800 dark:hover:text-white"
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
            className="fixed inset-0 z-[100] bg-ink-950/60 backdrop-blur-sm"
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
              className="w-full max-w-md border border-ink-200 bg-paper p-6 shadow-2xl dark:border-ink-800 dark:bg-ink-950"
            >
              <div className="flex items-start justify-between gap-4">
                <h2
                  id="report-modal-title"
                  className="font-display text-lg font-semibold text-ink-900 dark:text-white"
                >
                  {submitted ? 'Report submitted' : 'Why are you reporting this post?'}
                </h2>
                <button
                  type="button"
                  onClick={onClose}
                  aria-label="Close"
                  className="grid h-8 w-8 shrink-0 place-items-center text-ink-400 transition hover:bg-ink-100 hover:text-ink-900 dark:hover:bg-ink-800 dark:hover:text-white"
                >
                  <X size={18} />
                </button>
              </div>

              {submitted ? (
                <div className="mt-4 flex flex-col items-center gap-3 py-4 text-center">
                  <CheckCircle2 size={40} className="text-safe-500" />
                  <p className="text-sm text-ink-600 dark:text-ink-300">
                    Thanks for helping keep the community safe. Our team will
                    review this report.
                  </p>
                  <button
                    type="button"
                    onClick={onClose}
                    className="mt-2 border border-ink-900 bg-ink-900 px-5 py-2 text-sm font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
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
                        className={`flex cursor-pointer items-center gap-3 border px-3 py-2.5 text-sm transition ${
                          selected === reason
                            ? 'border-safe-500 bg-safe-50 text-ink-900 dark:bg-safe-500/10 dark:text-white'
                            : 'border-ink-200 text-ink-700 hover:border-ink-400 dark:border-ink-700 dark:text-ink-300 dark:hover:border-ink-500'
                        }`}
                      >
                        <input
                          type="radio"
                          name="report-reason"
                          value={reason}
                          checked={selected === reason}
                          onChange={() => setSelected(reason)}
                          className="h-4 w-4 accent-safe-500"
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
                          className="mt-3 block text-sm font-medium text-ink-700 dark:text-ink-300"
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
                          className="mt-1.5 w-full resize-none border border-ink-200 bg-paper px-3 py-2 text-sm text-ink-900 outline-none transition placeholder:text-ink-400 focus:border-safe-500 dark:border-ink-700 dark:bg-ink-900 dark:text-white"
                        />
                      </motion.div>
                    )}
                  </AnimatePresence>

                  <div className="mt-6 flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={onClose}
                      className="border border-ink-300 px-4 py-2 text-sm font-medium text-ink-700 transition hover:border-ink-900 hover:text-ink-900 dark:border-ink-700 dark:text-ink-300 dark:hover:border-white dark:hover:text-white"
                    >
                      Cancel
                    </button>
                    <button
                      type="button"
                      disabled={!selected || (selected === 'Other' && !details.trim())}
                      onClick={() => setSubmitted(true)}
                      className="border border-ink-900 bg-ink-900 px-5 py-2 text-sm font-semibold text-white transition enabled:hover:bg-ink-800 disabled:cursor-not-allowed disabled:opacity-40 dark:border-white dark:bg-white dark:text-ink-900 dark:enabled:hover:bg-ink-100"
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

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group relative mb-5 break-inside-avoid ia-panel overflow-hidden transition-transform transition-colors hover:-translate-y-0.5 hover:border-ink-400 dark:hover:border-ink-600"
    >
      {/* Image-forward header (with risk badge overlay) — links to detail */}
      {post.imageUrl && (
        <Link to={`/forum/${post.id}`} className="relative block">
          <img
            src={post.imageUrl}
            alt=""
            loading="lazy"
            className="block w-full bg-ink-100 object-cover dark:bg-ink-800"
          />
          <RiskBadge risk={post.risk} />
        </Link>
      )}

      <div className="px-5 pt-4">
        <div className="flex items-start gap-2">
          <div className="flex flex-1 flex-wrap items-center gap-2">
            {post.tags.map((tag) => (
              <span
                key={tag.id}
                className="border border-ink-200 px-2 py-0.5 font-display text-xs font-medium uppercase tracking-wider text-ink-600 dark:border-ink-700 dark:text-ink-300"
              >
                #{tag.name}
              </span>
            ))}
            {/* If there's no image, show the risk inline instead of overlaid */}
            {!post.imageUrl && post.risk && (
              <span
                className={`ia-label px-2 py-0.5 ${
                  post.risk === 'high'
                    ? 'bg-risk-100 text-risk-700 dark:bg-risk-500/15 dark:text-risk-500'
                    : 'bg-caution-100 text-caution-700 dark:bg-caution-500/15 dark:text-caution-500'
                }`}
              >
                {post.risk === 'high' ? 'High risk' : 'Caution'}
              </span>
            )}
          </div>
          <PostMenu onReport={() => setReportOpen(true)} />
        </div>

        <h3 className="mt-3 font-display text-xl font-semibold leading-snug text-ink-900 transition group-hover:text-safe-700 dark:text-white dark:group-hover:text-safe-400">
          <Link to={`/forum/${post.id}`} className="hover:underline">
            {post.title}
          </Link>
        </h3>
        <p className="mt-2 line-clamp-3 text-base text-ink-600 dark:text-ink-400">
          {post.excerpt}
        </p>
      </div>

      {/* Footer: author + date + engagement */}
      <div className="mt-4 flex items-center gap-3 border-t border-ink-200 px-5 py-3 dark:border-ink-800">
        <span className="grid h-9 w-9 shrink-0 place-items-center border border-ink-300 bg-ink-50 font-display text-xs font-semibold text-ink-700 dark:border-ink-700 dark:bg-ink-800 dark:text-ink-200">
          {initials(post.author.name)}
        </span>
        <div className="min-w-0">
          <p className="truncate text-sm font-medium text-ink-900 dark:text-white">
            {post.author.name}
          </p>
          <p className="text-xs text-ink-400">
            {formatDate(post.createdAt)}
          </p>
        </div>
        <div className="ml-auto flex items-center gap-3 font-display text-sm text-ink-400">
          <button
            type="button"
            onClick={() => setShowComments((s) => !s)}
            aria-expanded={showComments}
            className="flex items-center gap-1.5 px-1.5 py-1 transition hover:text-safe-600 dark:hover:text-safe-400"
          >
            <MessageCircle size={16} /> {post.replyCount}
          </button>
          <span className="flex items-center gap-1.5">
            <Heart size={16} /> {post.likeCount}
          </span>
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
            className="overflow-hidden border-t border-ink-200 dark:border-ink-800"
          >
            <div className="px-5 py-4">
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <ReportModal open={reportOpen} onClose={() => setReportOpen(false)} />
    </motion.article>
  );
}
