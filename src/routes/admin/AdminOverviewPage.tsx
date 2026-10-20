import { useQuery } from '@tanstack/react-query';
import {
  ArrowRight,
  FileText,
  Flag,
  MessageSquare,
  ShieldCheck,
  Users,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { getAdminStats } from '../../api/admin';
import {
  AdminError,
  AdminLoading,
  StatCard,
} from '../../components/admin/AdminUi';

export function AdminOverviewPage() {
  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['admin', 'stats'],
    queryFn: getAdminStats,
    staleTime: 30_000,
  });

  if (isLoading) return <AdminLoading label="Loading dashboard statistics…" />;
  if (isError || !data) {
    return (
      <AdminError
        message={(error as Error)?.message}
        onRetry={() => void refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <section aria-label="Headline statistics" className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Posts"
          value={data.posts.total}
          hint="Every submission, including deleted"
          icon={FileText}
          breakdown={[
            { label: 'Visible', value: data.posts.visible },
            { label: 'Hidden', value: data.posts.hidden },
            { label: 'Removed', value: data.posts.removed },
            { label: 'Deleted', value: data.posts.deleted },
          ]}
        />
        <StatCard
          label="Comments"
          value={data.comments.total}
          hint="Across all posts"
          icon={MessageSquare}
          breakdown={[
            { label: 'Visible', value: data.comments.visible },
            { label: 'Hidden', value: data.comments.hidden },
            { label: 'Removed', value: data.comments.removed },
          ]}
        />
        <StatCard
          label="Open reports"
          value={data.flags.open}
          hint={`Across ${data.flags.flaggedPosts} ${
            data.flags.flaggedPosts === 1 ? 'post' : 'posts'
          }`}
          icon={Flag}
          tone={data.flags.open > 0 ? 'warning' : 'trust'}
        />
        <StatCard
          label="Accounts"
          value={data.users.total}
          hint="Registered users, including the AI helper"
          icon={Users}
        />
      </section>

      <section className="grid gap-4 lg:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
        <div className="rounded-2xl border border-scam-line bg-scam-800 p-6 shadow-card">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="font-display text-lg font-bold text-scam-text">
                Needs attention
              </h2>
              <p className="mt-1 text-sm text-scam-muted">
                Jump straight into the work queues.
              </p>
            </div>
            <button
              type="button"
              onClick={() => void refetch()}
              disabled={isFetching}
              className="sr-btn-ghost px-3 py-1.5 text-xs disabled:opacity-50"
            >
              {isFetching ? 'Refreshing…' : 'Refresh'}
            </button>
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <Link
              to="/admin/reports"
              className="group rounded-xl border border-scam-line bg-scam-750/60 p-4 transition hover:border-risk-med/50 hover:bg-scam-750"
            >
              <div className="flex items-center justify-between">
                <span className="grid h-9 w-9 place-items-center rounded-lg border border-risk-med/40 bg-risk-med/10 text-risk-med">
                  <Flag size={17} />
                </span>
                <ArrowRight
                  size={16}
                  className="text-scam-dim transition group-hover:translate-x-0.5 group-hover:text-risk-med"
                />
              </div>
              <p className="sr-nums mt-3 text-2xl font-bold text-scam-text">
                {data.flags.open}
              </p>
              <p className="text-sm font-medium text-scam-text">Open reports</p>
              <p className="mt-0.5 text-xs text-scam-muted">
                Flagged posts and comments awaiting a decision
              </p>
            </Link>

            <Link
              to="/admin/posts"
              className="group rounded-xl border border-scam-line bg-scam-750/60 p-4 transition hover:border-trust-500/50 hover:bg-scam-750"
            >
              <div className="flex items-center justify-between">
                <span className="grid h-9 w-9 place-items-center rounded-lg border border-trust-500/40 bg-trust-500/10 text-trust-500">
                  <ShieldCheck size={17} />
                </span>
                <ArrowRight
                  size={16}
                  className="text-scam-dim transition group-hover:translate-x-0.5 group-hover:text-trust-500"
                />
              </div>
              <p className="sr-nums mt-3 text-2xl font-bold text-scam-text">
                {data.posts.hidden + data.posts.removed}
              </p>
              <p className="text-sm font-medium text-scam-text">
                Hidden or removed posts
              </p>
              <p className="mt-0.5 text-xs text-scam-muted">
                Audit content that is no longer in the public feed
              </p>
            </Link>
          </div>
        </div>

        <div className="rounded-2xl border border-scam-line bg-scam-800 p-6 shadow-card">
          <h2 className="font-display text-lg font-bold text-scam-text">
            Staff notes
          </h2>
          <ul className="mt-4 space-y-3 text-sm leading-relaxed text-scam-muted">
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-trust-500" />
              Deletions are soft: removed content stays visible here for audit
              and can be restored by a moderator.
            </li>
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-trust-500" />
              Resolve reports by reviewing the flagged target. Hiding or removing
              it closes the related open flags.
            </li>
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-trust-500" />
              Role changes are issued in the next access token. The affected
              user may keep their old permissions for up to 15 minutes.
            </li>
          </ul>
        </div>
      </section>
    </div>
  );
}
