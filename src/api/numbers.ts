import { parsePhone } from '../lib/phone';
import type {
  NumberCheckResult,
  NumberReportKind,
  NumberStatus,
} from '../types';
import { apiFetch, delay, USE_MOCK } from './client';

/**
 * Normalize a number to its canonical DIGITS-ONLY key so that "+X" and "X"
 * resolve to the same registry entry. Throws on invalid input.
 */
export function normalizeNumber(input: string): string {
  const parsed = parsePhone(input);
  if (!parsed.valid) {
    throw new Error(parsed.error);
  }
  return parsed.key;
}

/** Derive a status from the report counts. */
function deriveStatus(scam: number, trusted: number): NumberStatus {
  if (scam === 0 && trusted === 0) return 'unknown';
  if (scam > trusted) return 'scam';
  if (trusted > scam) return 'trusted';
  // Tie with at least one report each — treat as scam (safer default).
  return 'scam';
}

// In-memory seed store so reports actually change counts during the demo.
// Keyed by canonical digits-only form.
interface Entry {
  scam: number;
  trusted: number;
  lastReportedAt: string | null;
}

// Tracks which accounts have already reported which numbers, to enforce
// "one report per number per account". Key: `${userId}::${numberKey}`.
// A real backend would enforce this with a unique constraint.
const REPORTED_BY = new Set<string>();
const reportKey = (userId: string, numberKey: string) =>
  `${userId}::${numberKey}`;

/** Has this account already reported this number? */
export function hasReported(userId: string, input: string): boolean {
  const parsed = parsePhone(input);
  if (!parsed.valid) return false;
  return REPORTED_BY.has(reportKey(userId, parsed.key));
}
function daysAgo(n: number): string {
  return new Date(Date.now() - n * 24 * 3600 * 1000).toISOString();
}

const MOCK_NUMBERS: Record<string, Entry> = {
  '18005551234': { scam: 47, trusted: 2, lastReportedAt: daysAgo(1) },
  '441632960000': { scam: 0, trusted: 18, lastReportedAt: daysAgo(3) },
  '12025550142': { scam: 12, trusted: 11, lastReportedAt: daysAgo(5) },
  '61491570156': { scam: 3, trusted: 0, lastReportedAt: daysAgo(8) },
};

function toResult(display: string, entry: Entry): NumberCheckResult {
  const total = entry.scam + entry.trusted;
  return {
    number: display,
    status: deriveStatus(entry.scam, entry.trusted),
    counts: { scam: entry.scam, trusted: entry.trusted, total },
    lastReportedAt: entry.lastReportedAt,
  };
}

/**
 * Look up a phone number in the scam registry. Rejects invalid input.
 *
 * Real API integration: replace the mock branch, e.g.
 *   return apiFetch<NumberCheckResult>(`/numbers/${key}`);
 */
export async function lookupNumber(input: string): Promise<NumberCheckResult> {
  const parsed = parsePhone(input);
  if (!parsed.valid) {
    return Promise.reject(new Error(parsed.error));
  }

  if (USE_MOCK) {
    const entry = MOCK_NUMBERS[parsed.key] ?? {
      scam: 0,
      trusted: 0,
      lastReportedAt: null,
    };
    return delay(toResult(parsed.display, entry), 500);
  }
  return apiFetch<NumberCheckResult>(
    `/numbers/${encodeURIComponent(parsed.key)}`,
  );
}

/**
 * File a report against a number. Returns the updated result.
 *
 * The UI only calls this for logged-in users; the real backend should also
 * enforce authentication.
 */
export async function reportNumber(
  input: string,
  kind: NumberReportKind,
  userId: string | null | undefined,
): Promise<NumberCheckResult> {
  // Reporting requires a logged-in account.
  if (!userId) {
    return Promise.reject(new Error('You must be logged in to report.'));
  }

  const parsed = parsePhone(input);
  if (!parsed.valid) {
    return Promise.reject(new Error(parsed.error));
  }

  // One report per number per account.
  const key = reportKey(userId, parsed.key);
  if (REPORTED_BY.has(key)) {
    return Promise.reject(
      new Error('You have already reported this number.'),
    );
  }

  if (USE_MOCK) {
    const entry = MOCK_NUMBERS[parsed.key] ?? {
      scam: 0,
      trusted: 0,
      lastReportedAt: null,
    };
    if (kind === 'scam') entry.scam += 1;
    else entry.trusted += 1;
    entry.lastReportedAt = new Date().toISOString();
    MOCK_NUMBERS[parsed.key] = entry;
    REPORTED_BY.add(key);
    return delay(toResult(parsed.display, entry), 400);
  }

  const result = await apiFetch<NumberCheckResult>(
    `/numbers/${encodeURIComponent(parsed.key)}/report`,
    {
      method: 'POST',
      body: JSON.stringify({ kind }),
    },
  );
  REPORTED_BY.add(key);
  return result;
}
