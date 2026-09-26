import type { Tag } from '../types';
import { apiFetch, delay, USE_MOCK } from './client';
import { MOCK_TAGS } from './mockData';

/**
 * Fetch all available tags.
 *
 * Real API integration: replace the mock branch with the actual endpoint,
 * e.g. `return apiFetch<Tag[]>('/tags');`
 */
export async function getTags(): Promise<Tag[]> {
  if (USE_MOCK) {
    return delay(MOCK_TAGS, 300);
  }
  return apiFetch<Tag[]>('/tags');
}
