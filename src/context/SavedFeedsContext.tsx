import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { Post } from '../types';

export interface SavedFeed {
  id: string;
  title: string;
  category: string;
}

interface SavedFeedsState {
  savedFeeds: SavedFeed[];
  isSaved: (id: string) => boolean;
  toggleSave: (post: Post) => void;
  removeFeed: (id: string) => void;
}

const STORAGE_KEY = 'forum-saved-feeds';

function loadInitial(): SavedFeed[] {
  if (typeof window !== 'undefined') {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed as SavedFeed[];
      }
    } catch {
      /* ignore malformed storage */
    }
  }
  return [];
}

const SavedFeedsContext = createContext<SavedFeedsState | undefined>(undefined);

export function SavedFeedsProvider({ children }: { children: ReactNode }) {
  const [savedFeeds, setSavedFeeds] = useState<SavedFeed[]>(loadInitial);

  useEffect(() => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(savedFeeds));
    } catch {
      /* ignore quota errors */
    }
  }, [savedFeeds]);

  const isSaved = useCallback(
    (id: string) => savedFeeds.some((f) => f.id === id),
    [savedFeeds],
  );

  const toggleSave = useCallback((post: Post) => {
    setSavedFeeds((feeds) => {
      if (feeds.some((f) => f.id === post.id)) {
        return feeds.filter((f) => f.id !== post.id);
      }
      return [
        ...feeds,
        {
          id: post.id,
          title: post.title,
          category: post.tags[0]?.name ?? 'Report',
        },
      ];
    });
  }, []);

  const removeFeed = useCallback((id: string) => {
    setSavedFeeds((feeds) => feeds.filter((f) => f.id !== id));
  }, []);

  const value = useMemo(
    () => ({ savedFeeds, isSaved, toggleSave, removeFeed }),
    [savedFeeds, isSaved, toggleSave, removeFeed],
  );

  return (
    <SavedFeedsContext.Provider value={value}>
      {children}
    </SavedFeedsContext.Provider>
  );
}

export function useSavedFeeds(): SavedFeedsState {
  const ctx = useContext(SavedFeedsContext);
  if (!ctx) {
    throw new Error('useSavedFeeds must be used within a SavedFeedsProvider');
  }
  return ctx;
}
