import { useCallback, useState } from 'react';

/**
 * Cursor pagination with backward navigation.
 *
 * The API only returns a forward `next_cursor`, so the previous cursors are
 * kept in a trail. `reset()` returns to the first page (call it whenever a
 * filter/search changes so the next request starts from the beginning).
 */
export function useCursorPagination() {
  const [cursor, setCursor] = useState<string | null>(null);
  const [trail, setTrail] = useState<Array<string | null>>([]);

  const goNext = useCallback(
    (nextCursor: string) => {
      setTrail((t) => [...t, cursor]);
      setCursor(nextCursor);
    },
    [cursor],
  );

  const goPrev = useCallback(() => {
    setTrail((t) => {
      if (t.length === 0) return t;
      const next = [...t];
      const previous = next.pop() ?? null;
      setCursor(previous);
      return next;
    });
  }, []);

  const reset = useCallback(() => {
    setTrail([]);
    setCursor(null);
  }, []);

  return {
    cursor,
    /** Call with the page's `nextCursor` when the user presses Next. */
    goNext,
    goPrev,
    reset,
    hasPrev: trail.length > 0,
  };
}
