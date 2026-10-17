import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useCallback, useState } from 'react';
import { Lightbox } from './Lightbox';

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
 * Only the PII-redacted copies the backend serves are ever displayed. A single
 * image fills the frame; multiple images become a swipeable carousel with
 * arrows and a dot indicator.
 */
export function PostImages({
  urls,
  alt,
  variant = 'card',
  concealUntilRevealed = false,
}: PostImageProps) {
  const [open, setOpen] = useState(false);
  const [index, setIndex] = useState(0);
  const [page, setPage] = useState(0);
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

  const pageStep = useCallback(
    (delta: number) => setPage((p) => ((p + delta) % count + count) % count),
    [count],
  );

  if (count === 0) return null;

  const detail = variant === 'detail';
  const carousel = count > 1;

  return (
    <>
      <div
        className="relative overflow-hidden rounded-md border border-scam-line"
        {...(carousel
          ? { role: 'group', 'aria-roledescription': 'carousel', 'aria-label': `${alt} — ${count} redacted screenshots` }
          : {})}
      >
        {/* Sliding track: every slide stays mounted so each screenshot is in the DOM. */}
        <div
          className="flex transition-transform duration-300 ease-out"
          style={{ transform: `translateX(-${page * 100}%)` }}
        >
          {urls.map((url, i) => (
            <div key={url} className="relative w-full shrink-0 basis-full">
              <button
                type="button"
                onClick={() => (revealed ? show(i) : setRevealed(true))}
                className="block w-full cursor-zoom-in"
                aria-label={revealed ? `View image ${i + 1} of ${count}` : 'Reveal image'}
                aria-hidden={carousel && i !== page}
                tabIndex={carousel && i !== page ? -1 : undefined}
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

        {carousel && (
          <>
            <button
              type="button"
              aria-label="Previous image in carousel"
              onClick={() => pageStep(-1)}
              className="absolute left-2 top-1/2 grid h-9 w-9 -translate-y-1/2 place-items-center rounded-full bg-scam-950/70 text-scam-text transition hover:bg-scam-950/90"
            >
              <ChevronLeft size={20} />
            </button>
            <button
              type="button"
              aria-label="Next image in carousel"
              onClick={() => pageStep(1)}
              className="absolute right-2 top-1/2 grid h-9 w-9 -translate-y-1/2 place-items-center rounded-full bg-scam-950/70 text-scam-text transition hover:bg-scam-950/90"
            >
              <ChevronRight size={20} />
            </button>

            <span className="pointer-events-none absolute right-2 top-2 rounded-full bg-scam-950/70 px-2 py-0.5 text-xs font-semibold text-scam-text">
              {page + 1} / {count}
            </span>

            <div className="pointer-events-none absolute inset-x-0 bottom-2 flex justify-center gap-1.5">
              {urls.map((url, i) => (
                <button
                  key={url}
                  type="button"
                  aria-label={`Go to image ${i + 1}`}
                  aria-current={i === page}
                  onClick={() => setPage(i)}
                  className={`pointer-events-auto h-2 rounded-full transition-all ${
                    i === page ? 'w-5 bg-scam-text' : 'w-2 bg-scam-text/40 hover:bg-scam-text/70'
                  }`}
                />
              ))}
            </div>
          </>
        )}
      </div>

      {open && (
        <Lightbox
          urls={urls}
          alt={alt}
          index={index}
          onStep={carousel ? step : undefined}
          onClose={() => setOpen(false)}
        />
      )}
    </>
  );
}
