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

// Deterministic avatar gradient based on the author's name.
const AVATAR_GRADIENTS = [
  'from-brand-500 to-violet-500',
  'from-accent-500 to-brand-500',
  'from-violet-500 to-fuchsia-500',
  'from-cyan-500 to-blue-500',
  'from-rose-500 to-orange-400',
];
function avatarGradient(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + hash * 31;
  return AVATAR_GRADIENTS[Math.abs(hash) % AVATAR_GRADIENTS.length];
}

export function PostCard({ post }: { post: Post }) {
  const [showComments, setShowComments] = useState(false);

  return (
    <motion.article
      // Scroll-reveal: animate in when the card scrolls into view.
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.45, ease: 'easeOut' }}
      className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition-all hover:border-brand-300 hover:shadow-glow dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-700"
    >
      {/* Hover accent bar */}
      <span className="absolute inset-x-0 top-0 h-1 origin-left scale-x-0 bg-brand-gradient transition-transform duration-300 group-hover:scale-x-100" />

      <div className="mb-3 flex items-center gap-3">
        <span
          className={`grid h-11 w-11 place-items-center rounded-full bg-gradient-to-br ${avatarGradient(
            post.author.name,
          )} text-base font-semibold text-white shadow-sm`}
        >
          {initials(post.author.name)}
        </span>
        <div className="text-base">
          <p className="font-medium">{post.author.name}</p>
          <p className="text-slate-400">{formatDate(post.createdAt)}</p>
        </div>
      </div>

      <h3 className="mb-2 text-2xl font-semibold leading-snug transition group-hover:text-brand-600 dark:group-hover:text-brand-300">
        {post.title}
      </h3>
      <p className="mb-4 line-clamp-3 text-lg text-slate-500 dark:text-slate-400">
        {post.excerpt}
      </p>

      <div className="flex items-center justify-between border-t border-slate-100 pt-3 dark:border-slate-800">
        <div className="flex flex-wrap gap-2">
          {post.tags.map((tag) => (
            <span
              key={tag.id}
              className="rounded-full bg-brand-50 px-3 py-1 text-sm font-medium text-brand-700 dark:bg-brand-900/30 dark:text-brand-300"
            >
              #{tag.name}
            </span>
          ))}
        </div>
        <div className="flex items-center gap-4 text-base text-slate-400">
          <button
            type="button"
            onClick={() => setShowComments((s) => !s)}
            aria-expanded={showComments}
            className="flex items-center gap-1.5 rounded-lg px-2 py-1 transition hover:bg-slate-100 hover:text-brand-500 dark:hover:bg-slate-800"
          >
            <MessageCircle size={18} /> {post.replyCount}
          </button>
          <span className="flex items-center gap-1.5">
            <Heart size={18} /> {post.likeCount}
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
            className="overflow-hidden"
          >
            <div className="mt-4 border-t border-slate-100 pt-4 dark:border-slate-800">
              <CommentBox postId={post.id} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.article>
  );
}
