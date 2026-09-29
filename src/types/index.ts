export interface Tag {
  id: string;
  name: string;
  /** Number of posts using this tag (optional, for display). */
  count?: number;
}

export interface Author {
  id: string;
  name: string;
  avatarUrl?: string;
}

/** Risk level a report has been assigned (semantic to ScamReg). */
export type RiskLevel = 'high' | 'medium' | null;

export interface Post {
  id: string;
  title: string;
  excerpt: string;
  body?: string;
  author: Author;
  tags: Tag[];
  createdAt: string; // ISO date (when the report was posted)
  replyCount: number;
  likeCount: number;
  /** Optional screenshot/evidence image for the report. */
  imageUrl?: string | null;
  /** Optional risk classification, shown as a badge. */
  risk?: RiskLevel;
  /** When the scam actually happened (YYYY-MM-DD), if provided. */
  incidentDate?: string | null;
}

/** How the posts list is ordered. */
export type SortKey = 'new' | 'comments' | 'likes';

/** Payload for creating a new report (post). */
export interface NewPostInput {
  title: string;
  excerpt: string;
  body?: string;
  tagId: string;
  imageUrl?: string | null;
  risk?: RiskLevel;
  authorName: string;
  /** When the scam happened (YYYY-MM-DD). */
  incidentDate?: string | null;
}

/** Result of uploading a media file. */
export interface UploadedMedia {
  url: string;
  /** Original file name, for display. */
  name: string;
}

/** Shape returned by a paginated posts request. */
export interface PostsPage {
  posts: Post[];
  /** Cursor/page for the next page, or null when there are no more. */
  nextPage: number | null;
  total: number;
}

export interface PostsQuery {
  query?: string;
  tagId?: string | null;
  page?: number;
  pageSize?: number;
  sort?: SortKey;
}

export interface User {
  id: string;
  email: string;
  name: string;
}

/** Community verdict for a looked-up phone number. */
export type NumberStatus = 'trusted' | 'scam' | 'unknown';

/** Breakdown of how the community has classified a number. */
export interface NumberReportCounts {
  scam: number;
  trusted: number;
  /** total = scam + trusted (+ any other categories) */
  total: number;
}

/** Result of looking up a phone number in the registry. */
export interface NumberCheckResult {
  /** Normalized number that was looked up. */
  number: string;
  status: NumberStatus;
  counts: NumberReportCounts;
  /** ISO date of the most recent report, or null if never reported. */
  lastReportedAt: string | null;
}

/** A report a user files against a number. */
export type NumberReportKind = 'scam' | 'trusted';
