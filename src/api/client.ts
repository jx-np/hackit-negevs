/**
 * Central HTTP client. When the real API is provided, set VITE_API_BASE_URL
 * in a .env file and flip USE_MOCK to false. Until then the api/* modules
 * fall back to mock data so the UI is fully functional.
 */
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';

/** Toggle: use bundled mock data instead of hitting a real backend. */
export const USE_MOCK = !API_BASE_URL;

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
    ...options,
  });

  if (!res.ok) {
    const message = await res.text().catch(() => res.statusText);
    throw new Error(`Request failed (${res.status}): ${message}`);
  }

  return res.json() as Promise<T>;
}

/** Small helper to simulate network latency for mock responses. */
export function delay<T>(value: T, ms = 500): Promise<T> {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}
