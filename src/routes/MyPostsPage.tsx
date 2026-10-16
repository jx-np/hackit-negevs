import { motion } from 'framer-motion';
import { FileText } from 'lucide-react';
import { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { PostCard } from '../components/forum/PostCard';
import { useAuth } from '../context/AuthContext';
import { useMyPosts } from '../hooks/useMyPosts';

export function MyPostsPage() {
  const { isLoggedIn, isLoading: authLoading } = useAuth();
  const {
    data,
    isLoading,
    isError,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useMyPosts();

  const sentinelRef = useRef<HTMLDivElement | null>(null);

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

  const posts = data?.pages.flatMap((p) => p.posts) ?? [];
  const total = data?.pages[0]?.total ?? 0;

  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
    >
      <div className="mx-auto w-full max-w-3xl px-5 py-8 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-6 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <FileText size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Your activity</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              My posts
            </h1>
          </div>
        </motion.div>

        {!authLoading && !isLoggedIn ? (
          <div className="rounded-lg border border-dashed border-scam-line p-12 text-center text-scam-muted">
            <p className="text-xl font-medium text-scam-text">
              Sign in to see your posts
            </p>
            <p className="mt-1 text-base">
              Your submitted scam reports will appear here once you{"\u2019"}re
              signed in.
            </p>
            <Link
              to="/auth"
              className="sr-btn-primary mt-5 inline-block px-5 py-2"
            >
              Sign in
            </Link>
          </div>
        ) : isLoading || authLoading ? (
          <div className="py-12 text-center text-sm text-scam-muted">
            Loading your posts…
          </div>
        ) : isError ? (
          <div className="rounded-lg border border-risk-high/40 bg-risk-high/10 p-6 text-center text-risk-high">
            <p className="sr-label text-risk-high">Error</p>
            <p className="mt-2 text-lg font-medium text-scam-text">
              Could not load your posts.
            </p>
            <p className="mt-1 text-sm text-scam-muted">
              {(error as Error).message}
            </p>
          </div>
        ) : posts.length === 0 ? (
          <div className="rounded-lg border border-dashed border-scam-line p-12 text-center text-scam-muted">
            <p className="text-xl font-medium text-scam-text">No posts yet</p>
            <p className="mt-1 text-base">
              Report a scam to help protect the community.
            </p>
            <Link
              to="/report"
              className="sr-btn-primary mt-5 inline-block px-5 py-2"
            >
              Report a scam
            </Link>
          </div>
        ) : (
          <>
            <p className="sr-label mb-4">
              {total} {total === 1 ? 'post' : 'posts'}
            </p>
            <div className="flex flex-col">
              {posts.map((post) => (
                <PostCard key={post.id} post={post} />
              ))}
            </div>
            <div ref={sentinelRef} className="h-10" />
            {isFetchingNextPage && (
              <div className="py-6 text-center text-sm text-scam-muted">
                Loading more…
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
