/**
 * Auth token store.
 *
 * A tiny module-level store for the access/refresh tokens so the HTTP client
 * (api/client.ts) can read/refresh them without importing the React
 * AuthContext (which would create a circular dependency). The AuthContext is
 * the writer; the client is the reader + refresher.
 */
import type { AuthTokens } from '../types';

const STORAGE_KEY = 'scamreg-tokens';

let tokens: AuthTokens | null = loadTokens();

/** Subscribers notified whenever the tokens change (e.g. after refresh). */
type Listener = (tokens: AuthTokens | null) => void;
const listeners = new Set<Listener>();

function loadTokens(): AuthTokens | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as AuthTokens) : null;
  } catch {
    return null;
  }
}

export function getTokens(): AuthTokens | null {
  return tokens;
}

export function getAccessToken(): string | null {
  return tokens?.accessToken ?? null;
}

export function getRefreshToken(): string | null {
  return tokens?.refreshToken ?? null;
}

export function setTokens(next: AuthTokens | null): void {
  tokens = next;
  try {
    if (next) window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    else window.localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore storage errors */
  }
  for (const fn of listeners) fn(next);
}

export function clearTokens(): void {
  setTokens(null);
}

/** Subscribe to token changes. Returns an unsubscribe fn. */
export function subscribeTokens(fn: Listener): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}
