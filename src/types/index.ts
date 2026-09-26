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
}

export interface User {
  id: string;
  email: string;
  name: string;
}
