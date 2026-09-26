import { motion } from 'framer-motion';
import { ArrowUpRight, Heart, MessageCircle } from 'lucide-react';
import type { Post } from '../../types';

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
  return (
    <motion.article
      // Scroll-reveal: animate in when the card scrolls into view.
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.45, ease: 'easeOut' }}
      whileHover={{ y: -4 }}
      className="group relative cursor-pointer overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:border-brand-300 hover:shadow-glow dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-700"
    >
      {/* Hover accent bar */}
      <span className="absolute inset-x-0 top-0 h-1 origin-left scale-x-0 bg-brand-gradient transition-transform duration-300 group-hover:scale-x-100" />

      <div className="mb-3 flex items-center gap-3">
        <span
          className={`grid h-10 w-10 place-items-center rounded-full bg-gradient-to-br ${avatarGradient(
            post.author.name,
          )} text-sm font-semibold text-white shadow-sm`}
        >
          {initials(post.author.name)}
        </span>
        <div className="text-sm">
          <p className="font-medium">{post.author.name}</p>
          <p className="text-slate-400">{formatDate(post.createdAt)}</p>
        </div>
        <ArrowUpRight
          size={18}
          className="ml-auto text-slate-300 opacity-0 transition-all group-hover:translate-x-0.5 group-hover:opacity-100 dark:text-slate-600"
        />
      </div>

      <h3 className="mb-2 text-lg font-semibold leading-snug transition group-hover:text-brand-600 dark:group-hover:text-brand-300">
        {post.title}
      </h3>
      <p className="mb-4 line-clamp-2 text-sm text-slate-500 dark:text-slate-400">
        {post.excerpt}
      </p>

      <div className="flex items-center justify-between border-t border-slate-100 pt-3 dark:border-slate-800">
        <div className="flex flex-wrap gap-1.5">
          {post.tags.map((tag) => (
            <span
              key={tag.id}
              className="rounded-full bg-brand-50 px-2.5 py-0.5 text-xs font-medium text-brand-700 dark:bg-brand-900/30 dark:text-brand-300"
            >
              #{tag.name}
            </span>
          ))}
        </div>
        <div className="flex items-center gap-4 text-sm text-slate-400">
          <span className="flex items-center gap-1 transition group-hover:text-brand-500">
            <MessageCircle size={16} /> {post.replyCount}
          </span>
          <span className="flex items-center gap-1 transition group-hover:text-rose-500">
            <Heart size={16} /> {post.likeCount}
          </span>
        </div>
      </div>
    </motion.article>
  );
}
