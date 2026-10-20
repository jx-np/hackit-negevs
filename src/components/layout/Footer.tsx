import { Code2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { BrandMark } from './Navbar';

const GROUPS = [
  {
    title: 'Product',
    links: [
      { to: '/', label: 'The app' },
      { to: '/check', label: 'Number check' },
      { to: '/help', label: 'Get help' },
      { to: '/credits', label: 'Credits' },
    ],
  },
  {
    title: 'Community',
    links: [
      { to: '/forum', label: 'Forum' },
      { to: '/report', label: 'Report a scam' },
      { to: '/auth', label: 'Sign in' },
    ],
  },
];

export function Footer() {
  return (
    <footer className="border-t border-scam-line bg-scam-900">
      <div className="mx-auto grid w-full max-w-[1400px] gap-10 px-5 py-12 sm:grid-cols-[1.4fr_1fr_1fr] lg:px-8">
        <div className="max-w-sm">
          <Link to="/" className="sr-focus inline-flex items-center gap-2.5 rounded-lg">
            <BrandMark size="sm" />
            <span className="font-display text-lg font-bold tracking-tight text-scam-text">
              ScamWatch
            </span>
          </Link>
          <p className="mt-4 text-pretty text-sm leading-relaxed text-scam-muted">
            On-device AI scam detection, backed by a community registry that
            warns everyone when a new scam appears.
          </p>
        </div>

        {GROUPS.map((group) => (
          <nav key={group.title} aria-label={group.title}>
            <p className="sr-label">{group.title}</p>
            <ul className="mt-4 space-y-2.5">
              {group.links.map((link) => (
                <li key={link.to + link.label}>
                  <Link
                    to={link.to}
                    className="sr-focus rounded text-sm text-scam-muted transition hover:text-trust-600 dark:hover:text-trust-400"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
        ))}
      </div>

      <div className="border-t border-scam-line">
        <div className="mx-auto flex w-full max-w-[1400px] flex-col items-center justify-between gap-3 px-5 py-5 text-xs text-scam-dim sm:flex-row lg:px-8">
          <p>© {new Date().getFullYear()} ScamWatch</p>
          <a
            href="https://github.com/Qwertyuiop176g/kirostuff"
            target="_blank"
            rel="noreferrer"
            className="sr-focus inline-flex items-center gap-1.5 rounded transition hover:text-trust-600 dark:hover:text-trust-400"
          >
            <Code2 size={14} /> Source on GitHub
          </a>
        </div>
      </div>
    </footer>
  );
}
