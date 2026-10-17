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
  /** Down-vote count (detail only; 0 on feed items). */
  downCount?: number;
  /** The caller's current vote: 1 (up), -1 (down), or 0 (none/anonymous). */
  myVote?: number;
  /** Absolute URLs of the post's redacted screenshots, in display order. */
  imageUrls?: string[];
  risk?: RiskLevel;
  incidentDate?: string | null;
  /** Backend moderation label, surfaced in the UI. */
  reviewStatus?: ReviewStatus;
  /** True when the authenticated caller owns this post (can edit/delete). */
  isMine?: boolean;
}

/** Result of setting or clearing a reaction on a post. */
export interface ReactionResult {
  upCount: number;
  downCount: number;
  myVote: number;
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
  /** Additional tag slugs. */
  tags?: string[];
  /**
   * Ids of the caller's own uploads to attach as the post's images, in
   * display order (backend `upload_ids`). Each must have finished redaction.
   */
  uploadIds?: string[];
  risk?: RiskLevel;
  authorName: string;
  authorId: string;
  incidentDate?: string | null;
}

/** Progress of an upload's background OCR + redaction job. */
export type UploadStatus = 'processing' | 'ready' | 'failed';

/**
 * Result of `POST /uploads`. Uploading schedules the screenshot check
 * automatically, so the upload is only publishable once it reaches `ready`
 * (redaction produces the image that is actually attached).
 */
export interface UploadedMedia {
  uploadId: string;
  /** The image's media type, e.g. "image/png". */
  mediaType: string;
  /** Local file name, kept for display only. */
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
// Flagging (reporting content)
// ---------------------------------------------------------------------------

/** Backend-recognised reasons for flagging a post or comment. */
export type FlagReason =
  | 'personal_information'
  | 'harmful'
  | 'spam'
  | 'misinformation'
  | 'other';

/** Result of flagging a post or comment. */
export interface FlagResult {
  flagId: string;
  status: string;
}

// ---------------------------------------------------------------------------
// Guidance & resources ("Get help now")
// ---------------------------------------------------------------------------

export type GuidanceUrgency = 'normal' | 'urgent' | 'emergency';

export interface GuidanceItem {
  id: string;
  scenario: string;
  urgency: GuidanceUrgency;
  title: string;
  body: string;
  /** Related resource slugs/ids referenced by this guidance step. */
  resources: string[];
}

export interface Resource {
  id: string;
  slug: string;
  countryCode: string;
  url: string;
  contactInstructions?: string;
  name: string;
  description?: string;
  verifiedAt: string;
  ownerName: string;
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
  /**
   * Free-form classification label assigned by the backend. Empty until the
   * classification system applies one, so render it only when non-empty.
   */
  classification: string;
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
  reactions?: { up: number; down: number };
  my_vote?: number;
  is_mine?: boolean;
  /**
   * Not currently returned by the feed, but part of the post shape — mapped
   * through so feed cards render screenshots if the backend adds them.
   */
  redacted_image_urls?: string[];
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
  is_mine?: boolean;
  /** Relative API paths for the post's redacted images; omitted when none. */
  redacted_image_urls?: string[];
}

/** Response body from PUT/DELETE /community/posts/{id}/reaction. */
export interface ApiReactionResponse {
  up_count: number;
  down_count: number;
  my_vote: number;
}

export interface ApiListResponse<T> {
  items: T[];
  next_cursor?: string | null;
}

/** Response body from POST .../flag. */
export interface ApiFlagResponse {
  flag_id: string;
  status: string;
}

export interface ApiGuidanceItem {
  id: string;
  scenario: string;
  urgency: GuidanceUrgency;
  title: string;
  body: string;
  resources?: string[];
}

export interface ApiResource {
  id: string;
  slug: string;
  country_code: string;
  url: string;
  contact_instructions?: string;
  name: string;
  description?: string;
  verified_at: string;
  owner_name: string;
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
  /** Free-form classification label; "" when no active classification applies. */
  classification?: string;
}

/** Response body from POST /uploads. */
export interface ApiUploadResponse {
  upload_id: string;
  media_type: string;
  status: string;
}

/** Response body from GET /uploads/{id} (upload progress). */
export interface ApiUpload {
  upload_id: string;
  media_type: string;
  status: UploadStatus;
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
