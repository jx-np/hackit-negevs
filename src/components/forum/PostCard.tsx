import { AnimatePresence, motion } from 'framer-motion';
import { Heart, MessageCircle } from 'lucide-react';
import { useState } from 'react';
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

// Deterministic short record id from the post id (registry feel).
function recordId(id: string): string {
  let hash = 0;
  for (let i = 0; i < id.length; i++) hash = id.charCodeAt(i) + hash * 31;
  return String(Math.abs(hash) % 10000).padStart(4, '0');
}

export function PostCard({ post }: { post: Post }) {
  const [showComments, setShowComments] = useState(false);

  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group relative ia-panel shadow-ia transition-colors hover:border-ink-400 dark:hover:border-ink-600"
    >
      {/* Top hairline accent on hover */}
      <span className="absolute inset-x-0 top-0 h-0.5 origin-left scale-x-0 bg-safe-500 transition-transform duration-300 group-hover:scale-x-100" />

      {/* Record header: id + author + date */}
      <div className="flex items-center gap-3 border-b border-ink-200 px-6 py-3 dark:border-ink-800">
        <span className="grid h-9 w-9 place-items-center border border-ink-300 bg-ink-50 font-mono text-sm font-semibold text-ink-700 dark:border-ink-700 dark:bg-ink-800 dark:text-ink-200">
          {initials(post.author.name)}
        </span>
        <div className="min-w-0 text-base">
          <p className="truncate font-medium text-ink-900 dark:text-white">
            {post.author.name}
          </p>
          <p className="font-mono text-xs text-ink-400">
            {formatDate(post.createdAt)}
          </p>
        </div>
        <span className="ia-label ml-auto text-ink-300 dark:text-ink-600">
          #{recordId(post.id)}
        </span>
      </div>

      <div className="px-6 py-5">
        <h3 className="font-display text-2xl font-semibold leading-snug text-ink-900 transition group-hover:text-safe-700 dark:text-white dark:group-hover:text-safe-400">
          {post.title}
        </h3>
        <p className="mt-2 line-clamp-3 text-lg text-ink-600 dark:text-ink-400">
          {post.excerpt}
        </p>
      </div>

      <div className="flex items-center justify-between border-t border-ink-200 px-6 py-3 dark:border-ink-800">
        <div className="flex flex-wrap gap-2">
          {post.tags.map((tag) => (
            <span
              key={tag.id}
              className="border border-ink-200 px-2.5 py-1 font-mono text-xs font-medium text-ink-600 dark:border-ink-700 dark:text-ink-300"
            >
              #{tag.name}
            </span>
          ))}
        </div>
        <div className="flex items-center gap-3 font-mono text-sm text-ink-400">
          <button
            type="button"
            onClick={() => setShowComments((s) => !s)}
            aria-expanded={showComments}
            className="flex items-center gap-1.5 px-2 py-1 transition hover:text-safe-600 dark:hover:text-safe-400"
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
            <div className="px-6 py-4">
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.article>
  );
}
