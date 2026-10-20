import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import {
  CheckCircle2,
  FileText,
  Flag,
  MessageSquare,
  ShieldCheck,
  X,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getAdminFlags, reviewComment, reviewPost } from '../../api/admin';
import {
  ADMIN_INPUT_CLASS,
  ADMIN_SELECT_CLASS,
  AdminEmptyState,
  AdminError,
  AdminLoading,
  Badge,
  PaginationBar,
  StatusBadge,
} from '../../components/admin/AdminUi';
import { useCursorPagination } from '../../hooks/useCursorPagination';
import { relativeDate } from '../../lib/date';
import type {
  AdminFlag,
  AdminFlagStatus,
  AdminFlagTarget,
  CommentReviewDecision,
  FlagReason,
  PostReviewDecision,
} from '../../types';

const REASON_LABELS: Record<FlagReason, string> = {
  personal_information: 'Personal information',
  harmful: 'Harmful content',
  spam: 'Spam',
  misinformation: 'Misinformation',
  other: 'Other',
};

const POST_DECISIONS: Array<{
  value: PostReviewDecision;
  label: string;
  description: string;
  tone: 'neutral' | 'warning' | 'danger' | 'trust';
}> = [
  {
    value: 'hide',
    label: 'Hide',
    description: 'Remove from the public feed but keep the record.',
    tone: 'warning',
  },
  {
    value: 'remove',
    label: 'Remove',
    description: 'Mark the post as removed. It stays available for audit.',
    tone: 'danger',
  },
  {
    value: 'reviewed',
    label: 'Mark reviewed',
    description: 'Confirm the post is legitimate and verified.',
    tone: 'trust',
  },
  {
    value: 'disputed',
    label: 'Dispute',
    description: 'Flag the report as disputed or unreliable.',
    tone: 'neutral',
  },
  {
    value: 'restore',
    label: 'Restore',
    description: 'Make the post visible again and reset it to unverified.',
    tone: 'neutral',
  },
];

const COMMENT_DECISIONS: Array<{
  value: CommentReviewDecision;
  label: string;
  description: string;
  tone: 'neutral' | 'warning' | 'danger' | 'trust';
}> = [
  {
    value: 'hide',
    label: 'Hide',
    description: 'Hide the comment from public threads.',
    tone: 'warning',
  },
  {
    value: 'remove',
    label: 'Remove',
    description: 'Mark the comment as removed. It stays available for audit.',
    tone: 'danger',
  },
  {
    value: 'reviewed',
    label: 'Mark reviewed',
    description: 'Keep the comment visible and close the report.',
    tone: 'trust',
  },
  {
    value: 'restore',
    label: 'Restore',
    description: 'Make the comment visible again.',
    tone: 'neutral',
  },
];

const DECISION_TONE = {
  neutral: 'border-scam-line bg-scam-750 text-scam-text',
  warning: 'border-risk-med/50 bg-risk-med/10 text-risk-med',
  danger: 'border-risk-high/50 bg-risk-high/10 text-risk-high',
  trust: 'border-trust-500/50 bg-trust-500/10 text-trust-600 dark:text-trust-400',
} as const;

/** Modal that records a moderation decision for the flagged target. */
function ReviewFlagDialog({
  flag,
  onClose,
}: {
  flag: AdminFlag;
  onClose: () => void;
}) {
  const queryClient = useQueryClient();
  const isPost = flag.targetType === 'post';
  const decisions = isPost ? POST_DECISIONS : COMMENT_DECISIONS;
  const [decision, setDecision] = useState<string | null>(null);
  const [rationale, setRationale] = useState('');

  const mutation = useMutation({
    mutationFn: async () => {
      if (!decision) return;
      const note = rationale.trim() || undefined;
      if (isPost) {
        await reviewPost(flag.targetId, decision as PostReviewDecision, note);
      } else {
        await reviewComment(
          flag.targetId,
          decision as CommentReviewDecision,
          note,
        );
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin'] });
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      queryClient.invalidateQueries({ queryKey: ['post', flag.postId] });
      queryClient.invalidateQueries({ queryKey: ['comments', flag.postId] });
      onClose();
    },
  });

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [onClose]);

  return (
    <AnimatePresence>
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
          aria-labelledby="review-flag-title"
          initial={{ opacity: 0, scale: 0.96, y: 8 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.96, y: 8 }}
          transition={{ duration: 0.2, ease: 'easeOut' }}
          onClick={(e) => e.stopPropagation()}
          className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-lg border border-scam-line bg-scam-850 p-6 shadow-2xl"
        >
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2
                id="review-flag-title"
                className="text-lg font-semibold text-scam-text"
              >
                Review flagged {isPost ? 'post' : 'comment'}
              </h2>
              <p className="mt-1 text-sm text-scam-muted">
                {flag.postTitle}
              </p>
            </div>
            <button
              type="button"
              onClick={onClose}
              aria-label="Close"
              className="grid h-8 w-8 shrink-0 place-items-center rounded-md text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
            >
              <X size={18} />
            </button>
          </div>

          <blockquote className="mt-4 rounded-lg border border-scam-line bg-scam-800 p-3 text-sm italic leading-relaxed text-scam-muted">
            {flag.excerpt}
          </blockquote>

          <div className="mt-4 space-y-2">
            {decisions.map((option) => (
              <button
                key={option.value}
                type="button"
                onClick={() => setDecision(option.value)}
                aria-pressed={decision === option.value}
                className={`w-full rounded-lg border px-3 py-2.5 text-left transition ${
                  decision === option.value
                    ? DECISION_TONE[option.tone]
                    : 'border-scam-line bg-scam-800 text-scam-muted hover:border-scam-muted'
                }`}
              >
                <span className="block text-sm font-semibold">
                  {option.label}
                </span>
                <span className="mt-0.5 block text-xs opacity-80">
                  {option.description}
                </span>
              </button>
            ))}
          </div>

          <label
            htmlFor="review-rationale"
            className="mt-4 block text-xs font-semibold text-scam-muted"
          >
            Rationale (optional)
          </label>
          <textarea
            id="review-rationale"
            value={rationale}
            onChange={(e) => setRationale(e.target.value)}
            rows={3}
            placeholder="What did you find? This is stored with the decision."
            className={`${ADMIN_INPUT_CLASS} mt-1.5 w-full resize-none`}
          />

          {mutation.isError && (
            <p role="alert" className="mt-3 text-sm font-medium text-risk-high">
              {(mutation.error as Error).message ||
                'Could not apply this decision. Try again.'}
            </p>
          )}

          <div className="mt-6 flex justify-end gap-3">
            <button type="button" onClick={onClose} className="sr-btn-ghost px-4 py-2">
              Cancel
            </button>
            <button
              type="button"
              disabled={!decision || mutation.isPending}
              onClick={() => mutation.mutate()}
              className="sr-btn-primary px-5 py-2 disabled:cursor-not-allowed disabled:opacity-40"
            >
              <ShieldCheck size={15} />
              {mutation.isPending ? 'Applying…' : 'Apply decision'}
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}

export function AdminReportsPage() {
  const [status, setStatus] = useState<AdminFlagStatus>('open');
  const [targetType, setTargetType] = useState<AdminFlagTarget>('all');
  const [reviewing, setReviewing] = useState<AdminFlag | null>(null);
  const { cursor, goNext, goPrev, reset, hasPrev } = useCursorPagination();

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['admin', 'flags', status, targetType, cursor],
    queryFn: () => getAdminFlags({ status, targetType, cursor }),
  });

  function changeStatus(next: AdminFlagStatus) {
    setStatus(next);
    reset();
  }

  function changeTarget(next: AdminFlagTarget) {
    setTargetType(next);
    reset();
  }

  const items = data?.items ?? [];

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-scam-line bg-scam-800 p-4 shadow-card">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="font-display text-lg font-bold text-scam-text">
              Reports &amp; flags
            </h2>
            <p className="mt-0.5 text-sm text-scam-muted">
              Newest first. Reviewing a target closes its related reports.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <label className="sr-only" htmlFor="flag-status">
              Report status
            </label>
            <select
              id="flag-status"
              value={status}
              onChange={(e) => changeStatus(e.target.value as AdminFlagStatus)}
              className={ADMIN_SELECT_CLASS}
            >
              <option value="open">Open</option>
              <option value="resolved">Resolved</option>
              <option value="dismissed">Dismissed</option>
              <option value="all">All statuses</option>
            </select>
            <label className="sr-only" htmlFor="flag-target">
              Target type
            </label>
            <select
              id="flag-target"
              value={targetType}
              onChange={(e) => changeTarget(e.target.value as AdminFlagTarget)}
              className={ADMIN_SELECT_CLASS}
            >
              <option value="all">Posts &amp; comments</option>
              <option value="post">Posts only</option>
              <option value="comment">Comments only</option>
            </select>
          </div>
        </div>
      </div>

      {isLoading && <AdminLoading label="Loading reports…" />}
      {isError && (
        <AdminError
          message={(error as Error)?.message}
          onRetry={() => void refetch()}
        />
      )}

      {!isLoading && !isError && items.length === 0 && (
        <AdminEmptyState
          icon={CheckCircle2}
          title="No reports in this queue"
          description={
            status === 'open'
              ? 'Nothing needs attention right now. New flags will appear here as they are raised.'
              : 'No reports match this status and target filter.'
          }
        />
      )}

      {!isLoading && !isError && items.length > 0 && (
        <div className="space-y-3">
          {items.map((flag) => (
            <article
              key={flag.id}
              className="rounded-2xl border border-scam-line bg-scam-800 p-4 shadow-card"
            >
              <div className="flex flex-col gap-4 lg:flex-row lg:items-start">
                <span className="sr-tile h-9 w-9 shrink-0">
                  {flag.targetType === 'post' ? (
                    <FileText size={17} />
                  ) : (
                    <MessageSquare size={17} />
                  )}
                </span>

                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <StatusBadge status={flag.status} />
                    <Badge tone="trust">{REASON_LABELS[flag.reason]}</Badge>
                    <Badge>
                      {flag.targetType === 'post' ? 'Post' : 'Comment'}
                    </Badge>
                    <span className="text-xs text-scam-dim">
                      #{flag.id} · {relativeDate(flag.createdAt)}
                    </span>
                  </div>

                  <p className="mt-2 truncate text-sm font-semibold text-scam-text">
                    {flag.postTitle}
                  </p>
                  <blockquote className="mt-2 line-clamp-3 border-l-2 border-scam-line pl-3 text-sm italic leading-relaxed text-scam-muted">
                    {flag.excerpt}
                  </blockquote>
                  {flag.details && (
                    <p className="mt-2 text-xs leading-relaxed text-scam-muted">
                      <span className="font-semibold text-scam-text">
                        Reporter note:
                      </span>{' '}
                      {flag.details}
                    </p>
                  )}

                  <div className="mt-3 flex flex-wrap items-center gap-2 text-[11px] text-scam-dim">
                    <span>Reporter #{flag.reporterId}</span>
                    <span aria-hidden>·</span>
                    <span>Target author #{flag.targetAuthorId}</span>
                    <span aria-hidden>·</span>
                    <span className="inline-flex items-center gap-1">
                      Post: <StatusBadge status={flag.postReviewStatus} />
                    </span>
                    {flag.commentStatus && (
                      <span className="inline-flex items-center gap-1">
                        Comment: <StatusBadge status={flag.commentStatus} />
                      </span>
                    )}
                    {flag.postDeleted && <StatusBadge status="deleted" />}
                  </div>
                </div>

                <div className="flex shrink-0 flex-wrap items-center gap-2 lg:flex-col lg:items-stretch">
                  <Link
                    to={
                      flag.targetType === 'comment'
                        ? `/forum/${flag.postId}#comment-${flag.targetId}`
                        : `/forum/${flag.postId}`
                    }
                    className="sr-btn-ghost px-3 py-1.5 text-xs"
                  >
                    {flag.targetType === 'comment'
                      ? 'Open comment'
                      : 'Open post'}
                  </Link>
                  {flag.status === 'open' && (
                    <button
                      type="button"
                      onClick={() => setReviewing(flag)}
                      className="sr-btn-primary px-3 py-1.5 text-xs"
                    >
                      <Flag size={13} /> Review
                    </button>
                  )}
                </div>
              </div>
            </article>
          ))}

          <div className="overflow-hidden rounded-2xl border border-scam-line bg-scam-800">
            <PaginationBar
              hasPrev={hasPrev}
              hasNext={!!data?.nextCursor}
              onPrev={goPrev}
              onNext={() => data?.nextCursor && goNext(data.nextCursor)}
              loading={isFetching}
              count={items.length}
            />
          </div>
        </div>
      )}

      {reviewing && (
        <ReviewFlagDialog flag={reviewing} onClose={() => setReviewing(null)} />
      )}
    </div>
  );
}
