import { useState } from 'react';
import { postImageUrl } from '../../api/media';
import { Lightbox } from './Lightbox';

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
        <Lightbox urls={[src]} index={0} alt={alt} onClose={() => setOpen(false)} />
      )}
    </>
  );
}
