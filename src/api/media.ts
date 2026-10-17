/**
 * Screenshot upload + redaction API.
 *
 * Flow (see API.docs.md §5):
 *   1. `POST /uploads` — multipart `image` field; stores the image and
 *      schedules the background OCR + redaction job, returning
 *      `{ upload_id, media_type, status }`.
 *   2. Poll `GET /uploads/{upload_id}` until `status` is `ready` or `failed`.
 *   3. `GET /uploads/{upload_id}/redacted-image` — the censored copy,
 *      previewed to the author before publishing.
 *
 * A post attaches images by sending the *upload ids* on create; the backend
 * copies the redacted derivatives into post-owned objects.
 */
import type { ApiUpload, ApiUploadResponse, UploadedMedia } from '../types';
import { ApiError, apiAssetUrl, apiFetch, apiFetchBlob } from './client';

/** Media types accepted by `POST /uploads`. */
export const ALLOWED_MEDIA_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

/** Upload size limit enforced by the backend (`413 payload_too_large`). */
export const MAX_MEDIA_BYTES = 10 * 1024 * 1024; // 10 MiB

/**
 * Upload a screenshot. The response identifies the upload whose redaction job
 * has been scheduled; the image is not publishable until that job has produced
 * a redacted copy (use `waitForRedaction`).
 */
export async function uploadMedia(
  file: File,
  locale = 'en-SG',
): Promise<UploadedMedia> {
  const form = new FormData();
  form.append('image', file);
  form.append('locale', locale);

  const res = await apiFetch<ApiUploadResponse>('/uploads', {
    method: 'POST',
    body: form,
  });

  return {
    uploadId: res.upload_id,
    mediaType: res.media_type,
    name: file.name,
  };
}

/** Fetch the current progress of an upload. Owner-only. */
export async function getUpload(uploadId: string): Promise<ApiUpload> {
  return apiFetch<ApiUpload>(`/uploads/${encodeURIComponent(uploadId)}`);
}

/**
 * Cancel and permanently delete an upload.
 *
 * `DELETE /uploads/{id}` is owner-only and irreversible. If redaction is still
 * `queued` or `processing`, this cancels the in-flight (or not-yet-started)
 * OCR + PII-removal job, so no further compute is spent on a screenshot the
 * author has removed. A `404` means the upload is already gone or was never
 * ours — harmless for a removal, so it is treated as success.
 */
export async function deleteUpload(uploadId: string): Promise<void> {
  try {
    await apiFetch<void>(`/uploads/${encodeURIComponent(uploadId)}`, {
      method: 'DELETE',
    });
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) return;
    throw err;
  }
}

export interface RedactionOptions {
  /** How long to keep polling before giving up (default 60s). */
  timeoutMs?: number;
  /** Delay between polls (default 1.5s). */
  intervalMs?: number;
}

/**
 * Poll an upload until its redaction finishes.
 *
 * Resolves once the upload is `ready`. Rejects when it `failed` (which is what
 * the backend reports when its redaction service is unavailable) or when
 * polling exceeds `timeoutMs`.
 */
export async function waitForRedaction(
  uploadId: string,
  { timeoutMs = 60_000, intervalMs = 1_500 }: RedactionOptions = {},
): Promise<ApiUpload> {
  const deadline = Date.now() + timeoutMs;

  for (;;) {
    const upload = await getUpload(uploadId);
    if (upload.status === 'ready') return upload;
    if (upload.status === 'failed') {
      throw new Error(
        'We could not redact this screenshot. Try a different image, or post without it.',
      );
    }
    if (Date.now() + intervalMs > deadline) {
      throw new Error(
        'This screenshot is taking longer than expected to process. Try again in a moment.',
      );
    }
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }
}

/**
 * Fetch the redacted image for an upload as an object URL. Owner-only, so this
 * is the preview shown to the author before they publish.
 *
 * The caller owns the returned URL and must `URL.revokeObjectURL` it.
 */
export async function fetchRedactedImageUrl(uploadId: string): Promise<string> {
  const blob = await apiFetchBlob(
    `/uploads/${encodeURIComponent(uploadId)}/redacted-image`,
  );
  return URL.createObjectURL(blob);
}

/** Absolute URL for a post's redacted image at 0-based position `n`. */
export function postImageUrl(postId: string, n: number): string {
  return apiAssetUrl(
    `/api/v1/community/posts/${encodeURIComponent(postId)}/images/${n}`,
  );
}

/** Basic client-side guard mirroring the backend's upload rules. */
export function validateMediaFile(file: File): string | null {
  if (!(ALLOWED_MEDIA_TYPES as readonly string[]).includes(file.type)) {
    return 'Please choose a JPEG, PNG, or WebP image.';
  }
  if (file.size > MAX_MEDIA_BYTES) {
    return 'Image is too large (max 10 MB).';
  }
  return null;
}

