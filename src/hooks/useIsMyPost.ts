import { useQuery } from '@tanstack/react-query';
import { getMyPosts } from '../api/posts';
import { useAuth } from '../context/AuthContext';

/**
 * Resolve whether a post belongs to the signed-in user.
 *
 * The post-detail endpoint (`GET /community/posts/{id}`) does not return
 * `is_mine`, so ownership cannot be read from the post itself. The feed and
 * `GET /me/posts` do carry it — this hook queries the caller's own posts and
 * checks membership so the detail page can show the owner-only menu actions
 * (edit / delete), mirroring the feed card.
 */
export function useIsMyPost(id: string | undefined): boolean {
  const { isLoggedIn } = useAuth();

  const { data } = useQuery<Set<string>>({
    queryKey: ['myPostIds'],
    queryFn: async () => {
      const ids = new Set<string>();
      let cursor: string | null = null;
      // Walk every page so ownership is correct even for older posts.
      do {
        const page = await getMyPosts(cursor, 50);
        for (const p of page.posts) ids.add(p.id);
        cursor = page.nextCursor;
      } while (cursor);
      return ids;
    },
    enabled: isLoggedIn,
    staleTime: 60_000,
  });

  return !!id && !!data?.has(id);
}
