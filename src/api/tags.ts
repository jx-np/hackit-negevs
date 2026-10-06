/**
 * Taxonomy API.
 *
 * The forum filters posts by `scam_type` (category), so `getTags` returns the
 * scam-type categories mapped to the UI `Tag` shape. `getTagsList` exposes the
 * free-form tag vocabulary (used as optional extra tags when reporting).
 */
import type { ApiListResponse, ApiTaxonomyItem, Tag } from '../types';
import { apiFetch } from './client';

function humanizeKey(key: string, slug: string): string {
  const tail = key.includes('.') ? key.slice(key.indexOf('.') + 1) : key;
  const base = tail || slug;
  return base
    .replace(/^(category|tag)\./, '')
    .replace(/[._-]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase())
    .trim();
}

function mapItem(item: ApiTaxonomyItem): Tag {
  return { id: item.slug, name: humanizeKey(item.name_key, item.slug) };
}

/** Scam-type categories — used for feed filtering and report categories. */
export async function getTags(): Promise<Tag[]> {
  const res = await apiFetch<ApiListResponse<ApiTaxonomyItem>>(
    '/community/scam-types',
  );
  return (res.items ?? []).map(mapItem);
}

/** Free-form tags vocabulary (optional, for extra tagging). */
export async function getTagsList(q = ''): Promise<Tag[]> {
  const params = new URLSearchParams();
  if (q) params.set('q', q);
  const path = params.toString()
    ? `/community/tags?${params.toString()}`
    : '/community/tags';
  const res = await apiFetch<ApiListResponse<ApiTaxonomyItem>>(path);
  return (res.items ?? []).map(mapItem);
}
