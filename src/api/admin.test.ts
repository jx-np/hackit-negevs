import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import {
  bulkDeletePosts,
  getAdminFlags,
  getAdminPosts,
  getAdminStats,
  getAdminUsers,
  updateUserRole,
} from './admin';

afterEach(() => vi.unstubAllGlobals());

describe('admin API', () => {
  it('maps the dashboard statistics, including flagged_posts', async () => {
    mockFetch([
      {
        match: '/admin/stats',
        json: {
          posts: { total: 128, visible: 101, hidden: 4, removed: 3, deleted: 20 },
          comments: { total: 540, visible: 512, hidden: 9, removed: 19 },
          flags: { open: 7, flagged_posts: 5 },
          users: { total: 64 },
        },
      },
    ]);

    const stats = await getAdminStats();
    expect(stats.posts.total).toBe(128);
    expect(stats.comments.removed).toBe(19);
    expect(stats.flags).toEqual({ open: 7, flaggedPosts: 5 });
    expect(stats.users.total).toBe(64);
  });

  it('passes post filters through and maps the page shape', async () => {
    const fetchMock = mockFetch([
      {
        match: '/admin/posts',
        json: {
          items: [
            {
              post_id: '44',
              author_id: '12',
              author_label: 'Aisyah',
              title: 'DBS account suspended',
              redacted_text: 'Your account is suspended.',
              review_status: 'hidden',
              category_slug: 'phishing',
              tags: ['bank-impersonation'],
              comment_count: 6,
              up_count: 3,
              down_count: 1,
              created_at: '2026-10-19T08:10:00Z',
              updated_at: '2026-10-19T09:00:00Z',
              is_deleted: false,
            },
          ],
          next_cursor: 'abc',
        },
      },
    ]);

    const page = await getAdminPosts({ status: 'hidden', q: 'bank' });
    expect(page.nextCursor).toBe('abc');
    expect(page.items[0]).toMatchObject({
      id: '44',
      title: 'DBS account suspended',
      body: 'Your account is suspended.',
      reviewStatus: 'hidden',
      categorySlug: 'phishing',
      tags: ['bank-impersonation'],
      commentCount: 6,
      isDeleted: false,
    });

    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain('/admin/posts?');
    expect(url).toContain('status=hidden');
    expect(url).toContain('q=bank');
  });

  it('maps flags and users wire fields', async () => {
    mockFetch([
      {
        match: '/admin/flags',
        json: {
          items: [
            {
              flag_id: '5',
              reporter_id: '27',
              reason: 'personal_information',
              details: 'Phone number still visible.',
              status: 'open',
              created_at: '2026-10-19T09:20:00Z',
              target_type: 'post',
              target_id: '44',
              post_id: '44',
              post_title: 'DBS account suspended',
              excerpt: 'Call 9123 4567',
              post_review_status: 'unverified',
              post_deleted: false,
              target_author_id: '12',
            },
          ],
        },
      },
      {
        match: '/admin/users',
        json: {
          items: [
            {
              user_id: '12',
              email: 'aisyah@example.sg',
              display_name: 'Aisyah',
              role: 'moderator',
              locale: 'en-SG',
              is_bot: false,
              created_at: '2026-09-01T04:00:00Z',
            },
          ],
        },
      },
    ]);

    const flags = await getAdminFlags({ status: 'open', targetType: 'post' });
    expect(flags.items[0]).toMatchObject({
      id: '5',
      targetType: 'post',
      targetId: '44',
      postReviewStatus: 'unverified',
      targetAuthorId: '12',
    });

    const users = await getAdminUsers({ role: 'moderator' });
    expect(users.items[0]).toMatchObject({
      id: '12',
      displayName: 'Aisyah',
      role: 'moderator',
      isBot: false,
    });
  });

  it('maps a role update response', async () => {
    mockFetch([
      {
        match: /\/admin\/users\/12\/role/,
        method: 'PATCH',
        json: {
          user_id: '12',
          email: 'aisyah@example.sg',
          display_name: 'Aisyah',
          role: 'admin',
          locale: 'en-SG',
          is_bot: false,
          created_at: '2026-09-01T04:00:00Z',
        },
      },
    ]);

    const user = await updateUserRole('12', 'admin');
    expect(user.role).toBe('admin');
  });

  it('chunks bulk deletions at 100 ids and aggregates the results', async () => {
    const fetchMock = mockFetch([
      {
        match: '/admin/posts/bulk-delete',
        method: 'POST',
        json: {
          deleted: ['1'],
          failed: [{ id: '2', reason: 'not_found' }],
          deleted_count: 1,
          failed_count: 1,
        },
      },
    ]);

    const ids = Array.from({ length: 150 }, (_, i) => String(i + 1));
    const result = await bulkDeletePosts(ids);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    const bodies = fetchMock.mock.calls.map((call) =>
      JSON.parse(String((call[1] as RequestInit).body)),
    );
    expect(bodies[0].post_ids).toHaveLength(100);
    expect(bodies[1].post_ids).toHaveLength(50);
    expect(result.deletedCount).toBe(2);
    expect(result.failedCount).toBe(2);
  });
});
