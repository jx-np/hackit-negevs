import { useInfiniteQuery } from '@tanstack/react-query';
import { getComments } from '../api/comments';
import type { CommentsPage } from '../types';

/**
 * Fetch a post's discussion thread with cursor pagination.
 *
 * Keyed by ['comments', postId] so that posting a new comment (which
 * invalidates that key in CommentBox) refetches the thread.
 */
export function useComments(postId: string | undefined, limit = 20) {
  return useInfiniteQuery<CommentsPage>({
    queryKey: ['comments', postId],
    queryFn: ({ pageParam }) =>
      getComments(postId as string, (pageParam as string | null) ?? null, limit),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    enabled: !!postId,
  });
}
