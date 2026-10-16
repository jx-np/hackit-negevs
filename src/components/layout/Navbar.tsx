import { motion } from 'framer-motion';
import { LogOut, Menu, ShieldCheck, X } from 'lucide-react';
import { useState } from 'react';
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

/** Brand mark: shield glyph on a trust-blue tile. Shared with the footer. */
export function BrandMark({ size = 'md' }: { size?: 'sm' | 'md' }) {
  const box = size === 'sm' ? 'h-8 w-8 rounded-lg' : 'h-9 w-9 rounded-xl';
  return (
    <span
      className={`relative grid ${box} place-items-center bg-gradient-to-b from-trust-500 to-trust-700 text-white shadow-button`}
    >
      <ShieldCheck size={size === 'sm' ? 17 : 19} strokeWidth={2.25} />
    </span>
  );
}

export function Navbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { isLoggedIn, user, logout } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);

  const links = isLoggedIn
    ? [...BASE_LINKS, { to: '/me/posts', label: 'My posts', end: false }]
    : BASE_LINKS;

  // Close the mobile menu whenever the route changes (derived, no effect).
  const [menuPath, setMenuPath] = useState(location.pathname);
  if (menuPath !== location.pathname) {
    setMenuPath(location.pathname);
    if (mobileOpen) setMobileOpen(false);
  }

  const linkClass = ({ isActive }: { isActive: boolean }) =>
    `sr-focus relative rounded-lg px-3 py-2 text-[0.95rem] font-medium transition ${
      isActive
        ? 'text-scam-text'
        : 'text-scam-muted hover:bg-scam-750 hover:text-scam-text'
    }`;

  return (
    <header className="sticky top-0 z-30 border-b border-scam-line bg-scam-950/80 backdrop-blur-xl supports-[backdrop-filter]:bg-scam-950/70">
      <div className="mx-auto flex h-16 w-full max-w-[1400px] items-center justify-between gap-4 px-5 lg:px-8">
        <NavLink to="/" className="sr-focus group flex items-center gap-2.5 rounded-lg">
          <BrandMark />
          <span className="font-display text-lg font-bold tracking-tight text-scam-text">
            ScamWatch
          </span>
        </NavLink>

        <nav className="flex items-center gap-2 sm:gap-3" aria-label="Primary">
          <div className="hidden items-center gap-0.5 md:flex">
            {links.map((link) => (
              <NavLink key={link.to} to={link.to} end={link.end} className={linkClass}>
                {({ isActive }) => (
                  <>
                    {link.label}
                    {isActive && (
                      <motion.span
                        layoutId="nav-underline"
                        className="absolute inset-x-3 -bottom-[13px] h-0.5 rounded-full bg-trust-500"
                        transition={{ type: 'spring', duration: 0.4 }}
                      />
                    )}
                  </>
                )}
              </NavLink>
            ))}
          </div>

          <span className="mx-1 hidden h-6 w-px bg-scam-line md:block" aria-hidden />

          {isLoggedIn ? (
            <div className="flex items-center gap-2">
              <span className="hidden max-w-[10rem] truncate text-sm text-scam-muted lg:inline">
                {user?.name}
              </span>
              <button
                type="button"
                onClick={() => {
                  logout();
                  navigate('/');
                }}
                className="sr-btn-ghost"
                aria-label="Log out"
              >
                <LogOut size={16} /> <span className="hidden sm:inline">Log out</span>
              </button>
            </div>
          ) : (
            <NavLink to="/auth" className="sr-btn-primary px-4">
              Sign in
            </NavLink>
          )}

          <SettingsPanel />

          <button
            type="button"
            onClick={() => setMobileOpen((o) => !o)}
            aria-expanded={mobileOpen}
            aria-controls="mobile-nav"
            aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
            className="sr-focus grid h-10 w-10 place-items-center rounded-lg border border-scam-line text-scam-text transition hover:bg-scam-750 md:hidden"
          >
            {mobileOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </nav>
      </div>

      {mobileOpen && (
        <div id="mobile-nav" className="border-t border-scam-line bg-scam-950 md:hidden">
          <div className="mx-auto flex max-w-[1400px] flex-col gap-1 px-5 py-3">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className={({ isActive }) =>
                  `sr-focus rounded-lg px-3 py-2.5 text-base font-medium transition ${
                    isActive
                      ? 'bg-trust-500/10 text-trust-600 dark:text-trust-400'
                      : 'text-scam-muted hover:bg-scam-750 hover:text-scam-text'
                  }`
                }
              >
                {link.label}
              </NavLink>
            ))}
          </div>
        </div>
      )}
    </header>
  );
}
