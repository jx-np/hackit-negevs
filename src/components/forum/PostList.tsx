import { useEffect, useRef } from 'react';
import { usePosts } from '../../hooks/usePosts';
import type { Post, SortKey } from '../../types';
import { PostCard } from './PostCard';

interface PostListProps {
  query: string;
  tagId: string | null;
  sort: SortKey;
  /**
   * Optional client-side predicate applied to each loaded post. Used by the
   * Verified Scam Database view to show only moderator-reviewed reports while
   * reusing the same cursor-paginated feed. When omitted, every post is shown.
   */
  filter?: (post: Post) => boolean;
  /** Heading shown above the records when a custom empty-state is desired. */
  emptyTitle?: string;
  /** Secondary line in the empty state. */
  emptyHint?: string;
}

function PostSkeleton() {
  return (
    <div className="mb-5 rounded-2xl border border-scam-line bg-scam-800 p-6 shadow-card">
      <div className="flex items-center gap-3">
        <div className="h-9 w-9 shrink-0 animate-pulse rounded-md bg-scam-750" />
        <div className="flex-1 space-y-2">
          <div className="h-3 w-32 animate-pulse rounded bg-scam-750" />
          <div className="h-3 w-24 animate-pulse rounded bg-scam-750" />
        </div>
      </div>
      <div className="mt-4 space-y-3">
        <div className="h-5 w-3/4 animate-pulse rounded bg-scam-750" />
        <div className="h-4 w-full animate-pulse rounded bg-scam-750" />
        <div className="h-4 w-5/6 animate-pulse rounded bg-scam-750" />
      </div>
    </div>
  );
}

export function PostList({
  query,
  tagId,
  sort,
  filter,
  emptyTitle,
  emptyHint,
}: PostListProps) {
  const {
    data,
    isLoading,
    isError,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = usePosts({ query, tagId, sort });

  const sentinelRef = useRef<HTMLDivElement | null>(null);

  // Load the next page when the sentinel scrolls into view.
  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
          fetchNextPage();
        }
      },
      { rootMargin: '200px' },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [fetchNextPage, hasNextPage, isFetchingNextPage]);

  // Single centered report feed (one card per row).
  const feedClass = 'flex flex-col';

  if (isLoading) {
    return (
      <div className={feedClass}>
        {Array.from({ length: 6 }).map((_, i) => (
          <PostSkeleton key={i} />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <div className="rounded-2xl border border-risk-high/40 bg-risk-high/10 p-6 text-center text-risk-high">
        <p className="sr-label text-risk-high">Error</p>
        <p className="mt-2 text-lg font-medium text-scam-text">
          Something went wrong loading records.
        </p>
        <p className="mt-1 text-sm text-scam-muted">
          {(error as Error).message}
        </p>
      </div>
    );
  }

  const loaded = data?.pages.flatMap((p) => p.posts) ?? [];
  const posts = filter ? loaded.filter(filter) : loaded;
  const total = filter ? posts.length : data?.pages[0]?.total ?? 0;

  if (posts.length === 0) {
    // While filtering client-side, an early page may contain no matches even
    // though later pages do. Keep the sentinel mounted so the observer can
    // continue paging instead of stopping at a premature empty state.
    const stillPaging = Boolean(filter) && hasNextPage;
    return (
      <div className="rounded-2xl border border-dashed border-scam-line bg-scam-800/50 p-12 text-center text-scam-muted">
        <p className="text-xl font-medium text-scam-text">
          {stillPaging ? 'Loading…' : emptyTitle ?? 'No records found'}
        </p>
        <p className="mt-1 text-base">
          {stillPaging
            ? 'Scanning reports for matches.'
            : emptyHint ?? 'Try a different search term or category.'}
        </p>
        <div ref={sentinelRef} className="h-10" />
      </div>
    );
  }

  return (
    <div>
      <p className="sr-label mb-4">
        {total} {total === 1 ? 'record' : 'records'}
      </p>

      <div className={feedClass}>
        {posts.map((post) => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>

      {/* Infinite-scroll sentinel + loading indicator */}
      <div ref={sentinelRef} className="h-10" />

      {isFetchingNextPage && (
        <div className="py-6 text-center text-sm text-scam-muted">
          Loading more…
        </div>
      )}

      {!hasNextPage && posts.length > 0 && (
        <div className="py-6 text-center text-sm text-scam-dim">
          End of records.
        </div>
      )}
    </div>
  );
}
