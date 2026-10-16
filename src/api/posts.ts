/**
 * Posts / feed API.
 *
 * Maps the backend's community feed + post shapes onto the UI `Post` type.
 * The backend has no author / risk / incident-date fields on posts, so those
 * are derived or left empty:
 *   - author        → a neutral label derived from review_status
 *   - risk          → null (not modelled server-side)
 *   - incidentDate  → null
 *   - imageUrls     → redacted_image_urls (detail only; the feed omits them)
 *   - replyCount    → comment_count
 *   - likeCount     → reactions.up (feed + detail)
 */
import type {
  ApiCategory,
  ApiFeedItem,
  ApiFlagResponse,
  ApiListResponse,
  ApiPostDetail,
  ApiReactionResponse,
  FlagReason,
  FlagResult,
  NewPostInput,
  Post,
  PostsPage,
  PostsQuery,
  ReactionResult,
  ReviewStatus,
  SortKey,
  Tag,
} from '../types';
import { apiAssetUrl, apiFetch } from './client';

const DEFAULT_LIMIT = 12;

/** Humanize an i18n name_key, e.g. "tag.bank_impersonation" → "Bank Impersonation". */
function humanizeKey(key: string, slug: string): string {
  const tail = key.includes('.') ? key.slice(key.indexOf('.') + 1) : key;
  const base = tail || slug;
  return base
    .replace(/^(category|tag)\./, '')
    .replace(/[._-]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())
    .trim();
}

function mapTag(c: ApiCategory): Tag {
  return { id: c.slug, name: humanizeKey(c.name_key, c.slug) };
}

/** A neutral author label derived from moderation status. */
function authorFor(reviewStatus: ReviewStatus): { id: string; name: string } {
  if (reviewStatus === 'reviewed') {
    return { id: 'official', name: 'Verified report' };
  }
  return { id: 'community', name: 'Community member' };
}

function mapFeedItem(item: ApiFeedItem): Post {
  const tags = (item.tags ?? []).map(mapTag);
  if (item.category) tags.unshift(mapTag(item.category));
  return {
    id: item.post_id,
    title: item.title,
    excerpt: item.redacted_excerpt,
    author: authorFor(item.review_status),
    tags,
    createdAt: item.created_at,
    replyCount: item.comment_count,
    likeCount: item.reactions?.up ?? 0,
    downCount: item.reactions?.down ?? 0,
    myVote: item.my_vote ?? 0,
    // The feed does not currently return images; map the field through so the
    // card renders them automatically if the backend starts sending them.
    imageUrls: (item.redacted_image_urls ?? []).map(apiAssetUrl),
    risk: null,
    incidentDate: null,
    reviewStatus: item.review_status,
    isMine: item.is_mine ?? false,
  };
}

/**
 * Resolve the backend's `redacted_image_urls` into loadable URLs. The paths are
 * absolute API paths (`/api/v1/community/posts/12/images/0`), so they are
 * passed through `apiAssetUrl` to work in both dev (proxied) and production.
 */
function mapImageUrls(p: ApiPostDetail): string[] {
  return (p.redacted_image_urls ?? []).map(apiAssetUrl);
}

function mapPostDetail(p: ApiPostDetail): Post {
  const tags = (p.tags ?? []).map(mapTag);
  if (p.category) tags.unshift(mapTag(p.category));
  return {
    id: p.post_id,
    title: p.title,
    excerpt: p.redacted_text,
    body: undefined,
    author: authorFor(p.review_status),
    tags,
    createdAt: p.created_at,
    replyCount: p.comment_count,
    likeCount: p.reactions?.up ?? 0,
    downCount: p.reactions?.down ?? 0,
    myVote: p.my_vote ?? 0,
    imageUrls: mapImageUrls(p),
    risk: null,
    incidentDate: null,
    reviewStatus: p.review_status,
    isMine: p.is_mine ?? false,
  };
}

export async function getPost(id: string): Promise<Post> {
  const p = await apiFetch<ApiPostDetail>(
    `/community/posts/${encodeURIComponent(id)}`,
  );
  return mapPostDetail(p);
}

/**
 * Order a page of posts by the selected sort key. The backend feed only
 * guarantees recency ordering, so "comments" and "likes" are applied here
 * using the fields already present on each mapped post. Sorting is stable
 * within a page and falls back to recency for ties.
 */
function sortPosts(posts: Post[], sort: SortKey): Post[] {
  if (sort === 'new') return posts;
  const byNewest = (a: Post, b: Post) =>
    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  return [...posts].sort((a, b) => {
    if (sort === 'comments') {
      return b.replyCount - a.replyCount || byNewest(a, b);
    }
    // sort === 'likes'
    return b.likeCount - a.likeCount || byNewest(a, b);
  });
}

export async function getPosts({
  query = '',
  tagId = null,
  cursor = null,
  limit = DEFAULT_LIMIT,
  sort = 'new',
}: PostsQuery): Promise<PostsPage> {
  const params = new URLSearchParams();
  params.set('limit', String(limit));
  if (cursor) params.set('cursor', cursor);

  const q = query.trim();
  let path: string;
  if (q) {
    // Full-text search endpoint.
    params.set('q', q);
    if (tagId) params.set('scam_type', tagId);
    path = `/community/feed/search?${params.toString()}`;
  } else {
    // Standard feed. Filter by category (scam_type) when a tag is selected.
    if (tagId) {
      params.set('scam_type', tagId);
    }
    path = `/community/feed?${params.toString()}`;
  }

  const res = await apiFetch<ApiListResponse<ApiFeedItem>>(path);
  const posts = sortPosts((res.items ?? []).map(mapFeedItem), sort);
  return {
    posts,
    nextCursor: res.next_cursor ?? null,
    total: posts.length,
  };
}

export async function createPost(input: NewPostInput): Promise<Post> {
  if (!input.authorId) {
    return Promise.reject(new Error('You must be logged in to report.'));
  }

  // The backend infers the scam category server-side and rejects a
  // client-supplied `scam_type` on create, so the category is not sent. `tags`
  // must be known tag slugs; any provided are passed through, filtering out
  // empties.
  const extraTags = (input.tags ?? []).filter((t) => !!t);
  const uploadIds = input.uploadIds ?? [];

  const body = {
    title: input.title,
    redacted_text: input.excerpt,
    confirm_publication: true,
    locale: 'en-SG',
    // The backend copies each upload's redacted image onto the post, in order.
    ...(uploadIds.length > 0 ? { upload_ids: uploadIds } : {}),
  };

  const p = await apiFetch<ApiPostDetail>('/community/posts', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return mapPostDetail(p);
}

function mapReaction(r: ApiReactionResponse): ReactionResult {
  return {
    upCount: r.up_count ?? 0,
    downCount: r.down_count ?? 0,
    myVote: r.my_vote ?? 0,
  };
}

/**
 * Set or change the caller's vote on a post.
 * `vote` must be `1` (up) or `-1` (down).
 */
export async function setReaction(
  id: string,
  vote: 1 | -1,
): Promise<ReactionResult> {
  const r = await apiFetch<ApiReactionResponse>(
    `/community/posts/${encodeURIComponent(id)}/reaction`,
    {
      method: 'PUT',
      body: JSON.stringify({ vote }),
    },
  );
  return mapReaction(r);
}

/** Clear the caller's vote on a post. */
export async function clearReaction(id: string): Promise<ReactionResult> {
  const r = await apiFetch<ApiReactionResponse>(
    `/community/posts/${encodeURIComponent(id)}/reaction`,
    { method: 'DELETE' },
  );
  return mapReaction(r);
}

/** Fields that can be edited on a post. */
export interface PostPatch {
  title?: string;
  /** Maps to the backend's redacted_text. Editing resets review to unverified. */
  excerpt?: string;
  /** Additional tag slugs. */
  tags?: string[];
}

/**
 * Edit a post (author/moderator only). Editing `redacted_text` resets the
 * backend review_status to `unverified`.
 */
export async function updatePost(id: string, patch: PostPatch): Promise<Post> {
  const body: Record<string, unknown> = {};
  if (patch.title !== undefined) body.title = patch.title;
  if (patch.excerpt !== undefined) body.redacted_text = patch.excerpt;
  if (patch.tags !== undefined) body.tags = patch.tags;

  const p = await apiFetch<ApiPostDetail>(
    `/community/posts/${encodeURIComponent(id)}`,
    {
      method: 'PATCH',
      body: JSON.stringify(body),
    },
  );
  return mapPostDetail(p);
}

/** Soft-delete a post (author/moderator only). */
export async function deletePost(id: string): Promise<void> {
  await apiFetch<void>(`/community/posts/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

/** Flag a post for moderator review. */
export async function flagPost(
  id: string,
  reason: FlagReason,
  details?: string,
): Promise<FlagResult> {
  const r = await apiFetch<ApiFlagResponse>(
    `/community/posts/${encodeURIComponent(id)}/flag`,
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

/** The caller's own posts ("my posts" history). */
export async function getMyPosts(
  cursor: string | null = null,
  limit = DEFAULT_LIMIT,
): Promise<PostsPage> {
  const params = new URLSearchParams();
  params.set('limit', String(limit));
  if (cursor) params.set('cursor', cursor);

  const res = await apiFetch<ApiListResponse<ApiFeedItem>>(
    `/me/posts?${params.toString()}`,
  );
  const posts = (res.items ?? []).map(mapFeedItem);
  return {
    posts,
    nextCursor: res.next_cursor ?? null,
    total: posts.length,
  };
}
