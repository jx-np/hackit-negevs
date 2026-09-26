import type { PostsPage, PostsQuery } from '../types';
import { apiFetch, delay, USE_MOCK } from './client';
import { MOCK_POSTS } from './mockData';

const DEFAULT_PAGE_SIZE = 8;

/**
 * Fetch a page of posts, filtered by free-text query and/or a single tag.
 *
 * Real API integration: replace the mock branch with a request that maps
 * these params to your backend's query string, e.g.
 *   return apiFetch<PostsPage>(
 *     `/posts?search=${query}&tag=${tagId}&page=${page}`
 *   );
 */
export async function getPosts({
  query = '',
  tagId = null,
  page = 1,
  pageSize = DEFAULT_PAGE_SIZE,
}: PostsQuery): Promise<PostsPage> {
  if (USE_MOCK) {
    const q = query.trim().toLowerCase();

    const filtered = MOCK_POSTS.filter((post) => {
      const matchesQuery =
        !q ||
        post.title.toLowerCase().includes(q) ||
        post.excerpt.toLowerCase().includes(q) ||
        post.author.name.toLowerCase().includes(q);

      const matchesTag = !tagId || post.tags.some((t) => t.id === tagId);

      return matchesQuery && matchesTag;
    });

    const start = (page - 1) * pageSize;
    const slice = filtered.slice(start, start + pageSize);
    const hasMore = start + pageSize < filtered.length;

    return delay(
      {
        posts: slice,
        nextPage: hasMore ? page + 1 : null,
        total: filtered.length,
      },
      500,
    );
  }

  const params = new URLSearchParams();
  if (query) params.set('search', query);
  if (tagId) params.set('tag', tagId);
  params.set('page', String(page));
  params.set('pageSize', String(pageSize));

  return apiFetch<PostsPage>(`/posts?${params.toString()}`);
}
