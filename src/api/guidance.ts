/**
 * Guidance & resources ("Get help now") API.
 */
import type {
  ApiGuidanceItem,
  ApiListResponse,
  ApiResource,
  GuidanceItem,
  Resource,
} from '../types';
import { apiFetch } from './client';

function mapGuidance(g: ApiGuidanceItem): GuidanceItem {
  return {
    id: g.id,
    scenario: g.scenario,
    urgency: g.urgency,
    title: g.title,
    body: g.body,
    resources: g.resources ?? [],
  };
}

function mapResource(r: ApiResource): Resource {
  return {
    id: r.id,
    slug: r.slug,
    countryCode: r.country_code,
    url: r.url,
    contactInstructions: r.contact_instructions,
    name: r.name,
    description: r.description,
    verifiedAt: r.verified_at,
    ownerName: r.owner_name,
  };
}

export interface GuidanceQuery {
  scenario?: string;
  locale?: string;
}

/** Situation-specific next steps by scenario. */
export async function getGuidance(
  query: GuidanceQuery = {},
): Promise<GuidanceItem[]> {
  const params = new URLSearchParams();
  if (query.scenario) params.set('scenario', query.scenario);
  if (query.locale) params.set('locale', query.locale);
  const qs = params.toString();
  const res = await apiFetch<ApiListResponse<ApiGuidanceItem>>(
    `/guidance${qs ? `?${qs}` : ''}`,
  );
  return (res.items ?? []).map(mapGuidance);
}

export interface ResourcesQuery {
  country?: string;
  scenario?: string;
  locale?: string;
}

/** Vetted official resource catalog (ScamShield etc.). */
export async function getResources(
  query: ResourcesQuery = {},
): Promise<Resource[]> {
  const params = new URLSearchParams();
  if (query.country) params.set('country', query.country);
  if (query.scenario) params.set('scenario', query.scenario);
  if (query.locale) params.set('locale', query.locale);
  const qs = params.toString();
  const res = await apiFetch<ApiListResponse<ApiResource>>(
    `/guidance/resources${qs ? `?${qs}` : ''}`,
  );
  return (res.items ?? []).map(mapResource);
}
