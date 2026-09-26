import { Code2, ShieldCheck } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Footer() {
  return (
    <footer className="mt-16 border-t border-slate-200 bg-white/50 dark:border-slate-800 dark:bg-slate-950/50">
      <div className="mx-auto flex w-full max-w-[1400px] flex-col items-center justify-between gap-4 px-6 py-8 sm:flex-row">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          <span className="grid h-9 w-9 place-items-center rounded-lg bg-brand-gradient text-white">
            <ShieldCheck size={20} />
          </span>
          <span className="text-lg">
            Scam<span className="text-gradient">Reg</span>
          </span>
        </Link>

        <nav className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-base text-slate-500 dark:text-slate-400">
          <Link to="/" className="transition hover:text-brand-600 dark:hover:text-brand-300">
            Home
          </Link>
          <Link to="/forum" className="transition hover:text-brand-600 dark:hover:text-brand-300">
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
            <Code2 size={16} /> GitHub
          </a>
        </nav>

        <p className="text-sm text-slate-400">
          © {new Date().getFullYear()} ScamReg. Built with React.
        </p>
      </div>
    </footer>
  );
}
