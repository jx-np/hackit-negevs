import { ChevronLeft, ChevronRight, X } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';

interface PostImageProps {
  /** Loadable redacted-image URLs, in display order. */
  urls: string[];
  /** Alt text base (e.g. the post title). */
  alt: string;
  /** Larger presentation for the post detail page. */
  variant?: 'card' | 'detail';
  /** Blur until revealed (feed cards treat evidence as sensitive). */
  concealUntilRevealed?: boolean;
}

/**
 * Renders a post's redacted screenshots with a lightbox.
 *
 * Only the PII-redacted copies the backend serves are ever displayed. A
 * thumbnail strip appears when a post has more than one image.
 */
export function PostImages({
  urls,
  alt,
  variant = 'card',
  concealUntilRevealed = false,
}: PostImageProps) {
  const [open, setOpen] = useState(false);
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(!concealUntilRevealed);
  const count = urls.length;

  const show = useCallback(
    (i: number) => {
      setIndex(((i % count) + count) % count);
      setOpen(true);
    },
    [count],
  );

  const step = useCallback(
    (delta: number) => setIndex((i) => ((i + delta) % count + count) % count),
    [count],
  );

  // Close on Escape and step with the arrow keys while the lightbox is open.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
      if (e.key === 'ArrowLeft') step(-1);
      if (e.key === 'ArrowRight') step(1);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, step]);

  if (count === 0) return null;

  const detail = variant === 'detail';

  return (
    <>
      <div className={detail ? 'space-y-3' : 'space-y-2'}>
        {urls.map((url, i) => (
          <div
            key={url}
            className="relative overflow-hidden rounded-md border border-scam-line"
          >
            <button
              type="button"
              onClick={() => (revealed ? show(i) : setRevealed(true))}
              className="block w-full cursor-zoom-in"
              aria-label={revealed ? `View image ${i + 1} of ${count}` : 'Reveal image'}
            >
              <img
                src={url}
                alt={`${alt} — redacted screenshot ${i + 1}`}
                loading="lazy"
                className={`block w-full bg-scam-750 object-contain transition ${
                  revealed ? '' : 'blur-md'
                } ${detail ? 'max-h-[32rem]' : 'max-h-80'}`}
              />
            </button>
            {!revealed && (
              <span className="pointer-events-none absolute inset-0 grid place-items-center bg-scam-950/50 text-xs font-semibold uppercase tracking-wider text-scam-text">
                Sensitive evidence · click to reveal
              </span>
            )}
          </div>
        ))}
      </div>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label={`${alt} images`}
          className="fixed inset-0 z-50 flex flex-col bg-scam-950/95"
          onClick={() => setOpen(false)}
        >
          <div className="flex items-center justify-between px-4 py-3 text-xs font-semibold uppercase tracking-wider text-scam-muted">
            <span>
              Redacted screenshot {index + 1} of {count}
            </span>
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close image viewer"
              className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800"
            >
              <X size={18} />
            </button>
          </div>

          <div className="relative flex min-h-0 flex-1 items-center justify-center px-4 pb-6">
            <img
              src={urls[index]}
              alt={`${alt} — redacted screenshot ${index + 1}`}
              className="max-h-full max-w-full object-contain"
              onClick={(e) => e.stopPropagation()}
            />

            {count > 1 && (
              <>
                <button
                  type="button"
                  aria-label="Previous image"
                  onClick={(e) => {
                    e.stopPropagation();
                    step(-1);
                  }}
                  className="absolute left-4 grid h-11 w-11 place-items-center rounded-full bg-scam-800/80 text-scam-text transition hover:bg-scam-750"
                >
                  <ChevronLeft size={22} />
                </button>
                <button
                  type="button"
                  aria-label="Next image"
                  onClick={(e) => {
                    e.stopPropagation();
                    step(1);
                  }}
                  className="absolute right-4 grid h-11 w-11 place-items-center rounded-full bg-scam-800/80 text-scam-text transition hover:bg-scam-750"
                >
                  <ChevronRight size={22} />
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
