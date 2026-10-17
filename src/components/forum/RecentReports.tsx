import { ShieldAlert, TriangleAlert } from 'lucide-react';
import { Link } from 'react-router-dom';
import { usePosts } from '../../hooks/usePosts';
import type { Post, RiskLevel } from '../../types';

/** Only reports created within this window count as "recent". */
const RECENT_WINDOW_MS = 24 * 60 * 60 * 1000;

function isRecent(post: Post): boolean {
  return Date.now() - new Date(post.createdAt).getTime() <= RECENT_WINDOW_MS;
}

/** Relative "time ago" from an ISO timestamp. */
function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.round(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.round(hrs / 24);
  return `${days}d ago`;
}

function riskDotClass(risk: RiskLevel | undefined): string {
  if (risk === 'high') return 'bg-risk-high';
  if (risk === 'medium') return 'bg-risk-med';
  return 'bg-risk-low';
}

function riskLabel(risk: RiskLevel | undefined): string {
  if (risk === 'high') return 'High risk';
  if (risk === 'medium') return 'Under review';
  return 'Low risk';
}

function RecentRow({ post }: { post: Post }) {
  const category = post.tags[0]?.name ?? 'Report';
  return (
    <Link
      to={`/forum/${post.id}`}
      className="sr-focus block rounded-xl px-2 py-2.5 transition hover:bg-scam-750"
    >
      <div className="flex items-center gap-2">
        <span className="sr-tile h-5 w-5">
          <ShieldAlert size={12} />
        </span>
        <span className="truncate text-xs font-medium text-scam-text">{category}</span>
        <span className="text-xs text-scam-dim">· {timeAgo(post.createdAt)}</span>
        <span
          className={`ml-auto h-2 w-2 shrink-0 rounded-full ${riskDotClass(post.risk)}`}
          aria-hidden
        />
        <span className="sr-only">{riskLabel(post.risk)}</span>
      </div>
      <p className="mt-1.5 line-clamp-2 text-sm leading-snug text-scam-text">
        {post.title}
      </p>
      <p className="mt-1 text-xs text-scam-muted">
        {post.likeCount} confirmed · {post.replyCount} comments
      </p>
    </Link>
  );
}

type RecentReportsProps = {
  /** Switch the main feed to the full, newest-first report list. */
  onSeeAll?: () => void;
};

export function RecentReports({ onSeeAll }: RecentReportsProps) {
  // Always show the newest reports, independent of the main feed filters.
  const { data, isLoading } = usePosts({ query: '', tagId: null, sort: 'new' });
  const recent = (data?.pages.flatMap((p) => p.posts) ?? [])
    .filter(isRecent)
    .slice(0, 6);

  return (
    <aside
      className="w-full lg:sticky lg:top-[6.5rem] lg:mt-[97px] lg:w-[310px] lg:shrink-0 lg:self-start lg:max-h-[calc(100vh-7.5rem)] lg:overflow-y-auto lg:overscroll-contain lg:pb-6"
      aria-label="Recently reported scams"
    >
      {/* Recently reported */}
      <div className="sr-surface p-4">
        <div className="flex items-center justify-between border-b border-scam-line pb-3">
          <span className="sr-label">Recently Reported Scams</span>
          {onSeeAll && (
            <button
              type="button"
              onClick={onSeeAll}
              className="text-xs font-medium text-trust-400 transition hover:underline"
            >
              See all
            </button>
          )}
        </div>

        <div className="mt-1 flex flex-col divide-y divide-scam-line">
          {isLoading
            ? Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="space-y-2 py-3">
                  <div className="h-3 w-24 animate-pulse rounded bg-scam-750" />
                  <div className="h-4 w-full animate-pulse rounded bg-scam-750" />
                  <div className="h-3 w-32 animate-pulse rounded bg-scam-750" />
                </div>
              ))
            : recent.map((post) => <RecentRow key={post.id} post={post} />)}

          {!isLoading && recent.length === 0 && (
            <p className="py-3 text-sm text-scam-muted">No recent reports yet.</p>
          )}
        </div>
      </div>

      {/* Active threat alerts — urgent, time-sensitive scams. */}
      <div className="mt-4 overflow-hidden rounded-2xl border border-risk-high/30 bg-risk-high/[0.05] shadow-card">
        {/* Thin red top border strip for urgency */}
        <div className="h-1 w-full bg-gradient-to-r from-risk-high to-risk-med" />
        <div className="p-4">
          <div className="flex items-center gap-2">
            <span className="relative flex h-2.5 w-2.5">
              <span className="absolute inline-flex h-full w-full animate-pulse-dot rounded-full bg-risk-high" />
            </span>
            <TriangleAlert size={15} className="text-risk-high" />
            <span className="text-[11px] font-semibold uppercase tracking-[0.14em] text-risk-high">
              Active Threat Alerts
            </span>
          </div>
          <ul className="mt-3 space-y-3">
            <li>
              <p className="text-sm font-medium text-scam-text">
                Bank "account locked" phishing texts
              </p>
              <p className="mt-0.5 text-xs leading-relaxed text-scam-muted">
                Spoofed sender IDs · do not tap links
              </p>
            </li>
            <li>
              <p className="text-sm font-medium text-scam-text">
                Crypto "double your deposit" DMs
              </p>
              <p className="mt-0.5 text-xs leading-relaxed text-scam-muted">
                Targeting new investors on social apps
              </p>
            </li>
          </ul>
        </div>
      </div>
    </aside>
  );
}
