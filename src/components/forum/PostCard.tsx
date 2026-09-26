import { motion } from 'framer-motion';
import { Heart, MessageCircle } from 'lucide-react';
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

export function PostCard({ post }: { post: Post }) {
  return (
    <motion.article
      // Scroll-reveal: animate in when the card scrolls into view.
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.45, ease: 'easeOut' }}
      whileHover={{ y: -4 }}
      className="group cursor-pointer rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-brand-300 hover:shadow-md dark:border-slate-800 dark:bg-slate-900 dark:hover:border-brand-700"
    >
      <div className="mb-3 flex items-center gap-3">
        <span className="grid h-9 w-9 place-items-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700 dark:bg-brand-900/40 dark:text-brand-300">
          {initials(post.author.name)}
        </span>
        <div className="text-sm">
          <p className="font-medium">{post.author.name}</p>
          <p className="text-slate-400">{formatDate(post.createdAt)}</p>
        </div>
      </div>

      <h3 className="mb-2 text-lg font-semibold leading-snug transition group-hover:text-brand-600 dark:group-hover:text-brand-300">
        {post.title}
      </h3>
      <p className="mb-4 line-clamp-2 text-sm text-slate-500 dark:text-slate-400">
        {post.excerpt}
      </p>

      <div className="flex items-center justify-between">
        <div className="flex flex-wrap gap-1.5">
          {post.tags.map((tag) => (
            <span
              key={tag.id}
              className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-300"
            >
              {tag.name}
            </span>
          ))}
        </div>
        <div className="flex items-center gap-4 text-sm text-slate-400">
          <span className="flex items-center gap-1">
            <MessageCircle size={16} /> {post.replyCount}
          </span>
          <span className="flex items-center gap-1">
            <Heart size={16} /> {post.likeCount}
          </span>
        </div>
      </div>
    </motion.article>
  );
}
