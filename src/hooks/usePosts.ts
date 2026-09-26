import { useInfiniteQuery } from '@tanstack/react-query';
import { getPosts } from '../api/posts';
import type { PostsPage } from '../types';

interface UsePostsArgs {
  query: string;
  tagId: string | null;
}

/**
 * Infinite-scroll posts query. Re-fetches from page 1 whenever the search
 * text or selected tag changes (they are part of the query key).
 */
export function usePosts({ query, tagId }: UsePostsArgs) {
  return useInfiniteQuery<PostsPage>({
    queryKey: ['posts', { query, tagId }],
    queryFn: ({ pageParam }) =>
      getPosts({ query, tagId, page: pageParam as number }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => lastPage.nextPage ?? undefined,
  });
}
