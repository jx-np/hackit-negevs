import type { NewPostInput, Post, PostsPage, PostsQuery } from '../types';
import { apiFetch, delay, USE_MOCK } from './client';
import { MOCK_POSTS, MOCK_TAGS } from './mockData';

const DEFAULT_PAGE_SIZE = 8;

/**
 * Fetch a single post by id (for the detail / thread view).
 *
 * Real API integration: replace the mock branch, e.g.
 *   return apiFetch<Post>(`/posts/${id}`);
 */
export async function getPost(id: string): Promise<Post> {
  if (USE_MOCK) {
    const post = MOCK_POSTS.find((p) => p.id === id);
    if (!post) {
      return Promise.reject(new Error('Post not found'));
    }
    return delay(post, 300);
  }
  return apiFetch<Post>(`/posts/${encodeURIComponent(id)}`);
}

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
  sort = 'new',
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

    const sorted = [...filtered].sort((a, b) => {
      if (sort === 'comments') return b.replyCount - a.replyCount;
      if (sort === 'likes') return b.likeCount - a.likeCount;
      // 'new' — most recent first
      return (
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      );
    });

    const start = (page - 1) * pageSize;
    const slice = sorted.slice(start, start + pageSize);
    const hasMore = start + pageSize < sorted.length;

    return delay(
      {
        posts: slice,
        nextPage: hasMore ? page + 1 : null,
        total: sorted.length,
      },
      500,
    );
  }

  const params = new URLSearchParams();
  if (query) params.set('search', query);
  if (tagId) params.set('tag', tagId);
  params.set('sort', sort);
  params.set('page', String(page));
  params.set('pageSize', String(pageSize));

  return apiFetch<PostsPage>(`/posts?${params.toString()}`);
}

/**
 * Create a new report (post). The UI only calls this for logged-in users;
 * the real backend must also enforce authentication.
 *
 * Real API integration: replace the mock branch, e.g.
 *   return apiFetch<Post>('/posts', { method: 'POST', body: JSON.stringify(input) });
 */
export async function createPost(input: NewPostInput): Promise<Post> {
  if (USE_MOCK) {
    const tag = MOCK_TAGS.find((t) => t.id === input.tagId);
    const post: Post = {
      id: `post-new-${Date.now()}`,
      title: input.title,
      excerpt: input.excerpt,
      body: input.body,
      author: { id: 'me', name: input.authorName },
      tags: tag ? [tag] : [],
      createdAt: new Date().toISOString(),
      replyCount: 0,
      likeCount: 0,
      imageUrl: input.imageUrl ?? null,
      risk: input.risk ?? null,
    };
    // Prepend so it appears first under the default "newest" sort.
    MOCK_POSTS.unshift(post);
    return delay(post, 400);
  }
  return apiFetch<Post>('/posts', {
    method: 'POST',
    body: JSON.stringify(input),
  });
}
