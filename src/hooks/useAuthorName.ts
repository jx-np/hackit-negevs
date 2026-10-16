import { useAuth } from '../context/AuthContext';

/**
 * Resolve the author name to display for a post.
 *
 * Posts are published anonymously — the feed and post-detail endpoints never
 * expose who authored a post, so the API-derived name is only a neutral label
 * (e.g. "Community member" / "Verified report"). The one author we *can* name
 * is the signed-in user themselves: when a post is the caller's own
 * (`isMine`), show their real display name so their submissions read as
 * `u/<their-name>` instead of the anonymous label.
 */
export function useAuthorName(fallback: string, isMine: boolean): string {
  const { user } = useAuth();
  if (isMine && user?.name) return user.name;
  return fallback;
}
