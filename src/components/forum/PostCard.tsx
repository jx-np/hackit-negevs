import { AnimatePresence, motion } from 'framer-motion';
import { Heart, MessageCircle } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import type { Post } from '../../types';
import { CommentBox } from './CommentBox';

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
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
  const styles =
    risk === 'high'
      ? 'bg-risk-600 text-white'
      : 'bg-caution-500 text-ink-900';
  const label = risk === 'high' ? 'High risk' : 'Caution';
  return (
    <span
      className={`absolute left-3 top-3 ia-label px-2 py-1 ${styles}`}
    >
      {label}
    </span>
  );
}

export function PostCard({ post }: { post: Post }) {
  const [showComments, setShowComments] = useState(false);

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group relative mb-5 break-inside-avoid ia-panel overflow-hidden transition-transform transition-colors hover:-translate-y-0.5 hover:border-ink-400 dark:hover:border-ink-600"
    >
      {/* Image-forward header (with risk badge overlay) — links to detail */}
      {post.imageUrl && (
        <Link to={`/forum/${post.id}`} className="relative block">
          <img
            src={post.imageUrl}
            alt=""
            loading="lazy"
            className="block w-full bg-ink-100 object-cover dark:bg-ink-800"
          />
          <RiskBadge risk={post.risk} />
        </Link>
      )}

      <div className="px-5 pt-4">
        <div className="flex flex-wrap items-center gap-2">
          {post.tags.map((tag) => (
            <span
              key={tag.id}
              className="border border-ink-200 px-2 py-0.5 font-mono text-xs font-medium uppercase tracking-wider text-ink-600 dark:border-ink-700 dark:text-ink-300"
            >
              #{tag.name}
            </span>
          ))}
          {/* If there's no image, show the risk inline instead of overlaid */}
          {!post.imageUrl && post.risk && (
            <span
              className={`ia-label px-2 py-0.5 ${
                post.risk === 'high'
                  ? 'bg-risk-100 text-risk-700 dark:bg-risk-500/15 dark:text-risk-500'
                  : 'bg-caution-100 text-caution-700 dark:bg-caution-500/15 dark:text-caution-500'
              }`}
            >
              {post.risk === 'high' ? 'High risk' : 'Caution'}
            </span>
          )}
        </div>

        <h3 className="mt-3 font-display text-xl font-semibold leading-snug text-ink-900 transition group-hover:text-safe-700 dark:text-white dark:group-hover:text-safe-400">
          <Link to={`/forum/${post.id}`} className="hover:underline">
            {post.title}
          </Link>
        </h3>
        <p className="mt-2 line-clamp-3 text-base text-ink-600 dark:text-ink-400">
          {post.excerpt}
        </p>
      </div>

      {/* Footer: author + date + engagement */}
      <div className="mt-4 flex items-center gap-3 border-t border-ink-200 px-5 py-3 dark:border-ink-800">
        <span className="grid h-9 w-9 shrink-0 place-items-center border border-ink-300 bg-ink-50 font-mono text-xs font-semibold text-ink-700 dark:border-ink-700 dark:bg-ink-800 dark:text-ink-200">
          {initials(post.author.name)}
        </span>
        <div className="min-w-0">
          <p className="truncate text-sm font-medium text-ink-900 dark:text-white">
            {post.author.name}
          </p>
          <p className="font-mono text-xs text-ink-400">
            {formatDate(post.createdAt)}
          </p>
        </div>
        <div className="ml-auto flex items-center gap-3 font-mono text-sm text-ink-400">
          <button
            type="button"
            onClick={() => setShowComments((s) => !s)}
            aria-expanded={showComments}
            className="flex items-center gap-1.5 px-1.5 py-1 transition hover:text-safe-600 dark:hover:text-safe-400"
          >
            <MessageCircle size={16} /> {post.replyCount}
          </button>
          <span className="flex items-center gap-1.5">
            <Heart size={16} /> {post.likeCount}
          </span>
        </div>
      </div>

      {/* Expandable comment area (gated behind auth inside CommentBox) */}
      <AnimatePresence initial={false}>
        {showComments && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
            className="overflow-hidden border-t border-ink-200 dark:border-ink-800"
          >
            <div className="px-5 py-4">
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.article>
  );
}
