import { motion } from 'framer-motion';
import { ArrowLeft, Construction, type LucideIcon } from 'lucide-react';
import { Link } from 'react-router-dom';

interface PlaceholderPageProps {
  /** Short section label shown above the title. */
  eyebrow: string;
  /** Page heading. */
  title: string;
  /** One or two sentences describing what will live here. */
  description: string;
  /** Icon shown in the header tile. */
  icon: LucideIcon;
}

/**
 * Shared "coming soon" scaffold for navigation destinations that don't have
 * real content yet. Keeps the forum's dark palette and motion conventions so
 * these stubs feel like part of the app rather than dead links.
 */
export function PlaceholderPage({
  eyebrow,
  title,
  description,
  icon,
}: PlaceholderPageProps) {
  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <PlaceholderContent
          eyebrow={eyebrow}
          title={title}
          description={description}
          icon={icon}
          showBackLink
        />
      </div>
    </div>
  );
}

/**
 * Inner "coming soon" content without the full-page wrapper, so it can be
 * rendered inline inside the forum feed as well as on its own route.
 * The back-to-forum link is only shown on the standalone page.
 */
export function PlaceholderContent({
  eyebrow,
  title,
  description,
  icon: Icon,
  showBackLink = false,
}: PlaceholderPageProps & { showBackLink?: boolean }) {
  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
      >
        <span className="sr-tile h-12 w-12">
          <Icon size={24} />
        </span>
        <div>
          <span className="sr-eyebrow">{eyebrow}</span>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
            {title}
          </h1>
          <p className="mt-1 text-sm text-scam-muted">{description}</p>
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, ease: 'easeOut', delay: 0.1 }}
        className="flex flex-col items-center rounded-lg border border-dashed border-scam-line bg-scam-800 px-6 py-16 text-center"
      >
        <span className="sr-tile h-14 w-14">
          <Construction size={26} />
        </span>
        <h2 className="mt-5 text-lg font-semibold text-scam-text">
          Coming soon
        </h2>
        <p className="mt-2 max-w-md text-sm leading-relaxed text-scam-muted">
          We&rsquo;re still building this section. Check back soon &mdash; in
          the meantime, head back to the forum to browse and report scams.
        </p>
        {showBackLink && (
          <Link
            to="/forum"
            className="mt-6 inline-flex items-center gap-2 rounded-md bg-trust-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-trust-600"
          >
            <ArrowLeft size={16} /> Back to the forum
          </Link>
        )}
      </motion.div>
    </>
  );
}
