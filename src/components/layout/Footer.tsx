import { Code2, MessagesSquare } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Footer() {
  return (
    <footer className="mt-16 border-t border-slate-200 bg-white/50 dark:border-slate-800 dark:bg-slate-950/50">
      <div className="mx-auto flex max-w-5xl flex-col items-center justify-between gap-4 px-4 py-8 sm:flex-row">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-brand-gradient text-white">
            <MessagesSquare size={18} />
          </span>
          <span>Forum</span>
        </Link>

        <nav className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-slate-500 dark:text-slate-400">
          <Link to="/" className="transition hover:text-brand-600 dark:hover:text-brand-300">
            Forum
          </Link>
          <Link to="/auth" className="transition hover:text-brand-600 dark:hover:text-brand-300">
            Sign in
          </Link>
          <a
            href="https://github.com/Qwertyuiop176g/kirostuff"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-1.5 transition hover:text-brand-600 dark:hover:text-brand-300"
          >
            <Code2 size={15} /> GitHub
          </a>
        </nav>

        <p className="text-xs text-slate-400">
          © {new Date().getFullYear()} Forum. Built with React.
        </p>
      </div>
    </footer>
  );
}
