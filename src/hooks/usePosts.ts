import { useInfiniteQuery } from '@tanstack/react-query';
import { getPosts } from '../api/posts';
import type { PostsPage, SortKey } from '../types';

interface UsePostsArgs {
  query: string;
  tagId: string | null;
  sort: SortKey;
}

/**
 * Infinite-scroll posts query. Re-fetches from page 1 whenever the search
 * text, selected tag, or sort order changes (they are part of the query key).
 */
export function usePosts({ query, tagId, sort }: UsePostsArgs) {
  return useInfiniteQuery<PostsPage>({
    queryKey: ['posts', { query, tagId, sort }],
    queryFn: ({ pageParam }) =>
      getPosts({ query, tagId, sort, page: pageParam as number }),
    initialPageParam: 1,
    getNextPageParam: (lastPage) => lastPage.nextPage ?? undefined,
  });
}
