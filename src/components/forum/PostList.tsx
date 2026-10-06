import { useEffect, useRef } from 'react';
import { usePosts } from '../../hooks/usePosts';
import type { SortKey } from '../../types';
import { PostCard } from './PostCard';

interface PostListProps {
  query: string;
  tagId: string | null;
  sort: SortKey;
}

function PostSkeleton() {
  return (
    <div className="mb-5 break-inside-avoid ia-panel overflow-hidden">
      <div className="aspect-[16/10] w-full animate-pulse bg-ink-100 dark:bg-ink-800" />
      <div className="space-y-3 px-5 py-4">
        <div className="h-4 w-20 animate-pulse bg-ink-200 dark:bg-ink-800" />
        <div className="h-6 w-3/4 animate-pulse bg-ink-200 dark:bg-ink-800" />
        <div className="h-4 w-full animate-pulse bg-ink-200 dark:bg-ink-800" />
      </div>
    </div>
  );
}

export function PostList({ query, tagId, sort }: PostListProps) {
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

  // Media feed: masonry-style via CSS columns.
  const feedClass = 'columns-1 gap-5 sm:columns-2';

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
      <div className="border border-risk-500 bg-risk-50 p-6 text-center text-risk-700 dark:border-risk-500/50 dark:bg-risk-500/10 dark:text-risk-500">
        <p className="ia-label">Error</p>
        <p className="mt-2 text-lg font-medium">
          Something went wrong loading records.
        </p>
        <p className="mt-1 text-sm opacity-80">
          {(error as Error).message}
        </p>
      </div>
    );
  }

  const posts = data?.pages.flatMap((p) => p.posts) ?? [];
  const total = data?.pages[0]?.total ?? 0;

  if (posts.length === 0) {
    return (
      <div className="border border-dashed border-ink-300 p-12 text-center text-ink-500 dark:border-ink-700">
        <p className="font-display text-xl font-medium text-ink-800 dark:text-ink-200">
          No records found
        </p>
        <p className="mt-1 text-base">Try a different search term or tag.</p>
      </div>
    );
  }

  return (
    <div>
      <p className="ia-label mb-4 text-ink-400">
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
        <div className="py-6 text-center text-sm text-ink-400">
          Loading more…
        </div>
      )}

      {!hasNextPage && posts.length > 0 && (
        <div className="py-6 text-center text-sm text-ink-400">
          End of records.
        </div>
      )}
    </div>
  );
}
