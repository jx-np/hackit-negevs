import { useQuery } from '@tanstack/react-query';
import { getGuidance, getResources } from '../api/guidance';
import type { GuidanceItem, Resource } from '../types';

/** Situation-specific next steps, optionally filtered by scenario. */
export function useGuidance(scenario?: string) {
  return useQuery<GuidanceItem[]>({
    queryKey: ['guidance', scenario ?? null],
    queryFn: () => getGuidance(scenario ? { scenario } : {}),
  });
}

/** Vetted official resource catalog, optionally filtered by scenario/country. */
export function useResources(scenario?: string, country = 'SG') {
  return useQuery<Resource[]>({
    queryKey: ['resources', country, scenario ?? null],
    queryFn: () => getResources({ country, ...(scenario ? { scenario } : {}) }),
  });
}
