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

/** True when no backend base URL is configured (dev proxy target missing). */
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
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new Event('scamreg:session-expired'));
      }
      return false;
    }
    const data = (await res.json()) as ApiRefreshResponse;
    setTokens({
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in,
    });
    // The new access token may carry a role that changed since login (role
    // changes revoke refresh sessions, but the 15-minute access-token window
    // can overlap). Ask the auth layer to re-read /me so the UI/permissions
    // never rely on a permanently cached role.
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('scamreg:session-refreshed'));
    }
    return true;
  } catch {
    clearTokens();
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('scamreg:session-expired'));
    }
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
  const isFormData =
    typeof FormData !== 'undefined' && options.body instanceof FormData;
  const headers: Record<string, string> = {
    // Let the browser set the multipart boundary for FormData bodies.
    ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
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
    throw await errorFromResponse(res);
  }

  return res.json() as Promise<T>;
}

/**
 * Fetches raw bytes (e.g. an image) with the same auth/refresh handling as
 * `apiFetch`. Use for endpoints whose body is not JSON.
 */
export async function apiFetchBlob(
  path: string,
  options: RequestInit = {},
  skipRefresh = false,
): Promise<Blob> {
  const headers: Record<string, string> = {
    'ngrok-skip-browser-warning': 'true',
    ...(options.headers as Record<string, string> | undefined),
  };

  const token = getAccessToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });

  if (res.status === 401 && !skipRefresh) {
    const refreshed = await refreshOnce();
    if (refreshed) return apiFetchBlob(path, options, true);
  }

  if (!res.ok) {
    throw await errorFromResponse(res);
  }

  return res.blob();
}

/** Build an ApiError from a non-OK response. */
async function errorFromResponse(res: Response): Promise<ApiError> {
  let body: ApiErrorBody | undefined;
  try {
    body = (await res.json()) as ApiErrorBody;
  } catch {
    /* ignore parse failure */
  }
  return new ApiError(
    res.status,
    body?.error?.code ?? 'unknown',
    body?.error?.message ?? `Request failed (${res.status})`,
    body?.error?.fields ?? {},
    body?.request_id ?? res.headers.get('X-Request-Id') ?? '',
  );
}

/**
 * Resolve an API-relative asset path (e.g. the `redacted_image_urls` entries,
 * which are absolute paths like `/api/v1/community/posts/12/images/0`) into a
 * URL the browser can load.
 *
 * In development the path is already served by the same origin (Vite proxies
 * `/api`), so it is returned untouched; in production the configured backend
 * origin is prefixed.
 */
export function apiAssetUrl(path: string): string {
  if (/^https?:\/\//i.test(path)) return path;
  const base = import.meta.env.DEV ? '' : RAW_BASE.replace(/\/+$/, '');
  return `${base}${path.startsWith('/') ? '' : '/'}${path}`;
}

/**
 * Small helper to simulate network latency for mock responses.
 *
 * No API module currently has a mock branch (all talk to the backend), so this
 * exists only for future scaffolding and tests.
 */
export function delay<T>(value: T, ms = 500): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}
