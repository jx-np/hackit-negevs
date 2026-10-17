import { ChevronLeft, ChevronRight, Minus, Plus, RotateCcw, X } from 'lucide-react';
import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
} from 'react';
import { createPortal } from 'react-dom';

const MIN_SCALE = 1;
const MAX_SCALE = 5;
const STEP = 0.5;

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

type LightboxProps = {
  /** Image URLs available in the viewer. */
  urls: string[];
  /** Currently shown image index. */
  index: number;
  /** Alt text base (e.g. the post title). */
  alt: string;
  /** Close the viewer. */
  onClose: () => void;
  /** Step by delta (wraps). Omit to hide image navigation. */
  onStep?: (delta: number) => void;
};

/**
 * Full-screen image viewer with zoom and pan.
 *
 * Zoom with the toolbar buttons, the scroll wheel, or a double-click; pan by
 * dragging once zoomed in. Arrow keys step between images and `+`/`-`/`0`
 * control zoom. Resets zoom whenever the shown image changes.
 */
export function Lightbox({ urls, index, alt, onClose, onStep }: LightboxProps) {
  const count = urls.length;
  const [scale, setScale] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const dragging = useRef<{ x: number; y: number; ox: number; oy: number } | null>(
    null,
  );
  const surfaceRef = useRef<HTMLDivElement | null>(null);
  const zoomByRef = useRef<(delta: number) => void>(() => {});

  const reset = useCallback(() => {
    setScale(1);
    setOffset({ x: 0, y: 0 });
  }, []);

  // Reset the zoom whenever we switch to a different image.
  useEffect(() => {
    reset();
  }, [index, reset]);

  // Lock background scroll while the viewer is open so wheeling zooms the
  // image without moving the page behind it.
  useEffect(() => {
    const { overflow } = document.body.style;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = overflow;
    };
  }, []);

  const zoomTo = useCallback((next: number) => {
    const clamped = clamp(next, MIN_SCALE, MAX_SCALE);
    if (clamped === MIN_SCALE) setOffset({ x: 0, y: 0 });
    setScale(clamped);
  }, []);

  const zoomBy = useCallback(
    (delta: number) => zoomTo(Math.round((scale + delta) * 100) / 100),
    [scale, zoomTo],
  );
  zoomByRef.current = zoomBy;

  // Attach a non-passive wheel listener so preventDefault() reliably stops the
  // page from scrolling behind the viewer while the wheel zooms the image.
  useEffect(() => {
    const el = surfaceRef.current;
    if (!el) return;
    const onWheelNative = (e: WheelEvent) => {
      e.preventDefault();
      zoomByRef.current(e.deltaY < 0 ? STEP : -STEP);
    };
    el.addEventListener('wheel', onWheelNative, { passive: false });
    return () => el.removeEventListener('wheel', onWheelNative);
  }, []);

  // Keyboard: Escape closes, arrows step, +/-/0 drive the zoom.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      else if (e.key === 'ArrowLeft') onStep?.(-1);
      else if (e.key === 'ArrowRight') onStep?.(1);
      else if (e.key === '+' || e.key === '=') zoomBy(STEP);
      else if (e.key === '-' || e.key === '_') zoomBy(-STEP);
      else if (e.key === '0') reset();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose, onStep, zoomBy, reset]);

  const onDoubleClick = useCallback(() => {
    if (scale > MIN_SCALE) reset();
    else zoomTo(2);
  }, [scale, reset, zoomTo]);

  const onPointerDown = useCallback(
    (e: ReactPointerEvent) => {
      if (scale <= MIN_SCALE) return;
      e.preventDefault();
      e.currentTarget.setPointerCapture(e.pointerId);
      dragging.current = { x: e.clientX, y: e.clientY, ox: offset.x, oy: offset.y };
    },
    [scale, offset],
  );

  const onPointerMove = useCallback((e: ReactPointerEvent) => {
    const start = dragging.current;
    if (!start) return;
    setOffset({
      x: start.ox + (e.clientX - start.x),
      y: start.oy + (e.clientY - start.y),
    });
  }, []);

  const endDrag = useCallback((e: ReactPointerEvent) => {
    if (dragging.current && e.currentTarget.hasPointerCapture(e.pointerId)) {
      e.currentTarget.releasePointerCapture(e.pointerId);
    }
    dragging.current = null;
  }, []);

  const zoomed = scale > MIN_SCALE;

  return createPortal(
    <div
      ref={surfaceRef}
      role="dialog"
      aria-modal="true"
      aria-label={`${alt} images`}
      className="fixed inset-0 z-[200] flex flex-col bg-scam-950/95"
      onClick={onClose}
    >
      <div className="flex items-center justify-between px-4 py-3 text-xs font-semibold uppercase tracking-wider text-scam-muted">
        <span>
          {count > 1 ? `Redacted screenshot ${index + 1} of ${count}` : 'Redacted screenshot'}
        </span>
        <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
          <button
            type="button"
            onClick={() => zoomBy(-STEP)}
            disabled={scale <= MIN_SCALE}
            aria-label="Zoom out"
            className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800 disabled:opacity-40 disabled:hover:bg-transparent"
          >
            <Minus size={18} />
          </button>
          <span className="w-12 text-center tabular-nums text-scam-text" aria-live="polite">
            {Math.round(scale * 100)}%
          </span>
          <button
            type="button"
            onClick={() => zoomBy(STEP)}
            disabled={scale >= MAX_SCALE}
            aria-label="Zoom in"
            className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800 disabled:opacity-40 disabled:hover:bg-transparent"
          >
            <Plus size={18} />
          </button>
          <button
            type="button"
            onClick={reset}
            disabled={!zoomed}
            aria-label="Reset zoom"
            className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800 disabled:opacity-40 disabled:hover:bg-transparent"
          >
            <RotateCcw size={16} />
          </button>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close image viewer"
            className="grid h-9 w-9 place-items-center rounded-md text-scam-text transition hover:bg-scam-800"
          >
            <X size={18} />
          </button>
        </div>
      </div>

      <div className="relative flex min-h-0 flex-1 items-center justify-center overflow-hidden px-4 pb-6">
        <img
          src={urls[index]}
          alt={`${alt} — redacted screenshot ${index + 1}`}
          draggable={false}
          onClick={(e) => e.stopPropagation()}
          onDoubleClick={onDoubleClick}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={endDrag}
          onPointerCancel={endDrag}
          style={{
            transform: `translate(${offset.x}px, ${offset.y}px) scale(${scale})`,
            cursor: zoomed ? (dragging.current ? 'grabbing' : 'grab') : 'zoom-in',
            touchAction: 'none',
          }}
          className="max-h-full max-w-full select-none object-contain transition-transform duration-75"
        />

        {count > 1 && onStep && (
          <>
            <button
              type="button"
              aria-label="Previous image"
              onClick={(e) => {
                e.stopPropagation();
                onStep(-1);
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
                onStep(1);
              }}
              className="absolute right-4 grid h-11 w-11 place-items-center rounded-full bg-scam-800/80 text-scam-text transition hover:bg-scam-750"
            >
              <ChevronRight size={22} />
            </button>
          </>
        )}
      </div>
    </div>,
    document.body,
  );
}
