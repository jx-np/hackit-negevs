import { AnimatePresence, motion } from 'framer-motion';
import {
  CheckCircle2,
  Code2,
  Link2,
  type LucideProps,
  MoreHorizontal,
  Share2,
} from 'lucide-react';
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import type { Post } from '../../types';

/**
 * Brand glyphs for the share sheet. lucide-react dropped its brand icons, so
 * we inline minimal SVGs for X and WhatsApp. They accept `size` to stay
 * consistent with the lucide icons used alongside them.
 */
function XBrandIcon({ size = 16, ...props }: LucideProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      {...props}
    >
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24h-6.656l-5.214-6.817-5.967 6.817H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.45-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z" />
    </svg>
  );
}

function WhatsAppBrandIcon({ size = 16, ...props }: LucideProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      {...props}
    >
      <path d="M12.04 2C6.58 2 2.13 6.45 2.13 11.91c0 1.75.46 3.45 1.32 4.95L2 22l5.25-1.38a9.9 9.9 0 0 0 4.79 1.22h.01c5.46 0 9.91-4.45 9.91-9.91C21.96 6.45 17.5 2 12.04 2Zm0 18.15h-.01a8.2 8.2 0 0 1-4.19-1.15l-.3-.18-3.12.82.83-3.04-.2-.31a8.2 8.2 0 0 1-1.26-4.38c0-4.54 3.7-8.23 8.25-8.23 2.2 0 4.27.86 5.83 2.42a8.19 8.19 0 0 1 2.41 5.82c0 4.54-3.7 8.23-8.25 8.23Zm4.52-6.16c-.25-.12-1.47-.72-1.69-.81-.23-.08-.39-.12-.56.13-.16.25-.64.8-.79.97-.14.16-.29.18-.54.06-.25-.13-1.05-.39-1.99-1.23-.74-.66-1.23-1.47-1.38-1.72-.14-.25-.01-.38.11-.51.11-.11.25-.29.37-.43.13-.14.17-.25.25-.41.08-.17.04-.31-.02-.43-.06-.12-.56-1.34-.76-1.84-.2-.48-.4-.42-.56-.42l-.48-.01c-.17 0-.43.06-.66.31-.23.25-.86.85-.86 2.07 0 1.22.89 2.4 1.01 2.56.12.17 1.75 2.67 4.23 3.74.59.26 1.05.41 1.41.52.59.19 1.13.16 1.56.1.48-.07 1.47-.6 1.67-1.18.21-.58.21-1.07.14-1.18-.06-.1-.22-.16-.47-.28Z" />
    </svg>
  );
}

/**
 * Share dropdown anchored to the Share button. Offers quick links to copy the
 * post URL, grab an embed snippet, share to X / WhatsApp, or hand off to the
 * native share sheet ("More options"). Dismisses on outside-click or Escape.
 */
export function ShareMenu({ post }: { post: Post }) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState<'link' | 'embed' | null>(null);
  const [coords, setCoords] = useState<{ top: number; right: number } | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  // Absolute URL to the post (safe in SSR-less Vite app, but guard anyway).
  const url =
    typeof window !== 'undefined'
      ? `${window.location.origin}/forum/${post.id}`
      : `/forum/${post.id}`;
  const embed = `<iframe src="${url}" title="${post.title}" width="100%" height="320" frameborder="0"></iframe>`;
  const text = `Scam report: ${post.title}`;

  // Position the portal menu just above the trigger. The menu is rendered in a
  // portal (outside the card) so the card's `overflow-hidden` can't clip it.
  useLayoutEffect(() => {
    if (!open) return;
    function place() {
      const btn = triggerRef.current;
      if (!btn) return;
      const rect = btn.getBoundingClientRect();
      setCoords({
        top: rect.top, // menu grows upward from here via translateY(-100%)
        right: window.innerWidth - rect.right,
      });
    }
    place();
    window.addEventListener('scroll', place, true);
    window.addEventListener('resize', place);
    return () => {
      window.removeEventListener('scroll', place, true);
      window.removeEventListener('resize', place);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onPointerDown(e: MouseEvent) {
      const target = e.target as Node;
      if (
        menuRef.current?.contains(target) ||
        triggerRef.current?.contains(target)
      ) {
        return;
      }
      setOpen(false);
    }
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpen(false);
    }
    document.addEventListener('mousedown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  async function copy(value: string, which: 'link' | 'embed') {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(which);
      setTimeout(() => setCopied(null), 1500);
    } catch {
      /* clipboard unavailable — silently ignore */
    }
  }

  function openWindow(href: string) {
    window.open(href, '_blank', 'noopener,noreferrer');
    setOpen(false);
  }

  async function nativeShare() {
    if (navigator.share) {
      try {
        await navigator.share({ title: post.title, text, url });
      } catch {
        /* user cancelled */
      }
    } else {
      await copy(url, 'link');
    }
    setOpen(false);
  }

  const items = [
    {
      key: 'copy',
      Icon: copied === 'link' ? CheckCircle2 : Link2,
      label: copied === 'link' ? 'Copied!' : 'Copy link',
      onClick: () => copy(url, 'link'),
    },
    {
      key: 'embed',
      Icon: copied === 'embed' ? CheckCircle2 : Code2,
      label: copied === 'embed' ? 'Copied!' : 'Embed',
      onClick: () => copy(embed, 'embed'),
    },
    {
      key: 'x',
      Icon: XBrandIcon,
      label: 'X',
      onClick: () =>
        openWindow(
          `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`,
        ),
    },
    {
      key: 'whatsapp',
      Icon: WhatsAppBrandIcon,
      label: 'WhatsApp',
      onClick: () =>
        openWindow(`https://wa.me/?text=${encodeURIComponent(`${text} ${url}`)}`),
    },
    {
      key: 'more',
      Icon: MoreHorizontal,
      label: 'More options',
      onClick: nativeShare,
    },
  ] as const;

  return (
    <>
      <motion.button
        ref={triggerRef}
        type="button"
        whileTap={{ scale: 0.85 }}
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label="Share"
        className="grid h-8 w-8 place-items-center rounded-md transition hover:bg-scam-800 hover:text-trust-400"
      >
        <Share2 size={16} />
      </motion.button>

      {/* Rendered in a portal so the card's `overflow-hidden` can't clip it. */}
      {createPortal(
        <AnimatePresence>
          {open && coords && (
            <motion.div
              ref={menuRef}
              role="menu"
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -4 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              style={{
                position: 'fixed',
                top: coords.top,
                right: coords.right,
                transform: 'translateY(calc(-100% - 0.25rem))',
              }}
              className="z-50 min-w-[12rem] overflow-hidden rounded-md border border-scam-line bg-scam-850 py-1 shadow-xl"
            >
              {items.map(({ key, Icon, label, onClick }) => (
                <button
                  key={key}
                  type="button"
                  role="menuitem"
                  onClick={onClick}
                  className="flex w-full items-center gap-3 px-3.5 py-2.5 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
                >
                  <Icon size={16} className="shrink-0" /> {label}
                </button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </>
  );
}
