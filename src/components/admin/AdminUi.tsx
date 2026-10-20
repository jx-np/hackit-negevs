import {
  ChevronLeft,
  ChevronRight,
  Loader2,
  RefreshCw,
  type LucideIcon,
} from 'lucide-react';
import type { ReactNode } from 'react';

/** Shared control styling so every admin filter looks the same. */
export const ADMIN_INPUT_CLASS =
  'rounded-lg border border-scam-line bg-scam-750 px-3 py-2 text-sm text-scam-text outline-none transition placeholder:text-scam-muted focus:border-trust-500 focus:ring-2 focus:ring-trust-500/30';
export const ADMIN_SELECT_CLASS = `${ADMIN_INPUT_CLASS} pr-8`;

type BadgeTone =
  | 'neutral'
  | 'trust'
  | 'success'
  | 'warning'
  | 'danger'
  | 'violet';

const TONE_CLASS: Record<BadgeTone, string> = {
  neutral: 'border-scam-line bg-scam-750 text-scam-muted',
  trust:
    'border-trust-500/40 bg-trust-500/10 text-trust-600 dark:text-trust-400',
  success: 'border-risk-low/40 bg-risk-low/10 text-risk-low',
  warning: 'border-risk-med/40 bg-risk-med/10 text-risk-med',
  danger: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
  violet: 'border-risk-psa/40 bg-risk-psa/10 text-risk-psa',
};

export function Badge({
  children,
  tone = 'neutral',
  title,
}: {
  children: ReactNode;
  tone?: BadgeTone;
  title?: string;
}) {
  return (
    <span
      title={title}
      className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-semibold ${TONE_CLASS[tone]}`}
    >
      {children}
    </span>
  );
}

const STATUS_META: Record<string, { label: string; tone: BadgeTone }> = {
  visible: { label: 'Visible', tone: 'success' },
  reviewed: { label: 'Reviewed', tone: 'success' },
  unverified: { label: 'Unverified', tone: 'warning' },
  disputed: { label: 'Disputed', tone: 'violet' },
  hidden: { label: 'Hidden', tone: 'warning' },
  removed: { label: 'Removed', tone: 'danger' },
  deleted: { label: 'Deleted', tone: 'danger' },
  open: { label: 'Open', tone: 'warning' },
  resolved: { label: 'Resolved', tone: 'success' },
  dismissed: { label: 'Dismissed', tone: 'neutral' },
  resident: { label: 'Resident', tone: 'neutral' },
  helper: { label: 'Helper', tone: 'trust' },
  moderator: { label: 'Moderator', tone: 'violet' },
  admin: { label: 'Admin', tone: 'warning' },
};

/**
 * Moderation/review/role status pill with a consistent color language.
 *
 * Some admin payloads omit optional status fields (for example a flag whose
 * containing post no longer reports a review status). Treat a missing value as
 * "Unknown" instead of letting the fallback label access `.replace` on
 * `undefined`.
 */
export function StatusBadge({ status }: { status?: string | null }) {
  const value = status?.trim();
  if (!value) {
    return (
      <Badge tone="neutral" title="The server did not report a status">
        Unknown
      </Badge>
    );
  }

  const meta = STATUS_META[value] ?? {
    label: value.replace(/_/g, ' '),
    tone: 'neutral' as const,
  };
  return (
    <Badge tone={meta.tone}>
      <span className="capitalize">{meta.label}</span>
    </Badge>
  );
}

export function StatCard({
  label,
  value,
  hint,
  icon: Icon,
  tone = 'trust',
  breakdown,
}: {
  label: string;
  value: number;
  hint?: string;
  icon: LucideIcon;
  tone?: 'trust' | 'warning' | 'danger' | 'violet';
  breakdown?: Array<{ label: string; value: number }>;
}) {
  const iconTone =
    tone === 'warning'
      ? 'border-risk-med/40 bg-risk-med/10 text-risk-med'
      : tone === 'danger'
        ? 'border-risk-high/40 bg-risk-high/10 text-risk-high'
        : tone === 'violet'
          ? 'border-risk-psa/40 bg-risk-psa/10 text-risk-psa'
          : 'border-trust-500/40 bg-trust-500/10 text-trust-500';

  return (
    <div className="rounded-2xl border border-scam-line bg-scam-800 p-5 shadow-card">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="sr-label">{label}</p>
          <p className="sr-nums mt-2 text-3xl font-bold tracking-tight text-scam-text">
            {value.toLocaleString()}
          </p>
          {hint && <p className="mt-1 text-xs text-scam-muted">{hint}</p>}
        </div>
        <span
          className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl border ${iconTone}`}
        >
          <Icon size={19} aria-hidden />
        </span>
      </div>
      {breakdown && breakdown.length > 0 && (
        <dl className="mt-4 grid grid-cols-2 gap-x-4 gap-y-2 border-t border-scam-line pt-3">
          {breakdown.map((item) => (
            <div key={item.label} className="flex items-center justify-between gap-2">
              <dt className="text-[11px] font-medium text-scam-muted">
                {item.label}
              </dt>
              <dd className="sr-nums text-xs font-semibold text-scam-text">
                {item.value.toLocaleString()}
              </dd>
            </div>
          ))}
        </dl>
      )}
    </div>
  );
}

export function AdminLoading({ label = 'Loading…' }: { label?: string }) {
  return (
    <div className="flex items-center justify-center gap-2 rounded-2xl border border-scam-line bg-scam-800 px-6 py-14 text-sm text-scam-muted">
      <Loader2 size={17} className="animate-spin" aria-hidden />
      {label}
    </div>
  );
}

export function AdminError({
  message,
  onRetry,
}: {
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="rounded-2xl border border-risk-high/40 bg-risk-high/10 px-6 py-8 text-center">
      <p className="text-sm font-semibold text-risk-high">
        Could not load this view
      </p>
      <p className="mt-1 text-sm text-scam-muted">
        {message || 'The server rejected the request. Please try again.'}
      </p>
      {onRetry && (
        <button type="button" onClick={onRetry} className="sr-btn-ghost mt-4">
          <RefreshCw size={15} /> Retry
        </button>
      )}
    </div>
  );
}

export function AdminEmptyState({
  title,
  description,
  icon: Icon,
  action,
}: {
  title: string;
  description: string;
  icon: LucideIcon;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center rounded-2xl border border-dashed border-scam-line bg-scam-800/40 px-6 py-14 text-center">
      <span className="grid h-12 w-12 place-items-center rounded-xl border border-scam-line bg-scam-750 text-scam-muted">
        <Icon size={22} aria-hidden />
      </span>
      <p className="mt-4 text-lg font-semibold text-scam-text">{title}</p>
      <p className="mt-1 max-w-md text-sm text-scam-muted">{description}</p>
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}

export function PaginationBar({
  hasPrev,
  hasNext,
  onPrev,
  onNext,
  loading,
  count,
}: {
  hasPrev: boolean;
  hasNext: boolean;
  onPrev: () => void;
  onNext: () => void;
  loading?: boolean;
  count: number;
}) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-scam-line px-4 py-3">
      <p className="text-xs text-scam-muted">
        <span className="sr-nums font-semibold text-scam-text">{count}</span>{' '}
        {count === 1 ? 'row' : 'rows'} on this page
      </p>
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={onPrev}
          disabled={!hasPrev || loading}
          className="sr-btn-ghost px-3 py-1.5 text-xs disabled:cursor-not-allowed disabled:opacity-40"
        >
          <ChevronLeft size={14} /> Previous
        </button>
        <button
          type="button"
          onClick={onNext}
          disabled={!hasNext || loading}
          className="sr-btn-ghost px-3 py-1.5 text-xs disabled:cursor-not-allowed disabled:opacity-40"
        >
          Next <ChevronRight size={14} />
        </button>
      </div>
    </div>
  );
}

/** Small danger-styled button used by destructive table actions. */
export function DangerButton({
  children,
  onClick,
  disabled,
  title,
}: {
  children: ReactNode;
  onClick: () => void;
  disabled?: boolean;
  title?: string;
}) {
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      disabled={disabled}
      className="inline-flex items-center gap-1.5 rounded-lg border border-risk-high/40 bg-risk-high/10 px-2.5 py-1.5 text-xs font-semibold text-risk-high transition hover:border-risk-high/70 hover:bg-risk-high/20 disabled:cursor-not-allowed disabled:opacity-40"
    >
      {children}
    </button>
  );
}
