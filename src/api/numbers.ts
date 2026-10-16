/**
 * Phone number trust-score API.
 *
 * Uses GET /detection/phone-number/trust-score?phone_number=... which returns
 * { phone_number, trust_score, rating, report_count, known, classification }.
 * Reporting a number uses POST /detection/phone-number/report (auth required,
 * one report per number per window).
 *
 * The UI maps `trust_score` + `rating` into a status verdict (scam / trusted /
 * unknown) matching the existing NumberCheckResult shape.
 */
import { parsePhone } from '../lib/phone';
import type { ApiTrustScore, NumberCheckResult, NumberStatus } from '../types';
import { apiFetch } from './client';

export function normalizeNumber(input: string): string {
  const parsed = parsePhone(input);
  if (!parsed.valid) throw new Error(parsed.error);
  return parsed.key;
}

function ratingToStatus(rating: string): NumberStatus {
  switch (rating) {
    case 'high_risk':
      return 'scam';
    case 'trusted':
      return 'trusted';
    default:
      return 'unknown';
  }
}

function mapTrustScore(raw: ApiTrustScore, display: string): NumberCheckResult {
  return {
    number: display,
    status: ratingToStatus(raw.rating),
    trustScore: raw.trust_score,
    rating: raw.rating,
    reportCount: raw.report_count,
    known: raw.known,
    classification: raw.classification ?? '',
  };
}

/**
 * Look up a phone number's trust score.
 * Accepts any format the parsePhone helper accepts.
 */
export async function lookupNumber(input: string): Promise<NumberCheckResult> {
  const parsed = parsePhone(input);
  if (!parsed.valid) return Promise.reject(new Error(parsed.error));

  const params = new URLSearchParams();
  params.set('phone_number', parsed.display); // send with "+" if present
  const raw = await apiFetch<ApiTrustScore>(
    `/detection/phone-number/trust-score?${params.toString()}`,
  );
  return mapTrustScore(raw, parsed.display);
}
