/**
 * Live discussion stream (Server-Sent Events) API.
 *
 * The backend exposes `GET /community/posts/{id}/sse`, a Server-Sent Events
 * stream of live discussion activity for one publicly visible post: new
 * comments and the AI assistant's (`@help`) progress.
 *
 * `EventSource` cannot send an `Authorization` header, so the endpoint only
 * ever streams already-public, server-scrubbed data and never needs a token.
 */
import { API_BASE_URL } from './client';

/**
 * Absolute URL of a post's live discussion stream.
 *
 * In development the Vite dev server proxies `/api` to the backend, so the
 * relative path keeps the browser same-origin (no CORS preflight). In
 * production the configured backend origin is prefixed.
 */
export function getPostStreamUrl(postId: string): string {
  return `${API_BASE_URL}/community/posts/${encodeURIComponent(postId)}/sse`;
}
