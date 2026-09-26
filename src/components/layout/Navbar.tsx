import { AnimatePresence, motion, useScroll, useTransform } from 'framer-motion';
import { LogOut, ShieldCheck } from 'lucide-react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { SettingsPanel } from './SettingsPanel';

const LINKS = [
  { to: '/', label: 'Home', end: true },
  { to: '/forum', label: 'Forum', end: false },
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
      className="sticky top-0 z-30 border-b border-slate-200/60 bg-white/70 backdrop-blur-xl dark:border-slate-800/60 dark:bg-slate-950/70"
    >
      <div className="mx-auto flex w-full max-w-[1400px] items-center justify-between px-6">
        <NavLink to="/" className="group flex items-center gap-2.5 font-semibold">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-brand-gradient text-white shadow-soft transition-transform group-hover:scale-105">
            <ShieldCheck size={22} />
          </span>
          <span className="text-xl tracking-tight">
            Scam<span className="text-gradient">Reg</span>
          </span>
        </NavLink>

        <nav className="flex items-center gap-2 sm:gap-3">
          <div className="relative flex items-center rounded-full bg-slate-100/80 p-1 dark:bg-slate-800/80">
            {LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className="relative rounded-full px-4 py-2 text-base font-medium transition"
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

          {isLoggedIn ? (
            <div className="flex items-center gap-2">
              <span className="hidden text-sm font-medium text-slate-500 dark:text-slate-400 sm:inline">
                {user?.name}
              </span>
              <button
                type="button"
                onClick={() => {
                  logout();
                  navigate('/');
                }}
                className="flex items-center gap-1.5 rounded-full px-3 py-2 text-base font-medium text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-white"
                aria-label="Log out"
              >
                <LogOut size={18} /> <span className="hidden sm:inline">Log out</span>
              </button>
            </div>
          ) : (
            <NavLink
              to="/auth"
              className="rounded-full bg-brand-600 px-5 py-2 text-base font-semibold text-white shadow-soft transition hover:bg-brand-700"
            >
              Sign in
            </NavLink>
          )}

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
