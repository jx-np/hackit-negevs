import { describe, expect, it } from 'vitest';
import {
  hasReported,
  lookupNumber,
  normalizeNumber,
  reportNumber,
} from './numbers';

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

    const after = await reportNumber(number, 'scam', 'user-a');
    expect(after.counts.scam).toBe(before.counts.scam + 1);
    expect(after.status).toBe('scam');
    expect(after.lastReportedAt).not.toBeNull();
  });

  it('increments the trusted count', async () => {
    const number = '+15550002222';
    const before = await lookupNumber(number);
    const after = await reportNumber(number, 'trusted', 'user-a');
    expect(after.counts.trusted).toBe(before.counts.trusted + 1);
    expect(after.status).toBe('trusted');
  });
});

describe('reportNumber — auth + one-report-per-account', () => {
  it('rejects a report with no logged-in user', async () => {
    await expect(reportNumber('+15550003333', 'scam', null)).rejects.toThrow(
      /logged in/i,
    );
  });

  it('rejects a second report of the same number by the same account', async () => {
    const number = '+15550004444';
    await reportNumber(number, 'scam', 'user-dup');
    await expect(
      reportNumber(number, 'scam', 'user-dup'),
    ).rejects.toThrow(/already reported/i);
  });

  it('treats + and non-+ as the same number for the per-account limit', async () => {
    await reportNumber('+15550005555', 'scam', 'user-plus');
    await expect(
      reportNumber('15550005555', 'trusted', 'user-plus'),
    ).rejects.toThrow(/already reported/i);
  });

  it('allows a different account to report the same number', async () => {
    const number = '+15550006666';
    await reportNumber(number, 'scam', 'user-1');
    const second = await reportNumber(number, 'scam', 'user-2');
    // Two distinct accounts -> two scam reports counted.
    expect(second.counts.scam).toBe(2);
  });

  it('hasReported reflects whether an account reported a number', async () => {
    const number = '+15550007777';
    expect(hasReported('user-hr', number)).toBe(false);
    await reportNumber(number, 'scam', 'user-hr');
    expect(hasReported('user-hr', number)).toBe(true);
    // + / non-+ equivalence
    expect(hasReported('user-hr', '15550007777')).toBe(true);
  });
});
