import type { Comment } from '../types';

/**
 * Merges comments fetched from the API with comments announced live over the
 * post's SSE stream.
 *
 * - De-duplicates by comment id. The same comment can arrive twice: once as a
 *   `comment_created` event and once again in the `grok_replied` event, and it
 *   may also be present in a (re)fetched page.
 * - Keeps the fetched copy of a comment when both exist, since the fetched
 *   payload is the canonical one.
 * - Orders the result oldest-first by `createdAt`, matching the API's own
 *   ordering, so a live reply lands in the right place in the thread.
 */
export function mergeComments(
  fetched: readonly Comment[],
  live: readonly Comment[] = [],
): Comment[] {
  const byId = new Map<string, Comment>();
  for (const c of fetched) byId.set(c.id, c);
  for (const c of live) {
    if (!byId.has(c.id)) byId.set(c.id, c);
  }

  // Track insertion order so comments sharing a timestamp keep a stable order:
  // fetched comments first (in API order), then live-only ones (arrival order).
  const order = new Map<string, number>();
  let next = 0;
  for (const c of fetched) if (!order.has(c.id)) order.set(c.id, next++);
  for (const c of live) if (!order.has(c.id)) order.set(c.id, next++);

  return [...byId.values()].sort((a, b) => {
    const diff = Date.parse(a.createdAt) - Date.parse(b.createdAt);
    if (!Number.isNaN(diff) && diff !== 0) return diff;
    return (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0);
  });
}
