import { describe, expect, it } from 'vitest';
import { reportSchema, todayISO } from './reportSchema';

const base = {
  title: 'Fake bank SMS asking to verify',
  incidentDate: todayISO(),
  excerpt: 'A detailed description of what happened here, well over twenty chars.',
  tagId: 't-phishing',
  risk: 'high' as const,
};

describe('reportSchema', () => {
  it('accepts a valid report', () => {
    expect(reportSchema.safeParse(base).success).toBe(true);
  });

  it('requires a category', () => {
    const r = reportSchema.safeParse({ ...base, tagId: '' });
    expect(r.success).toBe(false);
  });

  it('rejects a short title', () => {
    expect(reportSchema.safeParse({ ...base, title: 'short' }).success).toBe(
      false,
    );
  });

  it('rejects a too-short description', () => {
    expect(reportSchema.safeParse({ ...base, excerpt: 'too short' }).success).toBe(
      false,
    );
  });

  it('rejects a future incident date', () => {
    const future = '2999-01-01';
    const r = reportSchema.safeParse({ ...base, incidentDate: future });
    expect(r.success).toBe(false);
    if (!r.success) {
      expect(r.error.issues.some((i) => /future/i.test(i.message))).toBe(true);
    }
  });

  it('requires an incident date', () => {
    expect(
      reportSchema.safeParse({ ...base, incidentDate: '' }).success,
    ).toBe(false);
  });
});
