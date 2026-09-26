import { describe, expect, it } from 'vitest';
import { lookupNumber, normalizeNumber, reportNumber } from './numbers';

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

describe('lookupNumber — + and non-+ consistency', () => {
  it('returns the same registry entry with or without a leading +', async () => {
    const withPlus = await lookupNumber('+18005551234');
    const withoutPlus = await lookupNumber('18005551234');
    expect(withPlus.status).toBe(withoutPlus.status);
    expect(withPlus.counts.total).toBe(withoutPlus.counts.total);
  });

  it('rejects an invalid number', async () => {
    await expect(lookupNumber('nope')).rejects.toThrow();
  });
});

describe('lookupNumber (mock mode)', () => {
  it('returns "scam" for a heavily scam-reported number', async () => {
    const res = await lookupNumber('+1 800 555 1234');
    expect(res.number).toBe('+18005551234');
    expect(res.status).toBe('scam');
    expect(res.counts.scam).toBeGreaterThan(res.counts.trusted);
    expect(res.counts.total).toBe(res.counts.scam + res.counts.trusted);
  });

  it('returns "trusted" for a mostly-trusted number', async () => {
    const res = await lookupNumber('+441632960000');
    expect(res.status).toBe('trusted');
    expect(res.counts.trusted).toBeGreaterThan(res.counts.scam);
  });

  it('returns "unknown" with zero counts for an unseen number', async () => {
    const res = await lookupNumber('+19998887766');
    expect(res.status).toBe('unknown');
    expect(res.counts.total).toBe(0);
    expect(res.lastReportedAt).toBeNull();
  });
});

describe('reportNumber (mock mode)', () => {
  it('increments the scam count and can flip an unknown number to scam', async () => {
    const number = '+15550001111';
    const before = await lookupNumber(number);
    expect(before.status).toBe('unknown');

    const after = await reportNumber(number, 'scam');
    expect(after.counts.scam).toBe(before.counts.scam + 1);
    expect(after.status).toBe('scam');
    expect(after.lastReportedAt).not.toBeNull();
  });

  it('increments the trusted count', async () => {
    const number = '+15550002222';
    const before = await lookupNumber(number);
    const after = await reportNumber(number, 'trusted');
    expect(after.counts.trusted).toBe(before.counts.trusted + 1);
    expect(after.status).toBe('trusted');
  });
});
