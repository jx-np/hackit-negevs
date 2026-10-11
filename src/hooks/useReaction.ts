/**
 * Reaction (up/down vote) state for a single post.
 *
 * Encapsulates the toggle semantics and optimistic UI used by both the feed
 * card and the post-detail view:
 *   - Clicking the same arrow you already picked clears your vote.
 *   - Clicking the opposite arrow switches your vote.
 *   - Counts update immediately (optimistically) and roll back on error.
 *
 * The backend is the source of truth: every successful call returns the
 * authoritative counts + `my_vote`, which we reconcile into local state.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import { clearReaction, setReaction } from '../api/posts';
import { useAuth } from '../context/AuthContext';
import type { Post } from '../types';

export interface ReactionState {
  /** Up-vote count. */
  upCount: number;
  /** Down-vote count. */
  downCount: number;
  /** Caller's current vote: 1 (up), -1 (down), 0 (none). */
  myVote: number;
  /** True while a request is in flight. */
  pending: boolean;
  /** Non-null when the last action failed. */
  error: string | null;
  /** Toggle the up-vote. */
  upvote: () => void;
  /** Toggle the down-vote. */
  downvote: () => void;
}

/** Predict the next counts/vote for an optimistic update. */
function predict(
  upCount: number,
  downCount: number,
  current: number,
  next: 1 | -1,
): { upCount: number; downCount: number; myVote: number } {
  // Clicking the active arrow clears it; otherwise the vote becomes `next`.
  const resolved = current === next ? 0 : next;

  // Remove the effect of the current vote…
  let up = upCount - (current === 1 ? 1 : 0);
  let down = downCount - (current === -1 ? 1 : 0);
  // …then apply the resolved vote.
  up += resolved === 1 ? 1 : 0;
  down += resolved === -1 ? 1 : 0;

  return { upCount: Math.max(0, up), downCount: Math.max(0, down), myVote: resolved };
}

/**
 * Accepts `Post | undefined` so it can be called unconditionally while the
 * post is still loading (e.g. on the detail page). Local counts initialise
 * from the post and re-sync whenever a new post (by id) arrives.
 */
export function useReaction(post: Post | undefined): ReactionState {
  const { isLoggedIn } = useAuth();
  const [upCount, setUpCount] = useState(post?.likeCount ?? 0);
  const [downCount, setDownCount] = useState(post?.downCount ?? 0);
  const [myVote, setMyVote] = useState(post?.myVote ?? 0);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Re-seed local state when the post first loads or changes identity, so the
  // detail page reflects the server's authoritative counts once fetched.
  const seededId = useRef<string | null>(post?.id ?? null);
  useEffect(() => {
    if (!post) return;
    if (seededId.current !== post.id) {
      seededId.current = post.id;
      setUpCount(post.likeCount);
      setDownCount(post.downCount ?? 0);
      setMyVote(post.myVote ?? 0);
    }
  }, [post]);

  const apply = useCallback(
    async (next: 1 | -1) => {
      if (!post) return;
      if (!isLoggedIn) {
        setError('You must be logged in to vote.');
        return;
      }
      if (pending) return;

      // Snapshot for rollback.
      const prev = { upCount, downCount, myVote };
      const optimistic = predict(upCount, downCount, myVote, next);

      setUpCount(optimistic.upCount);
      setDownCount(optimistic.downCount);
      setMyVote(optimistic.myVote);
      setPending(true);
      setError(null);

      try {
        // myVote === 0 means we're toggling the active arrow off.
        const result =
          optimistic.myVote === 0
            ? await clearReaction(post.id)
            : await setReaction(post.id, next);

        setUpCount(result.upCount);
        setDownCount(result.downCount);
        setMyVote(result.myVote);
      } catch (err) {
        // Roll back on failure.
        setUpCount(prev.upCount);
        setDownCount(prev.downCount);
        setMyVote(prev.myVote);
        setError(err instanceof Error ? err.message : 'Could not save your vote.');
      } finally {
        setPending(false);
      }
    },
    [isLoggedIn, pending, upCount, downCount, myVote, post],
  );

  const upvote = useCallback(() => void apply(1), [apply]);
  const downvote = useCallback(() => void apply(-1), [apply]);

  return { upCount, downCount, myVote, pending, error, upvote, downvote };
}
