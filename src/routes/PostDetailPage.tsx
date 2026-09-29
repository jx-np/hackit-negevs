import { motion } from 'framer-motion';
import { ArrowLeft, CalendarDays, Heart, MessageCircle } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { CommentBox } from '../components/forum/CommentBox';
import { usePost } from '../hooks/usePost';
import type { Post } from '../types';

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

function initials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

function RiskBadge({ risk }: { risk: Post['risk'] }) {
  if (!risk) return null;
  const cls =
    risk === 'high'
      ? 'bg-risk-600 text-white'
      : 'bg-caution-500 text-ink-900';
  return (
    <span className={`ia-label px-2.5 py-1 ${cls}`}>
      {risk === 'high' ? 'High risk' : 'Caution'}
    </span>
  );
}

export function PostDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: post, isLoading, isError, error } = usePost(id);

  return (
    <div className="min-h-screen bg-paper dark:bg-ink-950">
      <div className="mx-auto w-full max-w-6xl px-6 py-10">
        <Link
          to="/forum"
          className="mb-6 inline-flex items-center gap-2 font-mono text-sm uppercase tracking-wider text-ink-500 transition hover:text-safe-700 dark:text-ink-400 dark:hover:text-safe-400"
        >
          <ArrowLeft size={16} /> Back to forum
        </Link>

        {isLoading && (
          <div className="ia-panel overflow-hidden">
            <div className="aspect-[16/9] w-full animate-pulse bg-ink-100 dark:bg-ink-800" />
            <div className="space-y-3 p-6">
              <div className="h-8 w-3/4 animate-pulse bg-ink-200 dark:bg-ink-800" />
              <div className="h-4 w-full animate-pulse bg-ink-200 dark:bg-ink-800" />
              <div className="h-4 w-2/3 animate-pulse bg-ink-200 dark:bg-ink-800" />
            </div>
          </div>
        )}

        {isError && (
          <div className="border border-risk-500 bg-risk-50 p-6 text-center text-risk-700 dark:border-risk-500/50 dark:bg-risk-500/10 dark:text-risk-500">
            <p className="ia-label">Not found</p>
            <p className="mt-2 text-lg font-medium">
              {(error as Error)?.message ?? 'This report could not be loaded.'}
            </p>
            <Link
              to="/forum"
              className="mt-4 inline-block font-mono text-sm underline"
            >
              Return to the forum
            </Link>
          </div>
        )}

        {post && (
          <div className="grid gap-6 lg:grid-cols-[minmax(0,1.5fr)_minmax(0,1fr)] lg:items-start">
          <motion.article
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.35, ease: 'easeOut' }}
            className="ia-panel overflow-hidden"
          >
            {post.imageUrl && (
              <div className="relative">
                <img
                  src={post.imageUrl}
                  alt=""
                  className="block max-h-96 w-full bg-ink-100 object-cover dark:bg-ink-800"
                />
                {post.risk && (
                  <span className="absolute left-3 top-3">
                    <RiskBadge risk={post.risk} />
                  </span>
                )}
              </div>
            )}

            <div className="p-6">
              {/* Tags + risk (inline when no image) */}
              <div className="mb-4 flex flex-wrap items-center gap-2">
                {post.tags.map((tag) => (
                  <span
                    key={tag.id}
                    className="border border-ink-200 px-2.5 py-1 font-mono text-xs font-medium uppercase tracking-wider text-ink-600 dark:border-ink-700 dark:text-ink-300"
                  >
                    #{tag.name}
                  </span>
                ))}
                {!post.imageUrl && post.risk && <RiskBadge risk={post.risk} />}
              </div>

              <h1 className="font-display text-3xl font-bold leading-tight text-ink-900 dark:text-white sm:text-4xl">
                {post.title}
              </h1>

              {/* Author row */}
              <div className="mt-5 flex items-center gap-3 border-b border-ink-200 pb-5 dark:border-ink-800">
                <span className="grid h-11 w-11 place-items-center border border-ink-300 bg-ink-50 font-mono text-sm font-semibold text-ink-700 dark:border-ink-700 dark:bg-ink-800 dark:text-ink-200">
                  {initials(post.author.name)}
                </span>
                <div>
                  <p className="font-medium text-ink-900 dark:text-white">
                    {post.author.name}
                  </p>
                  <p className="font-mono text-xs text-ink-400">
                    {formatDate(post.createdAt)}
                  </p>
                </div>
                <div className="ml-auto flex items-center gap-4 font-mono text-sm text-ink-400">
                  <span className="flex items-center gap-1.5">
                    <MessageCircle size={16} /> {post.replyCount}
                  </span>
                  <span className="flex items-center gap-1.5">
                    <Heart size={16} /> {post.likeCount}
                  </span>
                </div>
              </div>

              {/* Incident date */}
              {post.incidentDate && (
                <div className="mt-5 flex items-center gap-2 border border-ink-200 bg-ink-50 px-4 py-3 dark:border-ink-800 dark:bg-ink-900/50">
                  <CalendarDays size={18} className="text-safe-600 dark:text-safe-400" />
                  <span className="ia-label text-ink-500 dark:text-ink-400">
                    Incident date
                  </span>
                  <span className="ml-auto font-mono text-sm text-ink-900 dark:text-white">
                    {formatDate(post.incidentDate)}
                  </span>
                </div>
              )}

              {/* Body */}
              <div className="mt-5 space-y-4 text-lg leading-relaxed text-ink-700 dark:text-ink-300">
                <p>{post.excerpt}</p>
                {post.body && <p>{post.body}</p>}
              </div>
            </div>
          </motion.article>

          {/* Comment thread — side column on large screens */}
          <motion.aside
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.35, ease: 'easeOut', delay: 0.05 }}
            className="ia-panel p-6 lg:sticky lg:top-24"
          >
            <h2 className="ia-label mb-4 border-b border-ink-200 pb-4 text-ink-500 dark:border-ink-800 dark:text-ink-400">
              Discussion · {post.replyCount} comments
            </h2>
            <CommentBox postId={post.id} />
          </motion.aside>
          </div>
        )}
      </div>
    </div>
  );
}
