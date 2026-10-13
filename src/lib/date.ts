/**
 * Date formatting helpers for displaying post/comment timestamps.
 *
 * Design: recent timestamps read more naturally as a relative distance
 * ("3 hours ago", "5 days ago"). Once a post is older than ~30 days the
 * relative form loses meaning, so we fall back to an absolute calendar date.
 */

const MS_PER_MINUTE = 60_000;
const MS_PER_HOUR = 60 * MS_PER_MINUTE;
const MS_PER_DAY = 24 * MS_PER_HOUR;

/** Threshold (in days) under which we prefer a relative "x ago" label. */
const RELATIVE_WINDOW_DAYS = 30;

export interface AbsoluteDateOptions {
  /** Month style for the absolute fallback. Defaults to 'short' (e.g. "Jan"). */
  month?: 'short' | 'long';
}

/** Absolute calendar date, e.g. "Jan 15, 2026" or "January 15, 2026". */
export function formatAbsoluteDate(
  iso: string,
  options: AbsoluteDateOptions = {},
): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: options.month ?? 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

/**
 * Human-friendly timestamp.
 *
 * - Under 1 minute → "just now"
 * - Under 1 hour   → "x minutes ago"
 * - Under 1 day    → "x hours ago"
 * - Under 30 days  → "x days ago"
 * - Otherwise      → absolute date (see {@link formatAbsoluteDate})
 *
 * Pluralization is handled so "1 hour ago" / "2 hours ago" both read well.
 */
export function relativeDate(iso: string, options: AbsoluteDateOptions = {}): string {
  const diff = Date.now() - new Date(iso).getTime();

  // Future or essentially-now timestamps collapse to "just now".
  if (diff < MS_PER_MINUTE) return 'just now';

  if (diff < MS_PER_HOUR) {
    const mins = Math.floor(diff / MS_PER_MINUTE);
    return `${mins} ${mins === 1 ? 'minute' : 'minutes'} ago`;
  }

  if (diff < MS_PER_DAY) {
    const hrs = Math.floor(diff / MS_PER_HOUR);
    return `${hrs} ${hrs === 1 ? 'hour' : 'hours'} ago`;
  }

  const days = Math.floor(diff / MS_PER_DAY);
  if (days < RELATIVE_WINDOW_DAYS) {
    return `${days} ${days === 1 ? 'day' : 'days'} ago`;
  }

  return formatAbsoluteDate(iso, options);
}
