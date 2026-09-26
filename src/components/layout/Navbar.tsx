import { AnimatePresence, motion, useScroll, useTransform } from 'framer-motion';
import { MessagesSquare } from 'lucide-react';
import { NavLink, useLocation } from 'react-router-dom';
import { SettingsPanel } from './SettingsPanel';

const LINKS = [
  { to: '/', label: 'Forum', end: true },
  { to: '/auth', label: 'Sign in', end: false },
];

export function Navbar() {
  const { scrollY } = useScroll();
  // Condense the navbar as the user scrolls down.
  const paddingY = useTransform(scrollY, [0, 80], [16, 10]);
  const location = useLocation();

  return (
    <motion.header
      style={{ paddingTop: paddingY, paddingBottom: paddingY }}
      className="sticky top-0 z-30 border-b border-slate-200/60 bg-white/70 backdrop-blur-xl dark:border-slate-800/60 dark:bg-slate-950/70"
    >
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4">
        <NavLink to="/" className="group flex items-center gap-2.5 font-semibold">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-brand-gradient text-white shadow-soft transition-transform group-hover:scale-105">
            <MessagesSquare size={20} />
          </span>
          <span className="text-lg tracking-tight">
            For<span className="text-gradient">um</span>
          </span>
        </NavLink>

        <nav className="flex items-center gap-1 sm:gap-2">
          <div className="relative flex items-center rounded-full bg-slate-100/80 p-1 dark:bg-slate-800/80">
            {LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className="relative rounded-full px-4 py-1.5 text-sm font-medium transition"
              >
                {({ isActive }) => (
                  <>
                    {isActive && (
                      <motion.span
                        layoutId="nav-pill"
                        className="absolute inset-0 rounded-full bg-white shadow-sm dark:bg-slate-700"
                        transition={{ type: 'spring', duration: 0.4 }}
                      />
                    )}
                    <span
                      className={`relative z-10 ${
                        isActive
                          ? 'text-brand-600 dark:text-brand-300'
                          : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
                      }`}
                    >
                      {link.label}
                    </span>
                  </>
                )}
              </NavLink>
            ))}
          </div>

          <SettingsPanel />
        </nav>
      </div>

      {/* Subtle animated progress accent under the bar per route */}
      <AnimatePresence mode="wait">
        <motion.div
          key={location.pathname}
          className="absolute bottom-0 left-0 h-0.5 bg-brand-gradient"
          initial={{ width: '0%' }}
          animate={{ width: '100%' }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
        />
      </AnimatePresence>
    </motion.header>
  );
}
