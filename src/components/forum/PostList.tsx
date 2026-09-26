import { useEffect, useRef } from 'react';
import { usePosts } from '../../hooks/usePosts';
import { PostCard } from './PostCard';

interface PostListProps {
  query: string;
  tagId: string | null;
}

function PostSkeleton() {
  return (
    <div className="ia-panel">
      <div className="flex items-center gap-3 border-b border-ink-200 px-6 py-3 dark:border-ink-800">
        <div className="h-9 w-9 animate-pulse bg-ink-200 dark:bg-ink-800" />
        <div className="space-y-1.5">
          <div className="h-3 w-24 animate-pulse bg-ink-200 dark:bg-ink-800" />
          <div className="h-3 w-16 animate-pulse bg-ink-200 dark:bg-ink-800" />
        </div>
      </div>
      <div className="space-y-3 px-6 py-5">
        <div className="h-6 w-3/4 animate-pulse bg-ink-200 dark:bg-ink-800" />
        <div className="h-4 w-full animate-pulse bg-ink-200 dark:bg-ink-800" />
      </div>
    </div>
  );
}

export function PostList({ query, tagId }: PostListProps) {
  const {
    data,
    isLoading,
    isError,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = usePosts({ query, tagId });

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

  if (isLoading) {
    return (
      <div className="mx-auto grid max-w-4xl gap-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <PostSkeleton key={i} />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <div className="mx-auto max-w-4xl border border-risk-500 bg-risk-50 p-6 text-center text-risk-700 dark:border-risk-500/50 dark:bg-risk-500/10 dark:text-risk-500">
        <p className="ia-label">Error</p>
        <p className="mt-2 text-lg font-medium">Something went wrong loading records.</p>
        <p className="mt-1 font-mono text-sm opacity-80">{(error as Error).message}</p>
      </div>
    );
  }

  const posts = data?.pages.flatMap((p) => p.posts) ?? [];
  const total = data?.pages[0]?.total ?? 0;

  if (posts.length === 0) {
    return (
      <div className="mx-auto max-w-4xl border border-dashed border-ink-300 p-12 text-center text-ink-500 dark:border-ink-700">
        <p className="font-display text-xl font-medium text-ink-800 dark:text-ink-200">
          No records found
        </p>
        <p className="mt-1 text-base">Try a different search term or tag.</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl">
      <p className="ia-label mb-4 text-ink-400">
        {total} {total === 1 ? 'record' : 'records'}
      </p>

      <div className="grid gap-4">
        {posts.map((post) => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>

      {/* Infinite-scroll sentinel + loading indicator */}
      <div ref={sentinelRef} className="h-10" />

      {isFetchingNextPage && (
        <div className="py-6 text-center font-mono text-sm text-ink-400">
          Loading more…
        </div>
      )}

      {!hasNextPage && posts.length > 0 && (
        <div className="py-6 text-center font-mono text-sm text-ink-400">
          End of records.
        </div>
      )}
    </div>
  );
}
