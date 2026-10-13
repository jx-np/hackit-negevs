import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import type { ApiComment, ApiPostDetail } from '../types';
import {
  deletePost,
  flagPost,
  getMyPosts,
  updatePost,
} from './posts';
import { deleteComment, flagComment, updateComment } from './comments';
import { getGuidance, getResources } from './guidance';

afterEach(() => {
  vi.unstubAllGlobals();
});

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

function apiComment(over: Partial<ApiComment> = {}): ApiComment {
  return {
    comment_id: 'c1',
    parent_id: null,
    author_id: 'user-1',
    author_label: 'Community member',
    body: 'Original body',
    status: 'visible',
    created_at: '2026-09-29T08:30:00Z',
    updated_at: '2026-09-29T08:30:00Z',
    ...over,
  };
}

describe('updatePost', () => {
  it('sends a PATCH with mapped fields and returns the updated post', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/posts/12',
        method: 'PATCH',
        json: postDetail({ title: 'Edited title' }),
      },
    ]);

    const post = await updatePost('12', {
      title: 'Edited title',
      excerpt: 'New redacted text',
      tags: ['phishing'],
    });

    expect(post.title).toBe('Edited title');
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toContain('/community/posts/12');
    expect(init?.method).toBe('PATCH');
    const body = JSON.parse(init?.body as string);
    expect(body.title).toBe('Edited title');
    expect(body.redacted_text).toBe('New redacted text');
    expect(body.tags).toEqual(['phishing']);
  });

  it('omits fields that are not provided', async () => {
    const fetchMock = mockFetch([
      { match: '/community/posts/12', method: 'PATCH', json: postDetail() },
    ]);
    await updatePost('12', { title: 'Only title' });
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect(body).toEqual({ title: 'Only title' });
    expect('redacted_text' in body).toBe(false);
  });
});

describe('deletePost', () => {
  it('sends a DELETE and resolves on 204', async () => {
    const fetchMock = mockFetch([
      { match: '/community/posts/12', method: 'DELETE', status: 204 },
    ]);
    await expect(deletePost('12')).resolves.toBeUndefined();
    expect(fetchMock.mock.calls[0][1]?.method).toBe('DELETE');
  });
});

describe('flagPost', () => {
  it('posts a reason and maps the flag response', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/posts/12/flag',
        method: 'POST',
        status: 201,
        json: { flag_id: 'f1', status: 'pending' },
      },
    ]);

    const result = await flagPost('12', 'spam', 'looks fake');
    expect(result).toEqual({ flagId: 'f1', status: 'pending' });
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect(body.reason).toBe('spam');
    expect(body.details).toBe('looks fake');
  });

  it('omits details when not provided', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/posts/12/flag',
        method: 'POST',
        status: 201,
        json: { flag_id: 'f1', status: 'pending' },
      },
    ]);
    await flagPost('12', 'harmful');
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect('details' in body).toBe(false);
  });
});

describe('getMyPosts', () => {
  it('fetches /me/posts and maps items', async () => {
    const fetchMock = mockFetch([
      {
        match: '/me/posts',
        json: {
          items: [
            {
              post_id: '7',
              title: 'My report',
              redacted_excerpt: 'excerpt',
              category: { slug: 'phishing', name_key: 'category.phishing' },
              tags: [],
              review_status: 'unverified',
              created_at: '2026-09-29T08:30:00Z',
              comment_count: 0,
            },
          ],
          next_cursor: 'cur2',
        },
      },
    ]);

    const page = await getMyPosts();
    expect(page.posts).toHaveLength(1);
    expect(page.posts[0].id).toBe('7');
    expect(page.nextCursor).toBe('cur2');
    expect(fetchMock.mock.calls[0][0]).toContain('/me/posts');
  });
});

describe('updateComment', () => {
  it('sends a PATCH with the new body', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/discussion/comments/c1',
        method: 'PATCH',
        json: apiComment({ body: 'Edited body' }),
      },
    ]);
    const comment = await updateComment('c1', 'Edited body');
    expect(comment.body).toBe('Edited body');
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect(body.body).toBe('Edited body');
  });
});

describe('deleteComment', () => {
  it('sends a DELETE and resolves on 204', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/discussion/comments/c1',
        method: 'DELETE',
        status: 204,
      },
    ]);
    await expect(deleteComment('c1')).resolves.toBeUndefined();
    expect(fetchMock.mock.calls[0][1]?.method).toBe('DELETE');
  });
});

describe('flagComment', () => {
  it('posts a reason and maps the flag response', async () => {
    const fetchMock = mockFetch([
      {
        match: '/community/discussion/comments/c1/flag',
        method: 'POST',
        status: 201,
        json: { flag_id: 'f9', status: 'pending' },
      },
    ]);
    const result = await flagComment('c1', 'misinformation');
    expect(result).toEqual({ flagId: 'f9', status: 'pending' });
    const body = JSON.parse(fetchMock.mock.calls[0][1]?.body as string);
    expect(body.reason).toBe('misinformation');
  });
});

describe('getGuidance', () => {
  it('maps guidance items and passes scenario', async () => {
    const fetchMock = mockFetch([
      {
        match: '/guidance',
        json: {
          items: [
            {
              id: 'g1',
              scenario: 'bank_transfer',
              urgency: 'emergency',
              title: 'Call your bank',
              body: 'Freeze the account.',
              resources: ['scamshield'],
            },
          ],
        },
      },
    ]);

    const items = await getGuidance({ scenario: 'bank_transfer' });
    expect(items).toHaveLength(1);
    expect(items[0].urgency).toBe('emergency');
    expect(items[0].resources).toEqual(['scamshield']);
    expect(fetchMock.mock.calls[0][0]).toContain('scenario=bank_transfer');
  });

  it('tolerates a missing items array', async () => {
    mockFetch([{ match: '/guidance', json: {} }]);
    const items = await getGuidance();
    expect(items).toEqual([]);
  });
});

describe('getResources', () => {
  it('maps resource snake_case fields and passes country', async () => {
    const fetchMock = mockFetch([
      {
        match: '/guidance/resources',
        json: {
          items: [
            {
              id: 'r1',
              slug: 'scamshield',
              country_code: 'SG',
              url: 'https://example.gov',
              contact_instructions: 'Call 999',
              name: 'ScamShield',
              description: 'Official helpline',
              verified_at: '2026-09-01T00:00:00Z',
              owner_name: 'Police',
            },
          ],
        },
      },
    ]);

    const items = await getResources({ country: 'SG' });
    expect(items).toHaveLength(1);
    expect(items[0].countryCode).toBe('SG');
    expect(items[0].contactInstructions).toBe('Call 999');
    expect(items[0].ownerName).toBe('Police');
    expect(items[0].verifiedAt).toBe('2026-09-01T00:00:00Z');
    expect(fetchMock.mock.calls[0][0]).toContain('country=SG');
  });
});
