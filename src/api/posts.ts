/**
 * Posts / feed API.
 *
 * Maps the backend's community feed + post shapes onto the UI `Post` type.
 * The backend has no author / risk / incident-date / image fields on posts,
 * so those are derived or left empty:
 *   - author        → a neutral label derived from review_status
 *   - risk          → null (not modelled server-side)
 *   - incidentDate  → null
 *   - imageUrl      → null
 *   - replyCount    → comment_count
 *   - likeCount     → reactions.up (detail only; 0 on feed items)
 */
import type {
  ApiCategory,
  ApiFeedItem,
  ApiListResponse,
  ApiPostDetail,
  NewPostInput,
  Post,
  PostsPage,
  PostsQuery,
  ReviewStatus,
  Tag,
} from '../types';
import { apiFetch } from './client';

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
    likeCount: 0,
    imageUrl: null,
    risk: null,
    incidentDate: null,
    reviewStatus: item.review_status,
  };
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
    imageUrl: null,
    risk: null,
    incidentDate: null,
    reviewStatus: p.review_status,
  };
}

export async function getPost(id: string): Promise<Post> {
  const p = await apiFetch<ApiPostDetail>(
    `/community/posts/${encodeURIComponent(id)}`,
  );
  return mapPostDetail(p);
}

export async function getPosts({
  query = '',
  tagId = null,
  cursor = null,
  limit = DEFAULT_LIMIT,
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
  const posts = (res.items ?? []).map(mapFeedItem);
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

  // Backend posts require explicit publication confirmation and use slugs for
  // scam_type / tags. The `tagId` field carries the chosen category slug.
  const extraTags = (input.tags ?? []).filter((t) => t && t !== input.tagId);

  const body = {
    title: input.title,
    redacted_text: input.excerpt,
    scam_type: input.tagId,
    tags: extraTags,
    confirm_publication: true,
    locale: 'en-SG',
  };

  const p = await apiFetch<ApiPostDetail>('/community/posts', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return mapPostDetail(p);
}
