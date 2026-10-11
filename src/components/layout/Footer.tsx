import { Code2, ShieldCheck } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Footer() {
  return (
    <footer className="mt-16 border-t border-ink-200 bg-paper dark:border-ink-800 dark:bg-ink-950">
      <div className="mx-auto flex w-full max-w-[1400px] flex-col items-center justify-between gap-4 px-6 py-8 sm:flex-row">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          <span className="grid h-9 w-9 place-items-center bg-ink-900 text-white dark:bg-white dark:text-ink-900">
            <ShieldCheck size={20} />
          </span>
          <span className="font-display text-lg font-bold text-ink-900 dark:text-white">
            ScamWatch
          </span>
        </Link>

        <nav className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 font-display text-sm uppercase tracking-wider text-ink-500 dark:text-ink-400">
          <Link to="/" className="transition hover:text-safe-700 dark:hover:text-safe-400">
            Home
          </Link>
          <Link to="/forum" className="transition hover:text-safe-700 dark:hover:text-safe-400">
            Forum
          </Link>
          <Link to="/check" className="transition hover:text-safe-700 dark:hover:text-safe-400">
            Number check
          </Link>
          <Link to="/report" className="transition hover:text-safe-700 dark:hover:text-safe-400">
            Report a scam
          </Link>
          <Link to="/auth" className="transition hover:text-safe-700 dark:hover:text-safe-400">
            Sign in
          </Link>
          <a
            href="https://github.com/Qwertyuiop176g/kirostuff"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-1.5 transition hover:text-safe-700 dark:hover:text-safe-400"
          >
            <Code2 size={16} /> GitHub
          </a>
        </nav>

        <p className="text-xs text-ink-400">
          © {new Date().getFullYear()} ScamWatch
        </p>
      </div>
    </footer>
  );
}
