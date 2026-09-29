import { describe, expect, it } from 'vitest';
import { createPost, getPosts } from './posts';

describe('getPosts (mock mode)', () => {
  it('returns the first page with the default page size', async () => {
    const result = await getPosts({ page: 1 });
    expect(result.posts).toHaveLength(8);
    expect(result.total).toBeGreaterThan(8);
    expect(result.nextPage).toBe(2);
  });

  it('paginates: page 2 returns different posts than page 1', async () => {
    const page1 = await getPosts({ page: 1 });
    const page2 = await getPosts({ page: 2 });
    const overlap = page1.posts.filter((p) =>
      page2.posts.some((q) => q.id === p.id),
    );
    expect(overlap).toHaveLength(0);
  });

  it('sets nextPage to null on the final page', async () => {
    const first = await getPosts({ page: 1 });
    const lastPage = Math.ceil(first.total / 8);
    const result = await getPosts({ page: lastPage });
    expect(result.nextPage).toBeNull();
  });

  it('filters by a text query (case-insensitive)', async () => {
    const result = await getPosts({ query: 'react', page: 1, pageSize: 100 });
    expect(result.posts.length).toBeGreaterThan(0);
    for (const post of result.posts) {
      const haystack =
        `${post.title} ${post.excerpt} ${post.author.name}`.toLowerCase();
      expect(haystack).toContain('react');
    }
  });

  it('matches by author name', async () => {
    const result = await getPosts({ query: 'Ada', page: 1, pageSize: 100 });
    expect(result.posts.length).toBeGreaterThan(0);
    expect(
      result.posts.every((p) => p.author.name.includes('Ada')),
    ).toBe(true);
  });

  it('filters by a single tag id', async () => {
    const result = await getPosts({
      tagId: 't-react',
      page: 1,
      pageSize: 100,
    });
    expect(result.posts.length).toBeGreaterThan(0);
    expect(
      result.posts.every((p) => p.tags.some((t) => t.id === 't-react')),
    ).toBe(true);
  });

  it('combines text query and tag filter', async () => {
    const result = await getPosts({
      query: 'react',
      tagId: 't-react',
      page: 1,
      pageSize: 100,
    });
    for (const post of result.posts) {
      expect(post.tags.some((t) => t.id === 't-react')).toBe(true);
      const haystack =
        `${post.title} ${post.excerpt} ${post.author.name}`.toLowerCase();
      expect(haystack).toContain('react');
    }
  });

  it('returns an empty result set for a non-matching query', async () => {
    const result = await getPosts({
      query: 'zzz-nonexistent-term',
      page: 1,
    });
    expect(result.posts).toHaveLength(0);
    expect(result.total).toBe(0);
    expect(result.nextPage).toBeNull();
  });
});


describe('getPosts sorting (mock mode)', () => {
  it('sorts by likes descending', async () => {
    const result = await getPosts({ sort: 'likes', page: 1, pageSize: 100 });
    const likes = result.posts.map((p) => p.likeCount);
    const sorted = [...likes].sort((a, b) => b - a);
    expect(likes).toEqual(sorted);
  });

  it('sorts by comment count descending', async () => {
    const result = await getPosts({ sort: 'comments', page: 1, pageSize: 100 });
    const replies = result.posts.map((p) => p.replyCount);
    const sorted = [...replies].sort((a, b) => b - a);
    expect(replies).toEqual(sorted);
  });

  it('sorts by newest first (default)', async () => {
    const result = await getPosts({ sort: 'new', page: 1, pageSize: 100 });
    const times = result.posts.map((p) => new Date(p.createdAt).getTime());
    const sorted = [...times].sort((a, b) => b - a);
    expect(times).toEqual(sorted);
  });
});

describe('getPosts images (mock mode)', () => {
  it('includes some posts with an imageUrl', async () => {
    const result = await getPosts({ page: 1, pageSize: 100 });
    expect(result.posts.some((p) => !!p.imageUrl)).toBe(true);
  });
});


describe('createPost — requires a logged-in author', () => {
  const base = {
    title: 'A new scam report',
    excerpt: 'A description of the scam that is long enough.',
    tagId: 't-react',
    authorName: 'Alice',
  };

  it('rejects when authorId is missing', async () => {
    await expect(
      createPost({ ...base, authorId: '' }),
    ).rejects.toThrow(/logged in/i);
  });

  it('creates a post when an authorId is provided', async () => {
    const post = await createPost({ ...base, authorId: 'user-1' });
    expect(post.id).toBeTruthy();
    expect(post.author.id).toBe('user-1');
    expect(post.title).toBe(base.title);
  });
});
