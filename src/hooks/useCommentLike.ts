import { useCallback, useSyncExternalStore } from 'react';

/**
 * Client-side comment likes.
 *
 * The backend has no comment reaction endpoint, so likes are persisted locally
 * in localStorage. We store the set of liked comment ids; the displayed count
 * is a per-comment base (seeded deterministically from the id so it looks
 * populated) plus one while the current user has it liked.
 */
const STORAGE_KEY = 'scamwatch-comment-likes';

type LikeState = Record<string, boolean>;

function read(): LikeState {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as LikeState) : {};
  } catch {
    return {};
  }
}

function write(state: LikeState) {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    /* ignore quota / unavailable storage */
  }
}

const listeners = new Set<() => void>();
let state: LikeState = read();

function emit() {
  for (const l of listeners) l();
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function getSnapshot() {
  return state;
}

function toggle(id: string) {
  state = { ...state, [id]: !state[id] };
  if (!state[id]) delete state[id];
  write(state);
  emit();
}

/** Deterministic non-negative base count derived from a comment id. */
function baseCount(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) {
    h = (h * 31 + id.charCodeAt(i)) >>> 0;
  }
  return h % 12;
}

export interface CommentLike {
  liked: boolean;
  count: number;
  toggle: () => void;
}

export function useCommentLike(commentId: string): CommentLike {
  const likes = useSyncExternalStore(subscribe, getSnapshot, getSnapshot);
  const liked = !!likes[commentId];
  const count = baseCount(commentId) + (liked ? 1 : 0);

  const toggleLike = useCallback(() => toggle(commentId), [commentId]);

  return { liked, count, toggle: toggleLike };
}
