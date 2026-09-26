import { useQuery } from '@tanstack/react-query';
import { getTags } from '../api/tags';
import type { Tag } from '../types';

export function useTags() {
  return useQuery<Tag[]>({
    queryKey: ['tags'],
    queryFn: getTags,
    staleTime: 5 * 60 * 1000, // tags change rarely
  });
}
