import { AnimatePresence, motion } from 'framer-motion';
import { LogOut, ShieldCheck } from 'lucide-react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { SettingsPanel } from './SettingsPanel';

const BASE_LINKS = [
  { to: '/', label: 'Home', end: true },
  { to: '/forum', label: 'Forum', end: false },
  { to: '/report', label: 'Post', end: false },
  { to: '/check', label: 'Check', end: false },
  { to: '/help', label: 'Get help', end: false },
];

export function Navbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { isLoggedIn, user, logout } = useAuth();

  const links = isLoggedIn
    ? [...BASE_LINKS, { to: '/me/posts', label: 'My posts', end: false }]
    : BASE_LINKS;

  return (
    <motion.header
      className="sticky top-0 z-30 border-b border-ink-200 bg-paper/85 py-3 backdrop-blur-md dark:border-ink-800 dark:bg-ink-950/85"
    >
      <div className="mx-auto flex w-full max-w-[1400px] items-center justify-between px-6">
        <NavLink to="/" className="group flex items-center gap-2.5 font-semibold">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-ink-900 text-white transition group-hover:bg-safe-600 dark:bg-white dark:text-ink-900 dark:group-hover:bg-safe-500">
            <ShieldCheck size={22} />
          </span>
          <span className="font-display text-xl font-bold tracking-tight text-ink-900 transition group-hover:text-safe-600 dark:text-white dark:group-hover:text-safe-500">
            ScamWatch
          </span>
        </NavLink>

        <nav className="flex items-center gap-4 sm:gap-6">
          <div className="flex items-center gap-1">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className="relative px-3 py-2 font-display text-sm font-medium uppercase tracking-wider transition"
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
              <span className="hidden text-xs text-ink-400 sm:inline">
                {user?.name}
              </span>
              <button
                type="button"
                onClick={() => {
                  logout();
                  navigate('/');
                }}
                className="flex items-center gap-1.5 rounded-md border border-ink-300 px-3 py-2 text-sm font-medium text-ink-700 transition hover:border-safe-500 hover:text-safe-600 dark:border-ink-700 dark:text-ink-300 dark:hover:border-safe-500 dark:hover:text-safe-400"
                aria-label="Log out"
              >
                <LogOut size={16} /> <span className="hidden sm:inline">Log out</span>
              </button>
            </div>
          ) : (
            <NavLink
              to="/auth"
              className="rounded-md border border-safe-600 bg-safe-500 px-5 py-2 text-sm font-semibold text-white shadow-soft transition hover:bg-safe-600"
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
