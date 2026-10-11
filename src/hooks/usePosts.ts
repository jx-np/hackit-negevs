import { keepPreviousData, useInfiniteQuery } from '@tanstack/react-query';
import { getPosts } from '../api/posts';
import type { PostsPage, SortKey } from '../types';

interface UsePostsArgs {
  query: string;
  tagId: string | null;
  sort: SortKey;
}

/**
 * Infinite-scroll posts query using cursor pagination. Re-fetches from the
 * beginning whenever the search text, selected tag, or sort order changes.
 */
export function usePosts({ query, tagId, sort }: UsePostsArgs) {
  return useInfiniteQuery<PostsPage>({
    queryKey: ['posts', { query, tagId, sort }],
    queryFn: ({ pageParam }) =>
      getPosts({
        query,
        tagId,
        sort,
        cursor: pageParam as string | null,
      }),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    // Keep the previous feed visible while a new category/search/sort query
    // loads. This prevents the center column from collapsing to skeletons,
    // which would shift the scroll position and make the page jitter.
    placeholderData: keepPreviousData,
  });
}
