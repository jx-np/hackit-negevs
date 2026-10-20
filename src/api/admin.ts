/**
 * Admin API — the moderator/admin back office (`/api/v1/admin/*`).
 *
 * These endpoints use the same JWT access token as the public site and are
 * only reachable for principals whose token carries the `moderator` or
 * `admin` role. The API layer maps the snake_case wire shapes onto the
 * camelCase admin types consumed by the dashboard.
 *
 * Moderation *decisions* (hide/remove/restore/review) live under
 * `/moderation/*` and are exposed here as well, because resolving a flag is
 * how the reports queue is cleared.
 */
import type {
  AdminComment,
  AdminCommentFilters,
  AdminFlag,
  AdminFlagFilters,
  AdminPage,
  AdminPost,
  AdminPostFilters,
  AdminStats,
  AdminUser,
  AdminUserFilters,
  ApiAdminComment,
  ApiAdminFlag,
  ApiAdminPost,
  ApiAdminStats,
  ApiAdminUser,
  ApiBulkDeleteResponse,
  ApiListResponse,
  BulkDeleteFailure,
  BulkDeleteResult,
  CommentReviewDecision,
  PostReviewDecision,
  UserRole,
} from '../types';
import { apiFetch } from './client';

const DEFAULT_LIMIT = 20;

/** Build a query string, dropping empty/null values. */
function query(
  params: Record<string, string | number | null | undefined>,
): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue;
    search.set(key, String(value));
  }
  const qs = search.toString();
  return qs ? `?${qs}` : '';
}

// ---------------------------------------------------------------------------
// Mappers
// ---------------------------------------------------------------------------

function mapStats(s: ApiAdminStats): AdminStats {
  return {
    posts: { ...s.posts },
    comments: { ...s.comments },
    flags: { open: s.flags.open, flaggedPosts: s.flags.flagged_posts },
    users: { ...s.users },
  };
}

function mapPost(p: ApiAdminPost): AdminPost {
  return {
    id: p.post_id,
    authorId: p.author_id,
    authorLabel: p.author_label,
    title: p.title,
    body: p.redacted_text,
    reviewStatus: p.review_status,
    categorySlug: p.category_slug,
    tags: p.tags ?? [],
    commentCount: p.comment_count,
    upCount: p.up_count,
    downCount: p.down_count,
    createdAt: p.created_at,
    updatedAt: p.updated_at,
    deletedAt: p.deleted_at,
    isDeleted: p.is_deleted,
  };
}

function mapComment(c: ApiAdminComment): AdminComment {
  return {
    id: c.comment_id,
    postId: c.post_id,
    postTitle: c.post_title,
    authorId: c.author_id,
    authorLabel: c.author_label,
    isBot: !!c.is_bot,
    parentId: c.parent_id ?? null,
    body: c.body,
    status: c.status,
    createdAt: c.created_at,
    updatedAt: c.updated_at,
    postDeleted: c.post_deleted,
  };
}

function mapFlag(f: ApiAdminFlag): AdminFlag {
  return {
    id: f.flag_id,
    reporterId: f.reporter_id,
    reason: f.reason,
    details: f.details,
    status: f.status,
    createdAt: f.created_at,
    resolvedAt: f.resolved_at,
    targetType: f.target_type,
    targetId: f.target_id,
    postId: f.post_id,
    postTitle: f.post_title,
    excerpt: f.excerpt,
    postReviewStatus: f.post_review_status,
    postDeleted: f.post_deleted,
    commentStatus: f.comment_status,
    targetAuthorId: f.target_author_id,
  };
}

function mapUser(u: ApiAdminUser): AdminUser {
  return {
    id: u.user_id,
    email: u.email,
    displayName: u.display_name,
    role: u.role,
    locale: u.locale,
    isBot: u.is_bot,
    createdAt: u.created_at,
  };
}

function mapPage<TWire, TUi>(
  res: ApiListResponse<TWire>,
  map: (item: TWire) => TUi,
): AdminPage<TUi> {
  return {
    items: (res.items ?? []).map(map),
    nextCursor: res.next_cursor ?? null,
  };
}

// ---------------------------------------------------------------------------
// Dashboard statistics
// ---------------------------------------------------------------------------

export async function getAdminStats(): Promise<AdminStats> {
  const res = await apiFetch<ApiAdminStats>('/admin/stats');
  return mapStats(res);
}

// ---------------------------------------------------------------------------
// Posts
// ---------------------------------------------------------------------------

export async function getAdminPosts(
  filters: AdminPostFilters = {},
): Promise<AdminPage<AdminPost>> {
  const path = `/admin/posts${query({
    status: filters.status ?? 'all',
    q: filters.q?.trim(),
    author_id: filters.authorId,
    limit: filters.limit ?? DEFAULT_LIMIT,
    cursor: filters.cursor,
  })}`;
  const res = await apiFetch<ApiListResponse<ApiAdminPost>>(path);
  return mapPage(res, mapPost);
}

async function runBulkDelete(
  path: string,
  payloadKey: 'post_ids' | 'comment_ids',
  ids: string[],
): Promise<BulkDeleteResult> {
  const unique = [...new Set(ids)];
  const deleted: string[] = [];
  const failed: BulkDeleteFailure[] = [];

  // The server caps a batch at 100 distinct ids; chunk larger selections.
  for (let i = 0; i < unique.length; i += 100) {
    const chunk = unique.slice(i, i + 100);
    const res = await apiFetch<ApiBulkDeleteResponse>(path, {
      method: 'POST',
      body: JSON.stringify({ [payloadKey]: chunk }),
    });
    deleted.push(...(res.deleted ?? []));
    failed.push(
      ...(res.failed ?? []).map((f) => ({ id: f.id, reason: f.reason })),
    );
  }

  return {
    deleted,
    failed,
    deletedCount: deleted.length,
    failedCount: failed.length,
  };
}

/** Soft-delete up to any number of posts (chunked at the server's 100-id cap). */
export function bulkDeletePosts(ids: string[]): Promise<BulkDeleteResult> {
  return runBulkDelete('/admin/posts/bulk-delete', 'post_ids', ids);
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

export async function getAdminComments(
  filters: AdminCommentFilters = {},
): Promise<AdminPage<AdminComment>> {
  const path = `/admin/comments${query({
    status: filters.status ?? 'all',
    post_id: filters.postId,
    author_id: filters.authorId,
    q: filters.q?.trim(),
    limit: filters.limit ?? DEFAULT_LIMIT,
    cursor: filters.cursor,
  })}`;
  const res = await apiFetch<ApiListResponse<ApiAdminComment>>(path);
  return mapPage(res, mapComment);
}

/** Soft-remove up to any number of comments (chunked at 100 per call). */
export function bulkDeleteComments(ids: string[]): Promise<BulkDeleteResult> {
  return runBulkDelete('/admin/comments/bulk-delete', 'comment_ids', ids);
}

// ---------------------------------------------------------------------------
// Flags
// ---------------------------------------------------------------------------

export async function getAdminFlags(
  filters: AdminFlagFilters = {},
): Promise<AdminPage<AdminFlag>> {
  const path = `/admin/flags${query({
    status: filters.status ?? 'open',
    target_type: filters.targetType ?? 'all',
    limit: filters.limit ?? DEFAULT_LIMIT,
    cursor: filters.cursor,
  })}`;
  const res = await apiFetch<ApiListResponse<ApiAdminFlag>>(path);
  return mapPage(res, mapFlag);
}

// ---------------------------------------------------------------------------
// Users & roles (admin only)
// ---------------------------------------------------------------------------

export async function getAdminUsers(
  filters: AdminUserFilters = {},
): Promise<AdminPage<AdminUser>> {
  const path = `/admin/users${query({
    q: filters.q?.trim(),
    role: filters.role ?? 'all',
    limit: filters.limit ?? DEFAULT_LIMIT,
    cursor: filters.cursor,
  })}`;
  const res = await apiFetch<ApiListResponse<ApiAdminUser>>(path);
  return mapPage(res, mapUser);
}

/**
 * Change an account's role. The backend revokes the target's refresh sessions;
 * their current access token keeps the old role until it expires.
 */
export async function updateUserRole(
  id: string,
  role: UserRole,
): Promise<AdminUser> {
  const res = await apiFetch<ApiAdminUser>(
    `/admin/users/${encodeURIComponent(id)}/role`,
    {
      method: 'PATCH',
      body: JSON.stringify({ role }),
    },
  );
  return mapUser(res);
}

// ---------------------------------------------------------------------------
// Moderation decisions (used to resolve flags)
// ---------------------------------------------------------------------------

export async function reviewPost(
  id: string,
  decision: PostReviewDecision,
  rationale?: string,
): Promise<void> {
  await apiFetch<void>(`/moderation/posts/${encodeURIComponent(id)}/review`, {
    method: 'POST',
    body: JSON.stringify({
      decision,
      ...(rationale ? { rationale } : {}),
    }),
  });
}

export async function reviewComment(
  id: string,
  decision: CommentReviewDecision,
  rationale?: string,
): Promise<void> {
  await apiFetch<void>(
    `/moderation/comments/${encodeURIComponent(id)}/review`,
    {
      method: 'POST',
      body: JSON.stringify({
        decision,
        ...(rationale ? { rationale } : {}),
      }),
    },
  );
}
