import { act, renderHook, waitFor } from '@testing-library/react';
import type { ReactNode } from 'react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import { clearTokens, setTokens } from '../api/tokenStore';
import { AuthProvider, useAuth } from './AuthContext';

function wrapper({ children }: { children: ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

beforeEach(() => {
  localStorage.clear();
  clearTokens();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('AuthContext', () => {
  it('starts logged out by default', () => {
    mockFetch([]); // no /me call without tokens
    const { result } = renderHook(() => useAuth(), { wrapper });
    expect(result.current.isLoggedIn).toBe(false);
    expect(result.current.user).toBeNull();
  });

  it('logs a user in via the real auth API', async () => {
    mockFetch([
      {
        match: '/auth/login',
        method: 'POST',
        json: {
          user: {
            id: '1',
            email: 'a@b.com',
            display_name: 'Alice',
            role: 'resident',
            locale: 'en-SG',
          },
          access_token: 'tok',
          refresh_token: 'rt',
          expires_in: 900,
        },
      },
    ]);
    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.login('a@b.com', 'password123');
    });

    expect(result.current.isLoggedIn).toBe(true);
    expect(result.current.user?.name).toBe('Alice');
    expect(result.current.user?.email).toBe('a@b.com');
  });

  it('persists user to localStorage on login', async () => {
    mockFetch([
      {
        match: '/auth/login',
        method: 'POST',
        json: {
          user: {
            id: '1',
            email: 'a@b.com',
            display_name: 'Alice',
            role: 'resident',
            locale: 'en-SG',
          },
          access_token: 'tok',
          refresh_token: 'rt',
          expires_in: 900,
        },
      },
    ]);
    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.login('a@b.com', 'password123');
    });

    const stored = JSON.parse(localStorage.getItem('scamreg-user') ?? 'null');
    expect(stored?.name).toBe('Alice');
  });

  it('logs out and clears storage', async () => {
    mockFetch([
      {
        match: '/auth/login',
        method: 'POST',
        json: {
          user: { id: '1', email: 'a@b.com', display_name: 'Alice', role: 'resident', locale: 'en-SG' },
          access_token: 'tok',
          refresh_token: 'rt',
          expires_in: 900,
        },
      },
      { match: '/auth/logout', method: 'POST', status: 204, json: undefined },
    ]);
    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.login('a@b.com', 'password123');
    });
    await act(async () => {
      await result.current.logout();
    });

    expect(result.current.isLoggedIn).toBe(false);
    expect(localStorage.getItem('scamreg-user')).toBeNull();
  });

  it('restores a persisted session on mount by calling /me', async () => {
    // Pre-seed tokens so the context tries to restore.
    setTokens({ accessToken: 'tok', refreshToken: 'rt', expiresIn: 900 });
    localStorage.setItem(
      'scamreg-user',
      JSON.stringify({ id: '1', email: 'x@y.com', name: 'Bob' }),
    );

    mockFetch([
      {
        match: '/me',
        json: {
          id: '1',
          email: 'x@y.com',
          display_name: 'Bob',
          role: 'resident',
          locale: 'en-SG',
        },
      },
    ]);

    const { result } = renderHook(() => useAuth(), { wrapper });

    // Immediately has the persisted user.
    expect(result.current.user?.name).toBe('Bob');

    // After /me resolves, still valid.
    await waitFor(() => {
      expect(result.current.isLoggedIn).toBe(true);
      expect(result.current.isLoading).toBe(false);
    });
    expect(result.current.user?.name).toBe('Bob');
  });

  it('logs in as demo user without hitting the API', () => {
    mockFetch([]);
    const { result } = renderHook(() => useAuth(), { wrapper });

    act(() => {
      result.current.loginDemo({ name: 'Demo User', email: 'demo@scamreg.app' });
    });

    expect(result.current.isLoggedIn).toBe(true);
    expect(result.current.user?.name).toBe('Demo User');
  });
});
