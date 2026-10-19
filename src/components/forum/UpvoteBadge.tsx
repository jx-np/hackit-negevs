import { ThumbsUp } from 'lucide-react';

/**
 * Social-proof badge for a post's upvote count.
 *
 * Uses the thumbs-up symbol and the word "upvotes" so the count reads
 * identically everywhere it appears — feed card, post detail, sidebar — and
 * matches the vote control the reader clicks. Self-contained on purpose: one
 * shared badge means the count can never drift in wording, size or visibility
 * between views.
 */
export function UpvoteBadge({
  count,
  className = '',
}: {
  count: number;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 text-xs font-medium ${className}`}
    >
      <ThumbsUp size={14} aria-hidden />
      <span>
        <span className="sr-nums">{count}</span> {count === 1 ? 'upvote' : 'upvotes'}
      </span>
    </span>
  );
}
