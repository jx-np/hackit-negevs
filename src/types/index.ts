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
  createdAt: string; // ISO date
  replyCount: number;
  likeCount: number;
  /** Optional screenshot/evidence image for the report. */
  imageUrl?: string | null;
  /** Optional risk classification, shown as a badge. */
  risk?: RiskLevel;
}

/** How the posts list is ordered. */
export type SortKey = 'new' | 'comments' | 'likes';

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
