import type { UploadedMedia } from '../types';
import { API_BASE_URL, delay, USE_MOCK } from './client';

/**
 * Upload a media file (e.g. a scam screenshot) and return its hosted URL.
 *
 * SCAFFOLDED: with no backend, this creates a local object URL so the image
 * previews and "works" in the UI, but it is NOT persisted anywhere — the URL
 * is only valid for the current page session.
 *
 * Real API integration: replace the mock branch with a real upload, e.g. a
 * multipart POST to your storage endpoint or a pre-signed S3 PUT:
 *
 *   const form = new FormData();
 *   form.append('file', file);
 *   const res = await fetch(`${API_BASE_URL}/media`, { method: 'POST', body: form });
 *   const { url } = await res.json();
 *   return { url, name: file.name };
 */
export async function uploadMedia(file: File): Promise<UploadedMedia> {
  if (USE_MOCK) {
    const url = URL.createObjectURL(file);
    // Simulate upload latency.
    return delay({ url, name: file.name }, 600);
  }

  const form = new FormData();
  form.append('file', file);
  const res = await fetch(`${API_BASE_URL}/media`, {
    method: 'POST',
    body: form,
  });
  if (!res.ok) {
    throw new Error(`Upload failed (${res.status})`);
  }
  const data = (await res.json()) as { url: string };
  return { url: data.url, name: file.name };
}

/** Basic client-side guard for accepted media. */
export const MAX_MEDIA_BYTES = 5 * 1024 * 1024; // 5 MB
export function validateMediaFile(file: File): string | null {
  if (!file.type.startsWith('image/')) {
    return 'Please choose an image file.';
  }
  if (file.size > MAX_MEDIA_BYTES) {
    return 'Image is too large (max 5 MB).';
  }
  return null;
}
