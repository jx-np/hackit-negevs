import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import type { ApiFeedItem, ApiPostDetail } from '../types';
import { createPost, getPost, getPosts } from './posts';

afterEach(() => {
  vi.unstubAllGlobals();
});

function feedItem(over: Partial<ApiFeedItem> = {}): ApiFeedItem {
  return {
    post_id: '12',
    title: 'Fake bank SMS',
    redacted_excerpt: 'Your account is suspended ...',
    category: { slug: 'phishing', name_key: 'category.phishing' },
    tags: [{ slug: 'bank-impersonation', name_key: 'tag.bank_impersonation' }],
    review_status: 'reviewed',
    created_at: '2026-09-29T08:30:00Z',
    comment_count: 4,
    ...over,
  };
}

function postDetail(over: Partial<ApiPostDetail> = {}): ApiPostDetail {
  return {
    post_id: '12',
    title: 'Fake bank SMS',
    redacted_text: 'Your account is suspended ...',
    category: { slug: 'phishing', name_key: 'category.phishing' },
    tags: [{ slug: 'bank-impersonation', name_key: 'tag.bank_impersonation' }],
    review_status: 'reviewed',
    created_at: '2026-09-29T08:30:00Z',
    updated_at: '2026-09-29T09:00:00Z',
    comment_count: 4,
    reactions: { up: 10, down: 1 },
    my_vote: 0,
    ...over,
  };
}

describe('getPosts (feed API)', () => {
  it('calls the feed endpoint and maps items to Post shape', async () => {
    mockFetch([
      {
        match: '/community/feed',
        json: { items: [feedItem()], next_cursor: 'abc123' },
      },
    ]);

    const result = await getPosts({});
    expect(result.posts).toHaveLength(1);
    const post = result.posts[0];
    expect(post.id).toBe('12');
    expect(post.title).toBe('Fake bank SMS');
    expect(post.excerpt).toBe('Your account is suspended ...');
    expect(post.tags[0].id).toBe('phishing');
    expect(post.replyCount).toBe(4);
    expect(result.nextCursor).toBe('abc123');
  });

  it('uses the search endpoint when a query is provided', async () => {
    const fetchMock = mockFetch([
      { match: '/community/feed/search', json: { items: [] } },
    ]);
    await getPosts({ query: 'bank' });
    const url = fetchMock.mock.calls[0][0] as string;
    expect(url).toContain('/community/feed/search');
    expect(url).toContain('q=bank');
  });

  it('passes scam_type when filtering by tag', async () => {
    const fetchMock = mockFetch([
      { match: '/community/feed', json: { items: [] } },
    ]);
    await getPosts({ tagId: 'phishing' });
    const url = fetchMock.mock.calls[0][0] as string;
    expect(url).toContain('scam_type=phishing');
  });

  it('passes cursor when paginating', async () => {
    const fetchMock = mockFetch([
      { match: '/community/feed', json: { items: [] } },
    ]);
    await getPosts({ cursor: 'nextcur' });
    const url = fetchMock.mock.calls[0][0] as string;
    expect(url).toContain('cursor=nextcur');
  });

  it('returns null nextCursor when the backend omits it', async () => {
    mockFetch([
      { match: '/community/feed', json: { items: [feedItem()] } },
    ]);
    const result = await getPosts({});
    expect(result.nextCursor).toBeNull();
  });
});

describe('getPost (detail API)', () => {
  it('fetches and maps a post detail', async () => {
    mockFetch([
      { match: '/community/posts/', json: postDetail() },
    ]);
    const post = await getPost('12');
    expect(post.id).toBe('12');
    expect(post.likeCount).toBe(10);
    expect(post.tags.length).toBeGreaterThan(0);
    expect(post.excerpt).toBe('Your account is suspended ...');
  });
});

describe('createPost', () => {
  it('rejects when authorId is missing', async () => {
    await expect(
      createPost({
        title: 'Test',
        excerpt: 'Description of the scam report.',
        tagId: 'phishing',
        authorName: 'Alice',
        authorId: '',
      }),
    ).rejects.toThrow(/logged in/i);
  });

  it('sends the correct backend payload', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/posts',
        method: 'POST',
        status: 201,
        json: postDetail({ post_id: '99' }),
      },
    ]);

    const post = await createPost({
      title: 'New scam',
      excerpt: 'Details here.',
      tagId: 'phishing',
      authorName: 'Alice',
      authorId: 'user-1',
    });

    expect(post.id).toBe('99');
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect(body.scam_type).toBe('phishing');
    expect(body.confirm_publication).toBe(true);
    expect(body.redacted_text).toBe('Details here.');
  });
});
