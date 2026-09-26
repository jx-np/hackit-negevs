import { describe, expect, it } from 'vitest';
import { isValidPhone, parsePhone } from './phone';

describe('parsePhone — validation', () => {
  it('rejects empty input', () => {
    expect(parsePhone('   ').valid).toBe(false);
  });

  it('rejects letters / garbage', () => {
    expect(parsePhone('call-me').valid).toBe(false);
    expect(parsePhone('abc123').valid).toBe(false);
  });

  it('rejects a "+" that is not leading', () => {
    expect(parsePhone('123+456').valid).toBe(false);
  });

  it('rejects too-short numbers', () => {
    expect(parsePhone('12345').valid).toBe(false);
  });

  it('rejects too-long numbers (> 15 digits)', () => {
    expect(parsePhone('1234567890123456').valid).toBe(false);
  });

  it('accepts a plain digit string', () => {
    expect(isValidPhone('8005551234')).toBe(true);
  });

  it('accepts formatting characters (spaces, dashes, parens, dots)', () => {
    expect(isValidPhone('+1 (800) 555-1234')).toBe(true);
    expect(isValidPhone('800.555.1234')).toBe(true);
  });
});

describe('parsePhone — normalization (+ and non-+ consistency)', () => {
  it('produces the same canonical key with or without a leading +', () => {
    const a = parsePhone('+18005551234');
    const b = parsePhone('18005551234');
    const c = parsePhone('+1 (800) 555-1234');
    expect(a.key).toBe('18005551234');
    expect(b.key).toBe('18005551234');
    expect(c.key).toBe('18005551234');
  });

  it('keeps a + in the display form when provided', () => {
    expect(parsePhone('+441632960000').display).toBe('+441632960000');
  });

  it('adds a + to the display form for long (international) numbers', () => {
    // 11 digits, no plus typed -> display gets a + by convention
    expect(parsePhone('18005551234').display).toBe('+18005551234');
  });

  it('leaves short national numbers without a + in display', () => {
    expect(parsePhone('8005551234').display).toBe('8005551234');
  });
});
