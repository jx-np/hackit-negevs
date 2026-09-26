import { motion, useScroll, useTransform } from 'framer-motion';
import { MessagesSquare } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';
import { SettingsPanel } from './SettingsPanel';

export function Navbar() {
  const { scrollY } = useScroll();
  // Condense the navbar as the user scrolls down.
  const paddingY = useTransform(scrollY, [0, 80], [16, 8]);
  const shadow = useTransform(
    scrollY,
    [0, 80],
    ['0 0 0 rgba(0,0,0,0)', '0 4px 20px rgba(0,0,0,0.08)'],
  );

  const { pathname } = useLocation();
  const onAuth = pathname.startsWith('/auth');

  return (
    <motion.header
      style={{ paddingTop: paddingY, paddingBottom: paddingY, boxShadow: shadow }}
      className="sticky top-0 z-30 border-b border-slate-200/60 bg-white/80 backdrop-blur-lg dark:border-slate-800/60 dark:bg-slate-950/80"
    >
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4">
        <Link to="/" className="flex items-center gap-2 font-semibold">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-brand-600 text-white">
            <MessagesSquare size={20} />
          </span>
          <span className="text-lg">Forum</span>
        </Link>

        <nav className="flex items-center gap-2">
          <Link
            to="/"
            className={`rounded-lg px-3 py-2 text-sm font-medium transition ${
              !onAuth
                ? 'text-brand-600 dark:text-brand-300'
                : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
            }`}
          >
            Forum
          </Link>
          <Link
            to="/auth"
            className={`rounded-lg px-3 py-2 text-sm font-medium transition ${
              onAuth
                ? 'text-brand-600 dark:text-brand-300'
                : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
            }`}
          >
            Sign in
          </Link>
          <SettingsPanel />
        </nav>
      </div>
    </motion.header>
  );
}
