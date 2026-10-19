import { describe, expect, it } from 'vitest';
import { mergeComments } from './comments';
import type { Comment } from '../types';

function comment(id: string, createdAt: string, extra: Partial<Comment> = {}): Comment {
  return {
    id,
    parentId: null,
    authorId: 'u1',
    authorLabel: 'Alex',
    isBot: false,
    body: `body ${id}`,
    status: 'visible',
    createdAt,
    updatedAt: createdAt,
    ...extra,
  };
}

describe('mergeComments', () => {
  it('returns the fetched comments when there are no live ones', () => {
    const fetched = [comment('1', '2026-09-29T09:10:00Z')];
    expect(mergeComments(fetched)).toEqual(fetched);
  });

  it('appends live comments that are not in the fetched set', () => {
    const fetched = [comment('1', '2026-09-29T09:10:00Z')];
    const live = [comment('2', '2026-09-29T09:20:00Z', { isBot: true })];

    const merged = mergeComments(fetched, live);

    expect(merged.map((c) => c.id)).toEqual(['1', '2']);
    expect(merged[1].isBot).toBe(true);
  });

  it('de-duplicates a comment that arrives both live and fetched', () => {
    const fetched = [comment('1', '2026-09-29T09:10:00Z', { body: 'canonical' })];
    const live = [comment('1', '2026-09-29T09:10:00Z', { body: 'duplicate' })];

    const merged = mergeComments(fetched, live);

    expect(merged).toHaveLength(1);
    // The fetched copy wins — it is the canonical payload.
    expect(merged[0].body).toBe('canonical');
  });

  it('orders the result oldest-first by creation time', () => {
    const fetched = [comment('1', '2026-09-29T09:10:00Z')];
    const live = [comment('3', '2026-09-29T09:30:00Z')];

    const merged = mergeComments(fetched, [
      comment('2', '2026-09-29T09:20:00Z'),
      ...live,
    ]);

    expect(merged.map((c) => c.id)).toEqual(['1', '2', '3']);
  });

  it('keeps a stable order for comments sharing a timestamp', () => {
    const fetched = [comment('1', '2026-09-29T09:10:00Z')];
    const live = [comment('2', '2026-09-29T09:10:00Z')];

    const merged = mergeComments(fetched, live);

    expect(merged.map((c) => c.id)).toEqual(['1', '2']);
  });
});
