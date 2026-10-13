import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { formatAbsoluteDate, relativeDate } from './date';

/** Fixed "now" so relative calculations are deterministic. */
const NOW = new Date('2026-10-11T12:00:00.000Z');

/** Build an ISO string offset from NOW by the given milliseconds (negative = past). */
function isoFromNow(offsetMs: number): string {
  return new Date(NOW.getTime() + offsetMs).toISOString();
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

describe('relativeDate', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows "just now" for timestamps under a minute old', () => {
    expect(relativeDate(isoFromNow(-30 * 1000))).toBe('just now');
  });

  it('shows minutes with correct pluralization', () => {
    expect(relativeDate(isoFromNow(-1 * MINUTE))).toBe('1 minute ago');
    expect(relativeDate(isoFromNow(-5 * MINUTE))).toBe('5 minutes ago');
  });

  it('shows hours with correct pluralization', () => {
    expect(relativeDate(isoFromNow(-1 * HOUR))).toBe('1 hour ago');
    expect(relativeDate(isoFromNow(-3 * HOUR))).toBe('3 hours ago');
  });

  it('shows days with correct pluralization', () => {
    expect(relativeDate(isoFromNow(-1 * DAY))).toBe('1 day ago');
    expect(relativeDate(isoFromNow(-5 * DAY))).toBe('5 days ago');
  });

  it('still uses relative form just under the 30-day window', () => {
    expect(relativeDate(isoFromNow(-29 * DAY))).toBe('29 days ago');
  });

  it('falls back to an absolute date at/after 30 days', () => {
    const iso = isoFromNow(-30 * DAY);
    expect(relativeDate(iso)).toBe(formatAbsoluteDate(iso));
    expect(relativeDate(iso)).not.toMatch(/ago/);
  });

  it('falls back to an absolute date for very old timestamps', () => {
    const iso = isoFromNow(-200 * DAY);
    expect(relativeDate(iso)).toBe(formatAbsoluteDate(iso));
  });
});

describe('formatAbsoluteDate', () => {
  it('defaults to a short month', () => {
    expect(formatAbsoluteDate('2026-01-15T12:00:00.000Z')).toMatch(/Jan/);
  });

  it('supports a long month', () => {
    expect(formatAbsoluteDate('2026-01-15T12:00:00.000Z', { month: 'long' })).toMatch(
      /January/,
    );
  });
});
