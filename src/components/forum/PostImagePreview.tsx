import { X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { postImageUrl } from '../../api/media';

type Props = {
  postId: string;
  alt: string;
};

/**
 * Clear preview of a post's first redacted screenshot, shown in the feed card
 * between the title and body. The feed endpoint does not report whether a post
 * has images, so this optimistically loads `images/0` (a public endpoint) and
 * hides itself when the post has no image (the request 404s / errors).
 *
 * Clicking the preview selects and zooms it in a full-screen lightbox.
 */
export function PostImagePreview({ postId, alt }: Props) {
  const [failed, setFailed] = useState(false);
  const [open, setOpen] = useState(false);
  const src = postImageUrl(postId, 0);

  // Close the lightbox on Escape while it is open.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  if (failed) return null;

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label={`Zoom ${alt}`}
        className="block h-72 w-full cursor-zoom-in overflow-hidden rounded-md border border-scam-line bg-scam-750 transition hover:border-scam-muted/60"
      >
        <img
          src={src}
          alt={alt}
          loading="lazy"
          decoding="async"
          onError={() => setFailed(true)}
          className="h-full w-full object-cover"
        />
      </button>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={alt}
          className="fixed inset-0 z-50 flex flex-col bg-scam-950/95"
          onClick={() => setOpen(false)}
        >
          <div className="flex items-center justify-end px-4 py-3">
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close image viewer"
              className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800"
            >
              <X size={18} />
            </button>
          </div>
          <div className="flex min-h-0 flex-1 items-center justify-center px-4 pb-6">
            <img
              src={src}
              alt={alt}
              className="max-h-full max-w-full object-contain"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        </div>
      )}
    </>
  );
}
