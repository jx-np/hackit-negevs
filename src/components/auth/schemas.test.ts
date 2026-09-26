import { describe, expect, it } from 'vitest';
import { loginSchema, signupSchema } from './schemas';

describe('loginSchema', () => {
  it('accepts a valid email and password', () => {
    const result = loginSchema.safeParse({
      email: 'user@example.com',
      password: 'secret',
    });
    expect(result.success).toBe(true);
  });

  it('rejects an invalid email', () => {
    const result = loginSchema.safeParse({
      email: 'not-an-email',
      password: 'secret',
    });
    expect(result.success).toBe(false);
  });

  it('rejects an empty password', () => {
    const result = loginSchema.safeParse({
      email: 'user@example.com',
      password: '',
    });
    expect(result.success).toBe(false);
  });
});

describe('signupSchema', () => {
  const valid = {
    name: 'Ada Lovelace',
    email: 'ada@example.com',
    password: 'abc12345',
    confirmPassword: 'abc12345',
  };

  it('accepts a fully valid signup', () => {
    expect(signupSchema.safeParse(valid).success).toBe(true);
  });

  it('rejects a short name', () => {
    const result = signupSchema.safeParse({ ...valid, name: 'A' });
    expect(result.success).toBe(false);
  });

  it('rejects a password without a number', () => {
    const result = signupSchema.safeParse({
      ...valid,
      password: 'abcdefgh',
      confirmPassword: 'abcdefgh',
    });
    expect(result.success).toBe(false);
  });

  it('rejects a password shorter than 8 characters', () => {
    const result = signupSchema.safeParse({
      ...valid,
      password: 'abc123',
      confirmPassword: 'abc123',
    });
    expect(result.success).toBe(false);
  });

  it('rejects mismatched passwords with a confirmPassword error', () => {
    const result = signupSchema.safeParse({
      ...valid,
      confirmPassword: 'different1',
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      const paths = result.error.issues.map((i) => i.path.join('.'));
      expect(paths).toContain('confirmPassword');
    }
  });
});
