import { useInfiniteQuery } from '@tanstack/react-query';
import { getMyPosts } from '../api/posts';
import type { PostsPage } from '../types';

/**
 * Infinite-scroll query over the signed-in user's own posts (`GET /me/posts`).
 * Keyed by ['myPosts'] so post edit/delete mutations can invalidate it.
 */
export function useMyPosts(limit = 20) {
  return useInfiniteQuery<PostsPage>({
    queryKey: ['myPosts'],
    queryFn: ({ pageParam }) =>
      getMyPosts((pageParam as string | null) ?? null, limit),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  });
}
