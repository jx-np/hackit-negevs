import { motion } from 'framer-motion';
import {
  ArrowBigDown,
  ArrowBigUp,
  ArrowLeft,
  CalendarDays,
  MessageCircle,
  ShieldAlert,
  ShieldCheck,
  TriangleAlert,
} from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { CommentBox } from '../components/forum/CommentBox';
import { CommentList } from '../components/forum/CommentList';
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

/** Risk metadata — traffic-light pill + colored strip (icon + label). */
const RISK_META = {
  high: {
    label: 'High risk',
    pill: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
    strip: 'bg-risk-high',
    Icon: TriangleAlert,
  },
  medium: {
    label: 'Under review',
    pill: 'border-risk-med/40 bg-risk-med/10 text-risk-med',
    strip: 'bg-risk-med',
    Icon: ShieldAlert,
  },
} as const;

function riskKey(risk: Post['risk']): 'high' | 'medium' {
  return risk === 'high' ? 'high' : 'medium';
}

function RiskBadge({ risk }: { risk: Post['risk'] }) {
  if (!risk) return null;
  const s = RISK_META[riskKey(risk)];
  const { Icon } = s;
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold ${s.pill}`}
    >
      <Icon size={13} /> {s.label}
    </span>
  );
}

export function PostDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: post, isLoading, isError, error } = usePost(id);
  const verified = post?.reviewStatus === 'reviewed';
  const risk = post?.risk ? RISK_META[riskKey(post.risk)] : null;

  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
      style={{ fontFamily: "'Inter', system-ui, -apple-system, sans-serif" }}
    >
      <div className="mx-auto w-full max-w-6xl px-5 py-10 lg:px-8">
        <Link
          to="/forum"
          className="mb-6 inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-scam-muted transition hover:text-trust-400"
        >
          <ArrowLeft size={16} /> Back to forum
        </Link>

        {isLoading && (
          <div className="overflow-hidden rounded-lg border border-scam-line bg-scam-800 shadow-card">
            <div className="aspect-[16/9] w-full animate-pulse bg-scam-750" />
            <div className="space-y-3 p-6">
              <div className="h-8 w-3/4 animate-pulse rounded bg-scam-750" />
              <div className="h-4 w-full animate-pulse rounded bg-scam-750" />
              <div className="h-4 w-2/3 animate-pulse rounded bg-scam-750" />
            </div>
          </div>
        )}

        {isError && (
          <div className="rounded-lg border border-risk-high/40 bg-risk-high/10 p-6 text-center">
            <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-risk-high">
              Not found
            </p>
            <p className="mt-2 text-lg font-medium text-scam-text">
              {(error as Error)?.message ?? 'This report could not be loaded.'}
            </p>
            <Link
              to="/forum"
              className="mt-4 inline-block text-sm font-medium text-trust-400 underline"
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
              className="relative overflow-hidden rounded-lg border border-scam-line bg-scam-800 shadow-card"
            >
              {/* Colored left-border risk strip */}
              {post.risk && risk && (
                <span
                  className={`absolute inset-y-0 left-0 z-10 w-1 ${risk.strip}`}
                  aria-hidden
                />
              )}

              {post.imageUrl && (
                <div className="relative">
                  <img
                    src={post.imageUrl}
                    alt=""
                    className="block max-h-96 w-full bg-scam-750 object-cover"
                  />
                  {post.risk && (
                    <span className="absolute left-4 top-4">
                      <RiskBadge risk={post.risk} />
                    </span>
                  )}
                </div>
              )}

              <div className="p-6 pl-7">
                {/* Category + verified + tags + risk (inline when no image) */}
                <div className="mb-4 flex flex-wrap items-center gap-2">
                  {verified && (
                    <span
                      className="inline-flex items-center gap-1 rounded-full border border-trust-500/40 bg-trust-500/10 px-2 py-0.5 text-[11px] font-semibold text-trust-300"
                      title="Verified by moderators"
                    >
                      <ShieldCheck size={12} /> Verified
                    </span>
                  )}
                  {!post.imageUrl && post.risk && <RiskBadge risk={post.risk} />}
                  {post.tags.map((tag) => (
                    <span
                      key={tag.id}
                      className="rounded-full border border-scam-line px-2.5 py-0.5 text-xs font-medium text-scam-muted transition hover:border-trust-500/50 hover:text-trust-400"
                    >
                      #{tag.name}
                    </span>
                  ))}
                </div>

                <h1 className="text-3xl font-bold leading-tight tracking-tight text-scam-text sm:text-4xl">
                  {post.title}
                </h1>

                {/* Author row */}
                <div className="mt-5 flex items-center gap-3 border-b border-scam-line pb-5">
                  <span className="sr-tile h-11 w-11">
                    <ShieldAlert size={20} />
                  </span>
                  <div>
                    <p className="font-semibold text-scam-text">
                      {post.author.name}
                    </p>
                    <p className="text-xs text-scam-muted">
                      {initials(post.author.name)} · {formatDate(post.createdAt)}
                    </p>
                  </div>
                  <div className="ml-auto flex items-center gap-4 text-sm text-scam-muted">
                    <span className="flex items-center gap-1.5">
                      <MessageCircle size={16} /> {post.replyCount}
                    </span>
                    <span className="flex items-center gap-1.5 text-risk-low">
                      <ShieldCheck size={16} /> {post.likeCount}
                    </span>
                  </div>
                </div>

                {/* Vote control + social proof */}
                <div className="mt-5 flex items-center gap-3">
                  <div className="flex items-center gap-1 rounded-md border border-scam-line bg-scam-750 px-1 py-0.5">
                    <button
                      type="button"
                      aria-label="This happened to me too"
                      className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400"
                    >
                      <ArrowBigUp size={18} />
                    </button>
                    <span className="min-w-[1.5rem] text-center text-sm font-semibold text-scam-text">
                      {post.likeCount}
                    </span>
                    <button
                      type="button"
                      aria-label="Downvote"
                      className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-risk-high"
                    >
                      <ArrowBigDown size={18} />
                    </button>
                  </div>
                  <span className="inline-flex items-center gap-1.5 text-xs font-medium text-risk-low">
                    <ShieldCheck size={14} /> {post.likeCount} confirmed
                  </span>
                </div>

                {/* Incident date */}
                {post.incidentDate && (
                  <div className="mt-5 flex items-center gap-2 rounded-md border border-scam-line bg-scam-750 px-4 py-3">
                    <CalendarDays size={18} className="text-trust-400" />
                    <span className="text-[11px] font-semibold uppercase tracking-[0.14em] text-scam-muted">
                      Incident date
                    </span>
                    <span className="ml-auto text-sm text-scam-text">
                      {formatDate(post.incidentDate)}
                    </span>
                  </div>
                )}

                {/* Body */}
                <div className="mt-5 space-y-4 text-base leading-7 text-scam-muted">
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
              className="rounded-lg border border-scam-line bg-scam-800 p-6 shadow-card lg:sticky lg:top-24"
            >
              <h2 className="mb-4 border-b border-scam-line pb-4 text-[11px] font-semibold uppercase tracking-[0.18em] text-scam-muted">
                Discussion · {post.replyCount} comments
              </h2>
              <div className="mb-5">
                <CommentList postId={post.id} />
              </div>
              <CommentBox postId={post.id} />
            </motion.aside>
          </div>
        )}
      </div>
    </div>
  );
}
