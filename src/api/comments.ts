/**
 * Discussion (comments) API.
 */
import type {
  ApiComment,
  ApiListResponse,
  Comment,
  CommentsPage,
} from '../types';
import { apiFetch } from './client';

function mapComment(c: ApiComment): Comment {
  return {
    id: c.comment_id,
    parentId: c.parent_id ?? null,
    authorId: c.author_id,
    authorLabel: c.author_label,
    body: c.body,
    status: c.status,
    createdAt: c.created_at,
    updatedAt: c.updated_at,
  };
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
