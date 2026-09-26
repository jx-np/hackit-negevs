import { AnimatePresence, motion, useScroll, useTransform } from 'framer-motion';
import { LogOut, ShieldCheck } from 'lucide-react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { SettingsPanel } from './SettingsPanel';

const LINKS = [
  { to: '/', label: 'Home', end: true },
  { to: '/forum', label: 'Forum', end: false },
  { to: '/check', label: 'Check', end: false },
  { to: '/report', label: 'Report', end: false },
];

export function Navbar() {
  const { scrollY } = useScroll();
  // Condense the navbar as the user scrolls down.
  const paddingY = useTransform(scrollY, [0, 80], [16, 10]);
  const location = useLocation();
  const navigate = useNavigate();
  const { isLoggedIn, user, logout } = useAuth();

  return (
    <motion.header
      style={{ paddingTop: paddingY, paddingBottom: paddingY }}
      className="sticky top-0 z-30 border-b border-ink-200 bg-paper/85 backdrop-blur-md dark:border-ink-800 dark:bg-ink-950/85"
    >
      <div className="mx-auto flex w-full max-w-[1400px] items-center justify-between px-6">
        <NavLink to="/" className="group flex items-center gap-2.5 font-semibold">
          <span className="grid h-10 w-10 place-items-center bg-ink-900 text-white transition group-hover:bg-safe-600 dark:bg-white dark:text-ink-900 dark:group-hover:bg-safe-500">
            <ShieldCheck size={22} />
          </span>
          <span className="font-display text-xl font-bold tracking-tight text-ink-900 dark:text-white">
            ScamReg
          </span>
        </NavLink>

        <nav className="flex items-center gap-4 sm:gap-6">
          <div className="flex items-center gap-1">
            {LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className="relative px-3 py-2 font-mono text-sm font-medium uppercase tracking-wider transition"
              >
                {({ isActive }) => (
                  <>
                    <span
                      className={
                        isActive
                          ? 'text-ink-900 dark:text-white'
                          : 'text-ink-500 hover:text-ink-900 dark:text-ink-400 dark:hover:text-white'
                      }
                    >
                      {link.label}
                    </span>
                    {isActive && (
                      <motion.span
                        layoutId="nav-underline"
                        className="absolute inset-x-2 -bottom-0.5 h-0.5 bg-safe-500"
                        transition={{ type: 'spring', duration: 0.4 }}
                      />
                    )}
                  </>
                )}
              </NavLink>
            ))}
          </div>

          {isLoggedIn ? (
            <div className="flex items-center gap-3">
              <span className="hidden font-mono text-xs text-ink-400 sm:inline">
                {user?.name}
              </span>
              <button
                type="button"
                onClick={() => {
                  logout();
                  navigate('/');
                }}
                className="flex items-center gap-1.5 border border-ink-300 px-3 py-2 text-sm font-medium text-ink-700 transition hover:border-ink-900 hover:text-ink-900 dark:border-ink-700 dark:text-ink-300 dark:hover:border-white dark:hover:text-white"
                aria-label="Log out"
              >
                <LogOut size={16} /> <span className="hidden sm:inline">Log out</span>
              </button>
            </div>
          ) : (
            <NavLink
              to="/auth"
              className="border border-ink-900 bg-ink-900 px-5 py-2 text-sm font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
            >
              Sign in
            </NavLink>
          )}

          <SettingsPanel />
        </nav>
      </div>

      {/* Route accent under the bar */}
      <AnimatePresence mode="wait">
        <motion.div
          key={location.pathname}
          className="absolute bottom-0 left-0 h-px bg-safe-500"
          initial={{ width: '0%' }}
          animate={{ width: '100%' }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
        />
      </AnimatePresence>
    </motion.header>
  );
}
