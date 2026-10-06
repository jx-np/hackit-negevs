/**
 * Central HTTP client.
 *
 * - Base URL from VITE_API_BASE_URL (required); all paths are relative to
 *   `/api/v1`.
 * - Injects `Authorization: Bearer <token>` when a token exists.
 * - Adds the `ngrok-skip-browser-warning` header (required for ngrok tunnels).
 * - On a 401 response, attempts a single token refresh and retries.
 * - Parses the backend's standard error body (`{ error: { code, message, fields } }`).
 */
import type { ApiErrorBody, ApiRefreshResponse } from '../types';
import { clearTokens, getAccessToken, getRefreshToken, setTokens } from './tokenStore';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const RAW_BASE = import.meta.env.VITE_API_BASE_URL ?? '';

/**
 * API prefix. In development, requests go to the same origin (e.g.
 * `/api/v1/...`) and Vite's dev-server proxy forwards them to the real
 * backend — this avoids CORS issues. In production, the full base URL is
 * used so the built app can talk directly to the backend.
 */
export const API_BASE_URL = import.meta.env.DEV
  ? '/api/v1' // proxied by Vite dev server
  : RAW_BASE
    ? `${RAW_BASE.replace(/\/+$/, '')}/api/v1`
    : '/api/v1'; // fallback: assume same-origin in prod too

/**
 * True when no base URL is configured — falls back to mock data.
 * In production, this should never be true.
 */
export const USE_MOCK = !RAW_BASE;

// ---------------------------------------------------------------------------
// Structured API error
// ---------------------------------------------------------------------------

export class ApiError extends Error {
  status: number;
  code: string;
  fields: Record<string, string>;
  requestId: string;

  constructor(
    status: number,
    code: string,
    message: string,
    fields: Record<string, string> = {},
    requestId = '',
  ) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.fields = fields;
    this.requestId = requestId;
  }
}

// ---------------------------------------------------------------------------
// Token refresh (single-inflight)
// ---------------------------------------------------------------------------

let refreshPromise: Promise<boolean> | null = null;

async function tryRefresh(): Promise<boolean> {
  const rt = getRefreshToken();
  if (!rt) return false;

  try {
    const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: JSON.stringify({ refresh_token: rt }),
    });
    if (!res.ok) {
      clearTokens();
      return false;
    }
    const data = (await res.json()) as ApiRefreshResponse;
    setTokens({
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in,
    });
    return true;
  } catch {
    clearTokens();
    return false;
  }
}

function refreshOnce(): Promise<boolean> {
  if (!refreshPromise) {
    refreshPromise = tryRefresh().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

// ---------------------------------------------------------------------------
// Core fetch helper
// ---------------------------------------------------------------------------

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
  /** Set to true for auth endpoints that should not retry on 401. */
  skipRefresh = false,
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    ...(options.headers as Record<string, string> | undefined),
  };

  const token = getAccessToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  // 204 No Content — no body to parse.
  if (res.status === 204) return undefined as unknown as T;

  // 401 → try to refresh once and retry.
  if (res.status === 401 && !skipRefresh) {
    const refreshed = await refreshOnce();
    if (refreshed) {
      return apiFetch<T>(path, options, true);
    }
    // Refresh failed — fall through to throw ApiError.
  }

  if (!res.ok) {
    let body: ApiErrorBody | undefined;
    try {
      body = (await res.json()) as ApiErrorBody;
    } catch {
      /* ignore parse failure */
    }
    throw new ApiError(
      res.status,
      body?.error?.code ?? 'unknown',
      body?.error?.message ?? `Request failed (${res.status})`,
      body?.error?.fields ?? {},
      body?.request_id ?? res.headers.get('X-Request-Id') ?? '',
    );
  }

  return res.json() as Promise<T>;
}

/** Small helper to simulate network latency for mock responses. */
export function delay<T>(value: T, ms = 500): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}
