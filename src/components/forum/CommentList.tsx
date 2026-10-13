import { useMutation, useQueryClient } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { ArrowBigUp, Check, Flag, MessageCircle, MoreVertical, Pencil, Reply, Send, Trash2, X } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useComments } from '../../hooks/useComments';
import { useCommentLike } from '../../hooks/useCommentLike';
import { useAuth } from '../../context/AuthContext';
import {
  createComment,
  deleteComment,
  flagComment,
  updateComment,
} from '../../api/comments';
import { ApiError } from '../../api/client';
import type { Comment, FlagReason } from '../../types';

interface CommentListProps {
  postId: string;
}

const COMMENT_REPORT_REASONS: { label: string; reason: FlagReason }[] = [
  { label: 'Spam or misleading', reason: 'spam' },
  { label: 'Harmful or abusive', reason: 'harmful' },
  { label: 'False information', reason: 'misinformation' },
  { label: 'Exposes personal information', reason: 'personal_information' },
  { label: 'Other', reason: 'other' },
];

/** Relative "time ago" from an ISO timestamp. */
function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.round(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.round(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(iso).toLocaleDateString();
}

function initials(label: string): string {
  return (
    label
      .split(/\s+/)
      .map((w) => w[0])
      .slice(0, 2)
      .join('')
      .toUpperCase() || '?'
  );
}

/** Per-comment kebab menu: flag (any logged-in user) + edit/delete (author). */
function CommentMenu({
  isAuthor,
  onFlag,
  onEdit,
  onDelete,
}: {
  isAuthor: boolean;
  onFlag: () => void;
  onEdit: () => void;
  onDelete: () => void;
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
        aria-label="Comment options"
        className="grid h-7 w-7 place-items-center rounded-md text-scam-dim transition hover:bg-scam-800 hover:text-scam-text"
      >
        <MoreVertical size={16} />
      </button>
      {open && (
        <div
          role="menu"
          className="absolute right-0 top-full z-20 mt-1 min-w-[9rem] rounded-md border border-scam-line bg-scam-850 py-1 shadow-xl"
        >
          {isAuthor && (
            <>
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setOpen(false);
                  onEdit();
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
              >
                <Pencil size={14} /> Edit
              </button>
              <button
                type="button"
                role="menuitem"
                onClick={() => {
                  setOpen(false);
                  onDelete();
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-risk-high transition hover:bg-scam-800"
              >
                <Trash2 size={14} /> Delete
              </button>
            </>
          )}
          <button
            type="button"
            role="menuitem"
            onClick={() => {
              setOpen(false);
              onFlag();
            }}
            className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
          >
            <Flag size={14} /> Report
          </button>
        </div>
      )}
    </div>
  );
}

function CommentItem({
  comment,
  postId,
  depth = 0,
  childrenByParent,
}: {
  comment: Comment;
  postId: string;
  depth?: number;
  childrenByParent: Map<string, Comment[]>;
}) {
  const isReply = depth > 0;
  // Cap reply nesting at 3 levels so reply-to-reply chains don't grow without
  // bound and waterfall past the container's right edge. Replies at the max
  // depth can't be replied to further, and indentation stops shifting right.
  const MAX_DEPTH = 3;
  const atMaxDepth = depth >= MAX_DEPTH;
  const nextDepth = Math.min(depth + 1, MAX_DEPTH);
  const removed = comment.status === 'removed' || comment.status === 'hidden';
  const hasReplies = (childrenByParent.get(comment.id) ?? []).length > 0;
  const { user, isLoggedIn } = useAuth();
  const queryClient = useQueryClient();
  const isAuthor = !!user && user.id === comment.authorId;
  const like = useCommentLike(comment.id);

  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(comment.body);
  const [flagging, setFlagging] = useState(false);
  const [flagReason, setFlagReason] = useState<FlagReason | null>(null);
  const [flagDetails, setFlagDetails] = useState('');
  const [flagDone, setFlagDone] = useState(false);
  const [replying, setReplying] = useState(false);
  const [replyDraft, setReplyDraft] = useState('');
  const [actionError, setActionError] = useState<string | null>(null);

  function invalidate() {
    queryClient.invalidateQueries({ queryKey: ['comments', postId] });
    queryClient.invalidateQueries({ queryKey: ['post', postId] });
  }

  const editMutation = useMutation({
    mutationFn: (body: string) => updateComment(comment.id, body),
    onSuccess: () => {
      setEditing(false);
      setActionError(null);
      invalidate();
    },
    onError: (err) =>
      setActionError(err instanceof Error ? err.message : 'Could not save edit.'),
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteComment(comment.id),
    onSuccess: invalidate,
    onError: (err) =>
      setActionError(err instanceof Error ? err.message : 'Could not delete.'),
  });

  const replyMutation = useMutation({
    mutationFn: (body: string) => createComment(postId, body, comment.id),
    onSuccess: () => {
      setReplying(false);
      setReplyDraft('');
      setActionError(null);
      invalidate();
    },
    onError: (err) =>
      setActionError(err instanceof Error ? err.message : 'Could not post reply.'),
  });

  const flagMutation = useMutation({
    mutationFn: ({ reason, details }: { reason: FlagReason; details?: string }) =>
      flagComment(comment.id, reason, details),
    onSuccess: () => {
      setFlagDone(true);
      setFlagging(false);
      setActionError(null);
    },
    onError: (err) => {
      if (err instanceof ApiError && err.status === 409) {
        setFlagDone(true);
        setFlagging(false);
        setActionError(null);
      } else {
        setActionError(
          err instanceof Error ? err.message : 'Could not submit report.',
        );
      }
    },
  });

  // A deleted comment with no replies is dropped entirely. If it still has
  // replies, keep the block and show a placeholder so the thread stays intact.
  if (removed && !hasReplies) {
    return null;
  }

  return (
    <div className={isReply ? 'mt-3 border-l border-scam-line pl-4 ml-3 sm:ml-5' : ''}>
      <div className="flex items-start gap-3 min-w-0">
        <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md border border-scam-line bg-scam-750 text-xs font-semibold text-scam-muted">
          {initials(comment.authorLabel)}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2">
            <span className="text-sm font-semibold text-scam-text">
              {comment.authorLabel}
            </span>
            <span className="text-xs text-scam-dim">{timeAgo(comment.createdAt)}</span>
            {comment.updatedAt !== comment.createdAt && !removed && (
              <span className="text-xs text-scam-dim">(edited)</span>
            )}
          </div>

          {editing ? (
            <div className="mt-1.5">
              <textarea
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                rows={3}
                autoFocus
                className="sr-input resize-none text-sm"
              />
              <div className="mt-2 flex items-center gap-2">
                <button
                  type="button"
                  disabled={!draft.trim() || editMutation.isPending}
                  onClick={() => editMutation.mutate(draft.trim())}
                  className="inline-flex items-center gap-1 rounded-md bg-trust-500 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-trust-600 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  <Check size={13} /> {editMutation.isPending ? 'Saving…' : 'Save'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setEditing(false);
                    setDraft(comment.body);
                    setActionError(null);
                  }}
                  className="inline-flex items-center gap-1 rounded-md px-3 py-1.5 text-xs font-semibold text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
                >
                  <X size={13} /> Cancel
                </button>
              </div>
            </div>
          ) : (
            <p
              className={`mt-1 whitespace-pre-wrap break-words text-sm leading-relaxed ${
                removed ? 'italic text-scam-dim' : 'text-scam-muted'
              }`}
            >
              {removed
                ? comment.status === 'removed'
                  ? 'This comment was deleted by the author.'
                  : 'This comment was removed.'
                : comment.body}
            </p>
          )}

          {flagging && !removed && (
            <div className="mt-2 rounded-md border border-scam-line bg-scam-850 p-3">
              <p className="text-xs font-semibold text-scam-text">
                Why are you reporting this comment?
              </p>
              <div className="mt-2 flex flex-wrap gap-1.5">
                {COMMENT_REPORT_REASONS.map(({ label, reason }) => (
                  <button
                    key={label}
                    type="button"
                    onClick={() => setFlagReason(reason)}
                    className={`rounded-full border px-2.5 py-1 text-xs transition ${
                      flagReason === reason
                        ? 'border-trust-400 bg-trust-400/10 text-scam-text'
                        : 'border-scam-line text-scam-muted hover:border-scam-muted'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
              {flagReason === 'other' && (
                <textarea
                  value={flagDetails}
                  onChange={(e) => setFlagDetails(e.target.value)}
                  rows={2}
                  autoFocus
                  placeholder="Tell us more about why you're reporting this comment…"
                  className="sr-input mt-2 resize-none text-sm"
                />
              )}
              <div className="mt-2.5 flex items-center gap-2">
                <button
                  type="button"
                  disabled={
                    !flagReason ||
                    flagMutation.isPending ||
                    (flagReason === 'other' && !flagDetails.trim())
                  }
                  onClick={() =>
                    flagReason &&
                    flagMutation.mutate({
                      reason: flagReason,
                      details: flagDetails.trim() || undefined,
                    })
                  }
                  className="rounded-md bg-trust-500 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-trust-600 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  {flagMutation.isPending ? 'Submitting…' : 'Submit report'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setFlagging(false);
                    setFlagReason(null);
                    setFlagDetails('');
                    setActionError(null);
                  }}
                  className="rounded-md px-3 py-1.5 text-xs font-semibold text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
                >
                  Cancel
                </button>
              </div>
            </div>
          )}

          {flagDone && (
            <p className="mt-2 text-xs font-medium text-risk-low">
              Thanks — our team will review this comment.
            </p>
          )}

          {/* Action row: like + reply. Any comment or reply can be replied to
              (arbitrarily deep threads). */}
          {!removed && !editing && !flagging && (
            <div className="mt-1.5 flex items-center gap-3">
              <motion.button
                type="button"
                whileTap={{ scale: 0.8 }}
                transition={{ type: 'spring', stiffness: 500, damping: 15 }}
                onClick={like.toggle}
                aria-label={like.liked ? 'Unlike comment' : 'Like comment'}
                aria-pressed={like.liked}
                className={`inline-flex items-center gap-1 text-xs font-semibold transition hover:text-trust-400 ${
                  like.liked ? 'text-trust-400' : 'text-scam-muted'
                }`}
              >
                <motion.span
                  key={like.liked ? 'liked' : 'unliked'}
                  initial={{ scale: 0.6 }}
                  animate={{ scale: 1 }}
                  transition={{ type: 'spring', stiffness: 500, damping: 12 }}
                >
                  <ArrowBigUp size={15} fill={like.liked ? 'currentColor' : 'none'} />
                </motion.span>
                <motion.span
                  key={`like-${like.count}`}
                  initial={{ y: -4, opacity: 0.4 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ duration: 0.18 }}
                  className="tabular-nums"
                >
                  {like.count}
                </motion.span>
              </motion.button>

              {isLoggedIn && !atMaxDepth && (
                <button
                  type="button"
                  onClick={() => setReplying((r) => !r)}
                  className="inline-flex items-center gap-1 text-xs font-semibold text-scam-muted transition hover:text-trust-400"
                >
                  <Reply size={13} /> Reply
                </button>
              )}
            </div>
          )}

          {replying && !removed && (
            <div className="mt-2">
              <textarea
                value={replyDraft}
                onChange={(e) => setReplyDraft(e.target.value)}
                rows={2}
                autoFocus
                placeholder={`Reply to ${comment.authorLabel}…`}
                className="sr-input resize-none text-sm"
              />
              <div className="mt-2 flex items-center gap-2">
                <button
                  type="button"
                  disabled={!replyDraft.trim() || replyMutation.isPending}
                  onClick={() => replyMutation.mutate(replyDraft.trim())}
                  className="inline-flex items-center gap-1 rounded-md bg-trust-500 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-trust-600 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  <Send size={13} /> {replyMutation.isPending ? 'Posting…' : 'Reply'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setReplying(false);
                    setReplyDraft('');
                    setActionError(null);
                  }}
                  className="inline-flex items-center gap-1 rounded-md px-3 py-1.5 text-xs font-semibold text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
                >
                  <X size={13} /> Cancel
                </button>
              </div>
            </div>
          )}

          {actionError && (
            <p role="alert" className="mt-2 text-xs font-medium text-risk-high">
              {actionError}
            </p>
          )}
        </div>

        {isLoggedIn && !removed && !editing && !flagging && !flagDone && (
          <CommentMenu
            isAuthor={isAuthor}
            onFlag={() => setFlagging(true)}
            onEdit={() => {
              setDraft(comment.body);
              setEditing(true);
            }}
            onDelete={() => {
              if (
                window.confirm('Delete this comment? This cannot be undone.')
              ) {
                deleteMutation.mutate();
              }
            }}
          />
        )}
      </div>

      {(childrenByParent.get(comment.id) ?? []).map((child) => (
        <CommentItem
          key={child.id}
          comment={child}
          postId={postId}
          depth={nextDepth}
          childrenByParent={childrenByParent}
        />
      ))}
    </div>
  );
}

/**
 * Fetches and renders a post's discussion thread. Top-level comments are shown
 * oldest-first with their replies nested recursively beneath (via parent_id).
 */
export function CommentList({ postId }: CommentListProps) {
  const {
    data,
    isLoading,
    isError,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
  } = useComments(postId);

  if (isLoading) {
    return (
      <div className="space-y-4 py-2">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="flex items-start gap-3">
            <div className="h-8 w-8 shrink-0 animate-pulse rounded-md bg-scam-750" />
            <div className="flex-1 space-y-2">
              <div className="h-3 w-28 animate-pulse rounded bg-scam-750" />
              <div className="h-3 w-full animate-pulse rounded bg-scam-750" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <p className="py-3 text-sm text-risk-high">
        Couldn't load comments: {(error as Error).message}
      </p>
    );
  }

  const comments = data?.pages.flatMap((p) => p.comments) ?? [];

  if (comments.length === 0) {
    return (
      <div className="flex items-center gap-2 py-4 text-sm text-scam-muted">
        <MessageCircle size={16} /> No comments yet — be the first to reply.
      </div>
    );
  }

  // Build a parent→children map so each comment can render its own replies
  // recursively, supporting arbitrarily deep threads. Order follows the API.
  const childrenByParent = new Map<string, Comment[]>();
  const ids = new Set(comments.map((c) => c.id));
  for (const c of comments) {
    // Treat a comment whose parent isn't in the loaded set as top-level so it
    // never gets dropped from the thread.
    const parentKey = c.parentId && ids.has(c.parentId) ? c.parentId : '__root__';
    const arr = childrenByParent.get(parentKey) ?? [];
    arr.push(c);
    childrenByParent.set(parentKey, arr);
  }
  const topLevel = childrenByParent.get('__root__') ?? [];

  return (
    <div className="space-y-5">
      {topLevel.map((comment) => (
        <CommentItem
          key={comment.id}
          comment={comment}
          postId={postId}
          childrenByParent={childrenByParent}
        />
      ))}

      {hasNextPage && (
        <button
          type="button"
          onClick={() => fetchNextPage()}
          disabled={isFetchingNextPage}
          className="text-xs font-semibold text-trust-400 transition hover:text-trust-300 disabled:opacity-60"
        >
          {isFetchingNextPage ? 'Loading…' : 'Load more comments'}
        </button>
      )}
    </div>
  );
}
