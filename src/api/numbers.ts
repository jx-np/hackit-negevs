import type {
  NumberCheckResult,
  NumberReportKind,
  NumberStatus,
} from '../types';
import { apiFetch, delay, USE_MOCK } from './client';

/** Normalize a number for lookup: keep a leading + and digits only. */
export function normalizeNumber(input: string): string {
  const trimmed = input.trim();
  const plus = trimmed.startsWith('+') ? '+' : '';
  return plus + trimmed.replace(/[^\d]/g, '');
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
interface Entry {
  scam: number;
  trusted: number;
  lastReportedAt: string | null;
}
function daysAgo(n: number): string {
  return new Date(Date.now() - n * 24 * 3600 * 1000).toISOString();
}

const MOCK_NUMBERS: Record<string, Entry> = {
  '+18005551234': { scam: 47, trusted: 2, lastReportedAt: daysAgo(1) },
  '+441632960000': { scam: 0, trusted: 18, lastReportedAt: daysAgo(3) },
  '+12025550142': { scam: 12, trusted: 11, lastReportedAt: daysAgo(5) },
  '+61491570156': { scam: 3, trusted: 0, lastReportedAt: daysAgo(8) },
};

function toResult(number: string, entry: Entry): NumberCheckResult {
  const total = entry.scam + entry.trusted;
  return {
    number,
    status: deriveStatus(entry.scam, entry.trusted),
    counts: { scam: entry.scam, trusted: entry.trusted, total },
    lastReportedAt: entry.lastReportedAt,
  };
}

/**
 * Look up a phone number in the scam registry.
 *
 * Real API integration: replace the mock branch, e.g.
 *   return apiFetch<NumberCheckResult>(`/numbers/${encodeURIComponent(n)}`);
 */
export async function lookupNumber(input: string): Promise<NumberCheckResult> {
  const n = normalizeNumber(input);
  if (USE_MOCK) {
    const entry = MOCK_NUMBERS[n] ?? {
      scam: 0,
      trusted: 0,
      lastReportedAt: null,
    };
    return delay(toResult(n, entry), 500);
  }
  return apiFetch<NumberCheckResult>(`/numbers/${encodeURIComponent(n)}`);
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
): Promise<NumberCheckResult> {
  const n = normalizeNumber(input);
  if (USE_MOCK) {
    const entry = MOCK_NUMBERS[n] ?? {
      scam: 0,
      trusted: 0,
      lastReportedAt: null,
    };
    if (kind === 'scam') entry.scam += 1;
    else entry.trusted += 1;
    entry.lastReportedAt = new Date().toISOString();
    MOCK_NUMBERS[n] = entry;
    return delay(toResult(n, entry), 400);
  }
  return apiFetch<NumberCheckResult>(`/numbers/${encodeURIComponent(n)}/report`, {
    method: 'POST',
    body: JSON.stringify({ kind }),
  });
}
