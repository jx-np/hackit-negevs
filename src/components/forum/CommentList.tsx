import { MessageCircle } from 'lucide-react';
import { useComments } from '../../hooks/useComments';
import type { Comment } from '../../types';

interface CommentListProps {
  postId: string;
}

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

function CommentItem({ comment, isReply }: { comment: Comment; isReply?: boolean }) {
  const removed = comment.status === 'removed' || comment.status === 'hidden';
  return (
    <div className={isReply ? 'mt-3 ml-6 border-l border-scam-line pl-4' : ''}>
      <div className="flex items-start gap-3">
        <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md border border-scam-line bg-scam-750 text-xs font-semibold text-scam-muted">
          {initials(comment.authorLabel)}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-x-2">
            <span className="text-sm font-semibold text-scam-text">
              {comment.authorLabel}
            </span>
            <span className="text-xs text-scam-dim">{timeAgo(comment.createdAt)}</span>
          </div>
          <p
            className={`mt-1 whitespace-pre-wrap break-words text-sm leading-relaxed ${
              removed ? 'italic text-scam-dim' : 'text-scam-muted'
            }`}
          >
            {removed ? 'This comment was removed.' : comment.body}
          </p>
        </div>
      </div>
    </div>
  );
}

/**
 * Fetches and renders a post's discussion thread. Top-level comments are shown
 * oldest-first with their one-level replies nested beneath (via parent_id).
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

  // Group one-level replies under their parent; keep order from the API.
  const topLevel = comments.filter((c) => !c.parentId);
  const repliesByParent = new Map<string, Comment[]>();
  for (const c of comments) {
    if (c.parentId) {
      const arr = repliesByParent.get(c.parentId) ?? [];
      arr.push(c);
      repliesByParent.set(c.parentId, arr);
    }
  }

  return (
    <div className="space-y-5">
      {topLevel.map((comment) => (
        <div key={comment.id}>
          <CommentItem comment={comment} />
          {(repliesByParent.get(comment.id) ?? []).map((reply) => (
            <CommentItem key={reply.id} comment={reply} isReply />
          ))}
        </div>
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
