import { vi } from 'vitest';

export interface MockRoute {
  /** Substring or regex matched against the request URL. */
  match: string | RegExp;
  /** Optional method filter. */
  method?: string;
  status?: number;
  /** JSON body to return. */
  json?: unknown;
}

/**
 * Install a mocked global `fetch` that resolves routes in order. The first
 * route whose `match` (and optional `method`) matches the request wins.
 * Returns the vi mock so tests can assert on calls.
 */
export function mockFetch(routes: MockRoute[]) {
  const fn = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === 'string' ? input : input.toString();
    const method = (init?.method ?? 'GET').toUpperCase();

    const route = routes.find((r) => {
      const matches =
        typeof r.match === 'string'
          ? url.includes(r.match)
          : r.match.test(url);
      const methodOk = !r.method || r.method.toUpperCase() === method;
      return matches && methodOk;
    });

    const status = route?.status ?? (route ? 200 : 404);
    const body = route?.json ?? { error: { code: 'not_found', message: 'no route' } };

    return {
      ok: status >= 200 && status < 300,
      status,
      headers: { get: () => '' },
      json: async () => body,
      text: async () => JSON.stringify(body),
    } as unknown as Response;
  });

  vi.stubGlobal('fetch', fn);
  return fn;
}
