import { useQuery } from '@tanstack/react-query';
import { getPost } from '../api/posts';
import type { Post } from '../types';

/** Fetch a single post by id for the detail / thread view. */
export function usePost(id: string | undefined) {
  return useQuery<Post>({
    queryKey: ['post', id],
    queryFn: () => getPost(id as string),
    enabled: !!id,
  });
}
