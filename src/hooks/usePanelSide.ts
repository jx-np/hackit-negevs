import { useCallback, useState } from 'react';

export type PanelSide = 'left' | 'right';

const STORAGE_KEY = 'forum-tag-panel-side';

function loadSide(): PanelSide {
  if (typeof window === 'undefined') return 'right';
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw === 'left' || raw === 'right' ? raw : 'right';
  } catch {
    return 'right';
  }
}

/** Persisted left/right side for the draggable tag panel. */
export function usePanelSide() {
  const [side, setSideState] = useState<PanelSide>(loadSide);

  const setSide = useCallback((next: PanelSide) => {
    setSideState(next);
    try {
      window.localStorage.setItem(STORAGE_KEY, next);
    } catch {
      /* ignore storage errors */
    }
  }, []);

  return { side, setSide };
}
