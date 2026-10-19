/**
 * Discussion (comments) API.
 */
import type {
  ApiComment,
  ApiFlagResponse,
  ApiListResponse,
  ApiStreamComment,
  Comment,
  CommentsPage,
  FlagReason,
  FlagResult,
} from '../types';
import { apiFetch } from './client';

function mapComment(c: ApiComment): Comment {
  return {
    id: c.comment_id,
    parentId: c.parent_id ?? null,
    authorId: c.author_id,
    authorLabel: c.author_label,
    isBot: !!c.is_bot,
    body: c.body,
    status: c.status,
    createdAt: c.created_at,
    updatedAt: c.updated_at,
  };
}

/**
 * Map a comment announced over the SSE stream. The payload uses the same
 * snake_case shape as the comments endpoint, so the same mapper applies.
 */
export function mapStreamComment(c: ApiStreamComment): Comment {
  return mapComment(c);
}

export async function getComments(
  postId: string,
  cursor: string | null = null,
  limit = 20,
): Promise<CommentsPage> {
  const params = new URLSearchParams();
  params.set('limit', String(limit));
  if (cursor) params.set('cursor', cursor);
  const res = await apiFetch<ApiListResponse<ApiComment>>(
    `/community/discussion/posts/${encodeURIComponent(
      postId,
    )}/comments?${params.toString()}`,
  );
  return {
    comments: (res.items ?? []).map(mapComment),
    nextCursor: res.next_cursor ?? null,
  };
}

export async function createComment(
  postId: string,
  body: string,
  parentId?: string | null,
): Promise<Comment> {
  const c = await apiFetch<ApiComment>(
    `/community/discussion/posts/${encodeURIComponent(postId)}/comments`,
    {
      method: 'POST',
      body: JSON.stringify({
        body,
        ...(parentId ? { parent_id: parentId } : {}),
      }),
    },
  );
  return mapComment(c);
}

/** Edit a comment's body (author only). */
export async function updateComment(
  id: string,
  body: string,
): Promise<Comment> {
  const c = await apiFetch<ApiComment>(
    `/community/discussion/comments/${encodeURIComponent(id)}`,
    {
      method: 'PATCH',
      body: JSON.stringify({ body }),
    },
  );
  return mapComment(c);
}

/** Soft-remove a comment (author or moderator). */
export async function deleteComment(id: string): Promise<void> {
  await apiFetch<void>(
    `/community/discussion/comments/${encodeURIComponent(id)}`,
    { method: 'DELETE' },
  );
}

/** Flag a comment for moderator review. */
export async function flagComment(
  id: string,
  reason: FlagReason,
  details?: string,
): Promise<FlagResult> {
  const r = await apiFetch<ApiFlagResponse>(
    `/community/discussion/comments/${encodeURIComponent(id)}/flag`,
    {
      method: 'POST',
      body: JSON.stringify({
        reason,
        ...(details ? { details } : {}),
      }),
    },
  );
  return { flagId: r.flag_id, status: r.status };
}
