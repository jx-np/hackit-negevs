import { motion } from 'framer-motion';
import { ArrowLeft, FileQuestion, Home, Search } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';

export function NotFoundPage() {
  const location = useLocation();

  return (
    <div className="relative bg-paper dark:bg-ink-950">
      <div className="pointer-events-none absolute inset-0 ia-grid opacity-60" />

      <section className="relative mx-auto flex min-h-[70vh] max-w-3xl flex-col items-start justify-center px-6 py-20">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className="w-full"
        >
          <span className="ia-label flex items-center gap-2 text-caution-700 dark:text-caution-400">
            <span className="h-2 w-2 rounded-full bg-caution-500" />
            Registry lookup · no match
          </span>

          <h1 className="mt-6 font-display text-7xl font-bold leading-[0.95] tracking-tight text-ink-900 dark:text-white sm:text-8xl">
            404
          </h1>
          <p className="mt-6 max-w-xl text-xl leading-relaxed text-ink-600 dark:text-ink-300">
            No record exists at this address. The page may have been moved, or
            the link that brought you here is out of date.
          </p>

          {/* Registry-style record showing the missing path */}
          <div className="ia-panel mt-10 w-full shadow-ia">
            <div className="flex items-center justify-between border-b border-ink-200 px-4 py-2.5 dark:border-ink-800">
              <span className="ia-label text-ink-400">Record · not found</span>
              <span className="ia-label inline-flex items-center gap-1.5 rounded-sm bg-caution-100 px-2 py-0.5 text-caution-700 dark:bg-caution-500/15 dark:text-caution-500">
                <FileQuestion size={14} /> Missing
              </span>
            </div>
            <div className="flex items-center gap-3 px-4 py-4">
              <Search size={18} className="shrink-0 text-ink-400" />
              <code className="truncate font-mono text-lg text-ink-700 dark:text-ink-200">
                {location.pathname}
              </code>
            </div>
          </div>

          <div className="mt-10 flex flex-wrap items-center gap-4">
            <Link
              to="/"
              className="inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
            >
              <Home size={18} /> Back to home
            </Link>
            <Link
              to="/forum"
              className="inline-flex items-center gap-2 border border-ink-300 px-7 py-3.5 text-base font-semibold text-ink-800 transition hover:border-ink-900 dark:border-ink-700 dark:text-ink-100 dark:hover:border-white"
            >
              <ArrowLeft size={18} /> Enter the forum
            </Link>
          </div>
        </motion.div>
      </section>
    </div>
  );
}
