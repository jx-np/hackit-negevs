import { motion } from 'framer-motion';
import {
  ArrowLeft,
  FileText,
  Flag,
  Gauge,
  Lock,
  MessageSquare,
  ShieldCheck,
  Users,
} from 'lucide-react';
import { Link, NavLink, Outlet } from 'react-router-dom';
import { AdminLoading, Badge } from '../../components/admin/AdminUi';
import { useAuth } from '../../context/AuthContext';
import { ROLE_LABELS } from '../../lib/roles';

const TABS = [
  { to: '/admin', label: 'Overview', icon: Gauge, end: true },
  { to: '/admin/reports', label: 'Reports', icon: Flag, end: false },
  { to: '/admin/posts', label: 'Posts', icon: FileText, end: false },
  { to: '/admin/comments', label: 'Comments', icon: MessageSquare, end: false },
  {
    to: '/admin/users',
    label: 'Users & roles',
    icon: Users,
    end: false,
    adminOnly: true,
  },
] as const;

function AccessDenied({
  title,
  description,
  signedOut = false,
}: {
  title: string;
  description: string;
  signedOut?: boolean;
}) {
  return (
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto flex w-full max-w-xl flex-col items-center px-5 py-24 text-center lg:px-8">
        <span className="grid h-14 w-14 place-items-center rounded-2xl border border-scam-line bg-scam-800 text-risk-med shadow-card">
          {signedOut ? <Lock size={26} /> : <ShieldCheck size={26} />}
        </span>
        <h1 className="mt-5 font-display text-2xl font-bold tracking-tight">
          {title}
        </h1>
        <p className="mt-2 text-sm leading-relaxed text-scam-muted">
          {description}
        </p>
        <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
          {signedOut ? (
            <Link to="/auth" className="sr-btn-primary px-5 py-2.5">
              Sign in
            </Link>
          ) : (
            <Link to="/forum" className="sr-btn-ghost px-4 py-2.5">
              <ArrowLeft size={16} /> Back to the forum
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * Staff console shell.
 *
 * Access is driven by the role in the current `/me` profile. `moderator` and
 * `admin` can see the console; only `admin` gets the Users & roles tab (the
 * backend returns 403 for moderators on `/admin/users*`).
 */
export function AdminPage() {
  const { user, isLoggedIn, isLoading, isModerator, isAdmin } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-scam-950 px-5 py-16 text-scam-text lg:px-8">
        <div className="mx-auto max-w-6xl">
          <AdminLoading label="Checking staff permissions…" />
        </div>
      </div>
    );
  }

  if (!isLoggedIn) {
    return (
      <AccessDenied
        signedOut
        title="Staff sign-in required"
        description="The admin dashboard is only available to moderator and administrator accounts. Sign in with a staff account to continue."
      />
    );
  }

  if (!isModerator) {
    return (
      <AccessDenied
        title="You don't have access"
        description="This area is reserved for moderators and administrators. If you believe your role is wrong, ask an administrator to check your account — role changes take effect within about 15 minutes."
      />
    );
  }

  const tabs = TABS.filter((tab) => !('adminOnly' in tab) || isAdmin);

  return (
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto w-full max-w-[1400px] px-5 py-8 lg:px-8">
        <motion.header
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35, ease: 'easeOut' }}
          className="relative mb-6 overflow-hidden rounded-2xl border border-scam-line bg-scam-800 p-6 shadow-card sm:p-7"
        >
          <div
            aria-hidden
            className="pointer-events-none absolute -right-24 -top-24 h-64 w-64 sw-halo"
          />
          <ShieldCheck
            aria-hidden
            strokeWidth={1}
            className="pointer-events-none absolute -bottom-10 right-4 h-40 w-40 text-trust-500/[0.07]"
          />
          <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-4">
              <span className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-gradient-to-b from-trust-500 to-trust-700 text-white shadow-button">
                <ShieldCheck size={26} aria-hidden />
              </span>
              <div>
                <span className="sr-eyebrow">Staff console</span>
                <h1 className="mt-1 font-display text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
                  Admin dashboard
                </h1>
                <p className="mt-1 max-w-lg text-pretty text-sm leading-relaxed text-scam-muted">
                  Review flagged content, audit every post and comment, and keep
                  the community safe.
                </p>
              </div>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {user?.role && (
                <Badge tone={isAdmin ? 'warning' : 'violet'}>
                  {ROLE_LABELS[user.role]}
                </Badge>
              )}
              <Link to="/forum" className="sr-btn-ghost px-3 py-2">
                <ArrowLeft size={15} /> View forum
              </Link>
            </div>
          </div>
        </motion.header>

        <nav
          aria-label="Admin sections"
          className="mb-6 flex gap-1 overflow-x-auto rounded-xl border border-scam-line bg-scam-800 p-1.5"
        >
          {tabs.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `sr-focus inline-flex shrink-0 items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-trust-500 text-white shadow-button'
                    : 'text-scam-muted hover:bg-scam-750 hover:text-scam-text'
                }`
              }
            >
              <Icon size={16} aria-hidden />
              {label}
            </NavLink>
          ))}
        </nav>

        <Outlet />
      </div>
    </div>
  );
}
