import { ImagePlus, Loader2, ShieldCheck, X } from 'lucide-react';
import { useCallback, useEffect, useRef, useState } from 'react';
import {
  deleteDetection,
  fetchRedactedImageUrl,
  MAX_MEDIA_BYTES,
  uploadMedia,
  validateMediaFile,
  waitForRedaction,
} from '../../api/media';

/** An upload that has been accepted and (once redacted) is publishable. */
export interface PickedImage {
  /** Upload id sent to the backend as part of `upload_ids`. */
  uploadId: string;
  /** Detection check that produced the redacted copy. */
  checkId: string;
  name: string;
  /** `processing` while OCR/redaction runs, `ready` once publishable. */
  status: 'processing' | 'ready' | 'failed';
  /** Object URL of the redacted preview (owner-only). */
  previewUrl: string | null;
  error: string | null;
}

interface MediaPickerProps {
  value: PickedImage[];
  onChange: (images: PickedImage[]) => void;
  /** Optional maximum number of images. Omit for no client-side limit. */
  max?: number;
}

const MAX_MB = Math.round(MAX_MEDIA_BYTES / (1024 * 1024));

/**
 * Screenshot picker for a report.
 *
 * Each chosen file is uploaded to `POST /uploads`, which schedules OCR + PII
 * redaction. The picker polls until the redacted copy is ready and previews
 * *that* copy - the raw upload is never shown or published. Only images in the
 * `ready` state are publishable, which is what `POST /community/posts` requires.
 */
export function MediaPicker({ value, onChange, max }: MediaPickerProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragging, setDragging] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Latest list, so async uploads don't clobber each other's results. It is
  // written only from event handlers and async callbacks (never during render).
  const valueRef = useRef(value);
  // Row ids removed while their upload was still in flight. If the upload (and
  // its check) lands after removal, the check is deleted on arrival so a
  // queued/not-yet-started redaction job is still cancelled.
  const removedRef = useRef<Set<string>>(new Set());
  // Redacted preview opened full-screen so the user can inspect the detail.
  const [zoom, setZoom] = useState<{ url: string; name: string } | null>(null);

  const full = max !== undefined && value.length >= max;

  // Close the zoom overlay on Escape.
  useEffect(() => {
    if (!zoom) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setZoom(null);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [zoom]);

  /**
   * Update the list while keeping the local ref in sync. React may not have
   * re-rendered between the async upload steps, so reads must never rely on
   * the `value` prop alone.
   */
  const apply = useCallback(
    (next: PickedImage[]) => {
      valueRef.current = next;
      onChange(next);
    },
    [onChange],
  );

  // Adopt externally-driven changes (e.g. the form clearing the list).
  useEffect(() => {
    valueRef.current = value;
  }, [value]);

  const patch = useCallback(
    (uploadId: string, changes: Partial<PickedImage>) => {
      apply(
        valueRef.current.map((img) =>
          img.uploadId === uploadId ? { ...img, ...changes } : img,
        ),
      );
    },
    [apply],
  );

  // Release object URLs when the component unmounts.
  useEffect(() => {
    return () => {
      valueRef.current.forEach((img) => {
        if (img.previewUrl) URL.revokeObjectURL(img.previewUrl);
      });
    };
  }, []);

  const handleFiles = useCallback(
    async (files: File[]) => {
      setError(null);
      const slots =
        max === undefined ? files.length : Math.max(0, max - valueRef.current.length);
      const accepted: File[] = [];

      for (const file of files.slice(0, slots)) {
        const validationError = validateMediaFile(file);
        if (validationError) {
          setError(validationError);
          continue;
        }
        accepted.push(file);
      }
      if (accepted.length === 0) return;

      // Reserve placeholders so concurrent uploads keep their order and the
      // picker shows progress immediately.
      const placeholders: PickedImage[] = accepted.map((file, i) => ({
        uploadId: `pending-${Date.now()}-${i}`,
        checkId: '',
        name: file.name,
        status: 'processing',
        previewUrl: null,
        error: null,
      }));
      apply([...valueRef.current, ...placeholders]);
      await Promise.all(
        accepted.map(async (file, i) => {
          const placeholder = placeholders[i];
          // The row's id changes from the placeholder to the real upload id
          // once the upload is accepted, so track the current one for updates.
          let currentId = placeholder.uploadId;
          try {
            const media = await uploadMedia(file);
            // Removed while uploading: the row is gone, so there is nothing to
            // update. Cancel the freshly-created check to free its blobs and
            // stop a queued/in-flight redaction job from running.
            if (removedRef.current.has(placeholder.uploadId)) {
              removedRef.current.delete(placeholder.uploadId);
              void deleteDetection(media.checkId).catch(() => {});
              return;
            }
            // Swap the placeholder id for the real upload id.
            apply(
              valueRef.current.map((img) =>
                img.uploadId === placeholder.uploadId
                  ? { ...img, uploadId: media.uploadId, checkId: media.checkId }
                  : img,
              ),
            );
            currentId = media.uploadId;

            await waitForRedaction(media.checkId);
            // The redacted copy is owner-only, so the preview is best-effort:
            // an anonymous (demo) upload is still publishable without one.
            try {
              const previewUrl = await fetchRedactedImageUrl(media.checkId);
              patch(currentId, { status: 'ready', previewUrl });
            } catch {
              patch(currentId, { status: 'ready' });
            }
          } catch (e) {
            patch(currentId, {
              status: 'failed',
              error: (e as Error).message || 'Upload failed.',
            });
          }
        }),
      );
    },
    [apply, max, patch],
  );

  const remove = (uploadId: string) => {
    const img = valueRef.current.find((i) => i.uploadId === uploadId);
    if (img?.previewUrl) URL.revokeObjectURL(img.previewUrl);
    apply(valueRef.current.filter((i) => i.uploadId !== uploadId));

    // Delete the check server-side so its stored blobs are removed and any
    // still-queued or in-flight redaction job is cancelled (saving compute).
    // Fire-and-forget: the image is already gone from the report, and a 404
    // (never existed / already gone) is treated as success by deleteDetection.
    if (img?.checkId) {
      void deleteDetection(img.checkId).catch(() => {
        /* best-effort cleanup; nothing actionable for the user */
      });
    } else {
      // Removed before the upload resolved: remember it so the in-flight
      // upload cancels its check as soon as one is created.
      removedRef.current.add(uploadId);
    }
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragging(false);
    const files = Array.from(e.dataTransfer.files ?? []);
    if (files.length) handleFiles(files);
  };

  return (
    <div>
      {value.length > 0 && (
        <ul className="mb-3 grid gap-3 sm:grid-cols-2">
          {value.map((img) => (
            <li
              key={img.uploadId}
              className="relative overflow-hidden rounded-md border border-ink-200 dark:border-ink-700"
            >
              {img.previewUrl ? (
                img.status === 'ready' ? (
                  <button
                    type="button"
                    onClick={() =>
                      setZoom({ url: img.previewUrl!, name: img.name })
                    }
                    aria-label={`Zoom in on redacted evidence: ${img.name}`}
                    className="block w-full cursor-zoom-in"
                  >
                    <img
                      src={img.previewUrl}
                      alt={`Redacted evidence: ${img.name}`}
                      className="max-h-72 w-full bg-ink-100 object-contain dark:bg-ink-800"
                    />
                  </button>
                ) : (
                  <img
                    src={img.previewUrl}
                    alt={`Redacted evidence: ${img.name}`}
                    className="max-h-72 w-full bg-ink-100 object-contain dark:bg-ink-800"
                  />
                )
              ) : (
                <div className="flex h-40 flex-col items-center justify-center gap-2 bg-ink-100 px-4 text-center dark:bg-ink-800">
                  {img.status === 'failed' ? (
                    <span className="text-xs text-risk-600 dark:text-risk-500">
                      {img.error}
                    </span>
                  ) : img.status === 'processing' ? (
                    <>
                      <Loader2
                        size={22}
                        className="animate-spin text-safe-600"
                      />
                      <span className="text-xs text-ink-500">
                        Redacting personal information...
                      </span>
                    </>
                  ) : (
                    <span className="text-xs text-ink-500">
                      Screenshot attached — preview unavailable
                    </span>
                  )}
                </div>
              )}

              <button
                type="button"
                onClick={() => remove(img.uploadId)}
                aria-label={`Remove ${img.name}`}
                className="absolute right-2 top-2 grid h-8 w-8 place-items-center bg-ink-900/80 text-white transition hover:bg-ink-900"
              >
                <X size={16} />
              </button>

              <p className="flex items-center gap-1.5 border-t border-ink-200 px-3 py-1.5 text-xs text-ink-400 dark:border-ink-700">
                {img.status === 'ready' ? (
                  <>
                    <ShieldCheck size={13} className="text-safe-600" />
                    Redacted preview
                  </>
                ) : (
                  img.name
                )}
              </p>
            </li>
          ))}
        </ul>
      )}

      {!full && (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={onDrop}
          className={`flex w-full flex-col items-center justify-center gap-2 rounded-md border border-dashed px-6 py-10 text-center transition ${
            dragging
              ? 'border-safe-500 bg-safe-50 dark:bg-safe-500/10'
              : 'border-ink-300 hover:border-safe-400 dark:border-ink-700 dark:hover:border-safe-500/60'
          }`}
        >
          <ImagePlus size={26} className="text-ink-400" />
          <span className="text-base font-medium text-ink-700 dark:text-ink-200">
            Click to choose an image, or drag and drop
          </span>
          <span className="text-xs text-ink-400">
            JPEG, PNG or WebP, up to {MAX_MB} MB - we redact personal details
            before anyone sees it
          </span>
        </button>
      )}

      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        className="sr-only"
        aria-label="Upload evidence image"
        onChange={(e) => {
          const files = Array.from(e.target.files ?? []);
          if (files.length) handleFiles(files);
          e.target.value = '';
        }}
      />

      {error && (
        <p className="mt-1 text-xs text-risk-600 dark:text-risk-500">{error}</p>
      )}

      {zoom && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={`Redacted evidence: ${zoom.name}`}
          className="fixed inset-0 z-50 flex flex-col bg-ink-950/95"
          onClick={() => setZoom(null)}
        >
          <div className="flex items-center justify-end px-4 py-3">
            <button
              type="button"
              onClick={() => setZoom(null)}
              aria-label="Close image viewer"
              className="grid h-9 w-9 place-items-center rounded-md text-white transition hover:bg-white/10"
            >
              <X size={18} />
            </button>
          </div>
          <div className="flex min-h-0 flex-1 items-center justify-center px-4 pb-6">
            <img
              src={zoom.url}
              alt={`Redacted evidence: ${zoom.name}`}
              className="max-h-full max-w-full object-contain"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        </div>
      )}
    </div>
  );
}
