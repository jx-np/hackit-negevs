import { act, renderHook } from '@testing-library/react';
import type { ReactNode } from 'react';
import { beforeEach, describe, expect, it } from 'vitest';
import { AuthProvider, useAuth } from './AuthContext';

function wrapper({ children }: { children: ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

describe('AuthContext', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('starts logged out by default', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });
    expect(result.current.isLoggedIn).toBe(false);
    expect(result.current.user).toBeNull();
  });

  it('logs a user in and exposes their details', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });
    act(() => result.current.login({ email: 'a@b.com', name: 'Alice' }));

    expect(result.current.isLoggedIn).toBe(true);
    expect(result.current.user?.name).toBe('Alice');
    expect(result.current.user?.email).toBe('a@b.com');
  });

  it('persists the logged-in user to localStorage', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });
    act(() => result.current.login({ email: 'a@b.com', name: 'Alice' }));

    const stored = JSON.parse(localStorage.getItem('scamreg-auth') ?? 'null');
    expect(stored?.name).toBe('Alice');
  });

  it('logs out and clears storage', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });
    act(() => result.current.login({ name: 'Alice' }));
    act(() => result.current.logout());

    expect(result.current.isLoggedIn).toBe(false);
    expect(localStorage.getItem('scamreg-auth')).toBeNull();
  });

  it('restores a persisted session on mount', () => {
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'x@y.com', name: 'Bob' }),
    );
    const { result } = renderHook(() => useAuth(), { wrapper });
    expect(result.current.isLoggedIn).toBe(true);
    expect(result.current.user?.name).toBe('Bob');
  });
});
