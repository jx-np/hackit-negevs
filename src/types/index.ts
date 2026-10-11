/**
 * Shared types.
 *
 * The UI-facing types (Post, Tag, Author, NumberCheckResult, ...) are kept
 * stable so the components don't need to change. The api/* layer maps the
 * backend's snake_case wire shapes (see `Api*` types below) onto these.
 */

// ---------------------------------------------------------------------------
// UI-facing types (consumed by components / hooks)
// ---------------------------------------------------------------------------

export interface Tag {
  /** Backend tag slug (e.g. "bank-impersonation"). */
  id: string;
  /** Human-readable label resolved from the i18n name_key. */
  name: string;
  count?: number;
}

export interface Author {
  id: string;
  name: string;
  avatarUrl?: string;
}

export type RiskLevel = 'high' | 'medium' | null;

export interface Post {
  id: string;
  title: string;
  excerpt: string;
  body?: string;
  author: Author;
  tags: Tag[];
  createdAt: string;
  replyCount: number;
  likeCount: number;
  imageUrl?: string | null;
  risk?: RiskLevel;
  incidentDate?: string | null;
  /** Backend moderation label, surfaced in the UI. */
  reviewStatus?: ReviewStatus;
}

export type ReviewStatus =
  | 'unverified'
  | 'reviewed'
  | 'disputed'
  | 'hidden'
  | 'removed';

export type SortKey = 'new' | 'comments' | 'likes';

export interface NewPostInput {
  title: string;
  /** Maps to the backend's redacted_text. */
  excerpt: string;
  body?: string;
  /** Category slug (backend scam_type). */
  tagId: string;
  /** Additional tag slugs. */
  tags?: string[];
  imageUrl?: string | null;
  risk?: RiskLevel;
  authorName: string;
  authorId: string;
  incidentDate?: string | null;
}

export interface UploadedMedia {
  url: string;
  name: string;
}

/**
 * A page of posts. `nextCursor` is the opaque cursor string from the backend
 * (null when there are no more pages). `total` is best-effort (the backend
 * does not return a count, so it reflects what has loaded so far).
 */
export interface PostsPage {
  posts: Post[];
  nextCursor: string | null;
  total: number;
}

export interface PostsQuery {
  query?: string;
  tagId?: string | null;
  cursor?: string | null;
  limit?: number;
  sort?: SortKey;
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

export interface Comment {
  id: string;
  parentId: string | null;
  authorId: string;
  authorLabel: string;
  body: string;
  status: 'visible' | 'hidden' | 'removed';
  createdAt: string;
  updatedAt: string;
}

export interface CommentsPage {
  comments: Comment[];
  nextCursor: string | null;
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

export type UserRole = 'resident' | 'helper' | 'moderator' | 'admin';

export interface User {
  id: string;
  email: string;
  /** UI display name (maps to backend display_name). */
  name: string;
  role?: UserRole;
  locale?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  /** Access-token lifetime in seconds. */
  expiresIn: number;
}

// ---------------------------------------------------------------------------
// Phone number trust score
// ---------------------------------------------------------------------------

export type NumberStatus = 'trusted' | 'scam' | 'unknown';

export interface NumberReportCounts {
  scam: number;
  trusted: number;
  total: number;
}

export interface NumberCheckResult {
  number: string;
  status: NumberStatus;
  /** 0 (risky) – 100 (trusted). */
  trustScore: number;
  rating: 'high_risk' | 'unknown' | 'trusted';
  reportCount: number;
  known: boolean;
}

// ---------------------------------------------------------------------------
// Backend wire shapes (snake_case) — used only inside api/*
// ---------------------------------------------------------------------------

export interface ApiTaxonomyItem {
  slug: string;
  name_key: string;
  description_key?: string;
}

export interface ApiCategory {
  slug: string;
  name_key: string;
}

export interface ApiFeedItem {
  post_id: string;
  title: string;
  redacted_excerpt: string;
  category: ApiCategory | null;
  tags: ApiCategory[];
  review_status: ReviewStatus;
  created_at: string;
  comment_count: number;
}

export interface ApiPostDetail {
  post_id: string;
  title: string;
  redacted_text: string;
  category: ApiCategory | null;
  tags: ApiCategory[];
  review_status: ReviewStatus;
  created_at: string;
  updated_at: string;
  comment_count: number;
  reactions: { up: number; down: number };
  my_vote: number;
}

export interface ApiListResponse<T> {
  items: T[];
  next_cursor?: string | null;
}

export interface ApiComment {
  comment_id: string;
  parent_id?: string | null;
  author_id: string;
  author_label: string;
  body: string;
  status: 'visible' | 'hidden' | 'removed';
  created_at: string;
  updated_at: string;
}

export interface ApiUser {
  id: string;
  email: string;
  display_name: string;
  role: UserRole;
  locale: string;
  created_at?: string;
}

export interface ApiAuthResponse {
  user: ApiUser;
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

export interface ApiRefreshResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

export interface ApiTrustScore {
  phone_number: string;
  trust_score: number;
  rating: 'high_risk' | 'unknown' | 'trusted';
  report_count: number;
  known: boolean;
}

/** Standard backend error body. */
export interface ApiErrorBody {
  error: {
    code: string;
    message: string;
    fields?: Record<string, string>;
  };
  request_id?: string;
}
