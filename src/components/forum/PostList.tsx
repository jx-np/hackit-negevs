import { useEffect, useRef } from 'react';
import { usePosts } from '../../hooks/usePosts';
import { PostCard } from './PostCard';

interface PostListProps {
  query: string;
  tagId: string | null;
}

function PostSkeleton() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
      <div className="mb-3 flex items-center gap-3">
        <div className="h-9 w-9 animate-pulse rounded-full bg-slate-200 dark:bg-slate-800" />
        <div className="space-y-1.5">
          <div className="h-3 w-24 animate-pulse rounded bg-slate-200 dark:bg-slate-800" />
          <div className="h-3 w-16 animate-pulse rounded bg-slate-200 dark:bg-slate-800" />
        </div>
      </div>
      <div className="mb-2 h-5 w-3/4 animate-pulse rounded bg-slate-200 dark:bg-slate-800" />
      <div className="mb-4 h-4 w-full animate-pulse rounded bg-slate-200 dark:bg-slate-800" />
      <div className="h-4 w-24 animate-pulse rounded bg-slate-200 dark:bg-slate-800" />
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
      <div className="grid gap-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <PostSkeleton key={i} />
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-center text-red-600 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-400">
        <p className="font-medium">Something went wrong loading posts.</p>
        <p className="mt-1 text-sm opacity-80">{(error as Error).message}</p>
      </div>
    );
  }

  const posts = data?.pages.flatMap((p) => p.posts) ?? [];
  const total = data?.pages[0]?.total ?? 0;

  if (posts.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-slate-300 p-12 text-center text-slate-500 dark:border-slate-700">
        <p className="text-lg font-medium">No posts found</p>
        <p className="mt-1 text-sm">Try a different search term or tag.</p>
      </div>
    );
  }

  return (
    <div>
      <p className="mb-4 text-sm text-slate-400">
        {total} {total === 1 ? 'post' : 'posts'}
      </p>

      <div className="grid gap-4">
        {posts.map((post) => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>

      {/* Infinite-scroll sentinel + loading indicator */}
      <div ref={sentinelRef} className="h-10" />

      {isFetchingNextPage && (
        <div className="py-6 text-center text-sm text-slate-400">
          Loading more…
        </div>
      )}

      {!hasNextPage && posts.length > 0 && (
        <div className="py-6 text-center text-sm text-slate-400">
          You've reached the end.
        </div>
      )}
    </div>
  );
}
