import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import { lookupNumber, normalizeNumber } from './numbers';
import type { ApiTrustScore } from '../types';

afterEach(() => {
  vi.unstubAllGlobals();
});

const trustScore = (over: Partial<ApiTrustScore> = {}): ApiTrustScore => ({
  phone_number: '+18005551234',
  trust_score: 60,
  rating: 'unknown',
  report_count: 0,
  known: false,
  ...over,
});

describe('normalizeNumber', () => {
  it('returns the canonical digits-only key (ignoring + and formatting)', () => {
    expect(normalizeNumber('+1 (800) 555-1234')).toBe('18005551234');
    expect(normalizeNumber('  1.800.555.1234 ')).toBe('18005551234');
  });

  it('maps "+X" and "X" to the same key', () => {
    expect(normalizeNumber('+441632960000')).toBe(
      normalizeNumber('441632960000'),
    );
  });

  it('throws on invalid input', () => {
    expect(() => normalizeNumber('call-me')).toThrow();
    expect(() => normalizeNumber('123')).toThrow();
  });
});

describe('lookupNumber (trust-score API)', () => {
  it('rejects an invalid number without calling the API', async () => {
    const fetchMock = mockFetch([]);
    await expect(lookupNumber('nope')).rejects.toThrow();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('calls the trust-score endpoint with the phone_number query param', async () => {
    const fetchMock = mockFetch([
      { match: '/detection/phone-number/trust-score', json: trustScore() },
    ]);
    await lookupNumber('+1 800 555 1234');
    const url = fetchMock.mock.calls[0][0] as string;
    expect(url).toContain('/detection/phone-number/trust-score');
    expect(url).toContain('phone_number=');
  });

  it('maps a high_risk rating to the "scam" status', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({ trust_score: 18, rating: 'high_risk', report_count: 42, known: true }),
      },
    ]);
    const res = await lookupNumber('+18005551234');
    expect(res.status).toBe('scam');
    expect(res.trustScore).toBe(18);
    expect(res.reportCount).toBe(42);
    expect(res.known).toBe(true);
  });

  it('maps a trusted rating to the "trusted" status', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({ trust_score: 90, rating: 'trusted', known: true }),
      },
    ]);
    const res = await lookupNumber('+441632960000');
    expect(res.status).toBe('trusted');
    expect(res.trustScore).toBe(90);
  });

  it('maps an unknown rating (default score) to the "unknown" status', async () => {
    mockFetch([{ match: '/trust-score', json: trustScore() }]);
    const res = await lookupNumber('+19998887766');
    expect(res.status).toBe('unknown');
    expect(res.trustScore).toBe(60);
    expect(res.known).toBe(false);
    expect(res.reportCount).toBe(0);
  });

  it('surfaces the backend classification label', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({
          trust_score: 18,
          rating: 'high_risk',
          report_count: 42,
          known: true,
          classification: 'scam',
        }),
      },
    ]);
    const res = await lookupNumber('+18005551234');
    expect(res.classification).toBe('scam');
  });

  it('defaults classification to an empty string when absent', async () => {
    mockFetch([{ match: '/trust-score', json: trustScore() }]);
    const res = await lookupNumber('+18005551234');
    expect(res.classification).toBe('');
  });

  it('sends the same number consistently with or without a leading +', async () => {
    const fetchMock = mockFetch([
      { match: '/trust-score', json: trustScore() },
    ]);
    await lookupNumber('+18005551234');
    await lookupNumber('18005551234');
    const url1 = fetchMock.mock.calls[0][0] as string;
    const url2 = fetchMock.mock.calls[1][0] as string;
    // Both lookups target the trust-score endpoint and encode the digits.
    expect(url1).toContain('8005551234');
    expect(url2).toContain('8005551234');
  });
});
