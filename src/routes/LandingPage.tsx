import { motion } from 'framer-motion';
import {
  ArrowRight,
  BellRing,
  Check,
  Cpu,
  Database,
  Link2,
  Lock,
  MessageSquareText,
  Phone,
  ScanLine,
  ShieldCheck,
  Users,
  WifiOff,
  X,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { DeviceMockup, PopOutCard } from '../components/landing/DeviceMockup';

const THREATS = [
  { icon: MessageSquareText, label: 'Scam texts & SMS' },
  { icon: Phone, label: 'Fraudulent calls' },
  { icon: Link2, label: 'Phishing links' },
  { icon: Users, label: 'Impersonation' },
];

const FEATURES = [
  {
    icon: Cpu,
    title: 'On-device AI detection',
    body: 'Messages, calls, and links are analysed by AI models that run entirely on your phone. Nothing is uploaded to spot a scam.',
  },
  {
    icon: BellRing,
    title: 'Real-time warnings',
    body: 'Get a clear alert the moment a known scam pattern reaches you, before you tap, reply, or pay.',
  },
  {
    icon: Database,
    title: 'Centralized reporting',
    body: 'Report a scam once and it joins a shared registry, so everyone using ScamWatch is warned about it too.',
  },
  {
    icon: Lock,
    title: 'Private by design',
    body: 'Your personal messages stay yours. Only the scam reports you choose to submit are ever shared.',
  },
];

const STEPS = [
  {
    icon: ScanLine,
    title: 'Scan',
    body: 'ScamWatch quietly checks incoming messages, calls, and links on your device.',
  },
  {
    icon: ShieldCheck,
    title: 'Detect',
    body: 'On-device AI flags anything that looks like a scam and tells you why.',
  },
  {
    icon: Users,
    title: 'Report',
    body: 'One tap sends it to the shared registry, protecting the whole community.',
  },
];

const PRIVACY_ROWS = [
  { label: 'Messages analysed on your phone', us: true, them: false },
  { label: 'Works without an internet connection', us: true, them: false },
  { label: 'Message content sent to a server', us: false, them: true },
  { label: 'Community-reported scam registry', us: true, them: false },
];

const fade = {
  initial: { opacity: 0, y: 18 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: '-60px' },
  transition: { duration: 0.55, ease: [0.22, 1, 0.36, 1] as const },
};

function SectionHeading({
  eyebrow,
  title,
  body,
  center = false,
}: {
  eyebrow: string;
  title: string;
  body?: string;
  center?: boolean;
}) {
  return (
    <motion.div {...fade} className={center ? 'mx-auto max-w-2xl text-center' : 'max-w-2xl'}>
      <span className="sr-eyebrow">{eyebrow}</span>
      <h2 className="mt-3 text-balance font-display text-3xl font-bold tracking-tight text-scam-text sm:text-[2.6rem] sm:leading-[1.1]">
        {title}
      </h2>
      {body && (
        <p className="mt-4 text-pretty text-lg leading-relaxed text-scam-muted">{body}</p>
      )}
    </motion.div>
  );
}

export function LandingPage() {
  return (
    <div className="overflow-x-clip bg-scam-950 text-scam-text">
      {/* ===== HERO ===== */}
      <section className="relative border-b border-scam-line">
        <div className="pointer-events-none absolute inset-0 sw-dots opacity-70 [mask-image:radial-gradient(ellipse_at_70%_40%,black_20%,transparent_70%)]" />
        <div className="pointer-events-none absolute -right-40 top-0 h-[640px] w-[640px] sw-halo" />

        <div className="relative mx-auto grid max-w-6xl items-center gap-14 px-6 pb-20 pt-16 lg:grid-cols-[1.05fr_0.95fr] lg:pb-28 lg:pt-24">
          <motion.div
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="inline-flex items-center gap-2 rounded-full border border-scam-line bg-scam-800 px-3 py-1.5 text-sm font-medium text-scam-muted shadow-card">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping-slow rounded-full bg-verified-500" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-verified-500" />
              </span>
              The ScamWatch mobile app
            </span>

            <h1 className="mt-6 text-balance font-display text-5xl font-bold leading-[1.02] tracking-tight text-scam-text sm:text-6xl lg:text-[4.5rem]">
              Spot the scam{' '}
              <span className="text-trust-600 dark:text-trust-400">before it spots you.</span>
            </h1>

            <p className="mt-6 max-w-xl text-pretty text-xl leading-relaxed text-scam-muted">
              ScamWatch uses on-device AI to catch scam messages, calls, and
              phishing links in real time, backed by a community registry that
              warns everyone the moment a new scam appears.
            </p>

            <div className="mt-9 flex flex-wrap items-center gap-3">
              <Link
                to="/forum"
                className="sw-btn-lg bg-trust-600 text-white shadow-button hover:bg-trust-700"
              >
                Explore the community <ArrowRight size={18} />
              </Link>
              <Link
                to="/check"
                className="sw-btn-lg border border-scam-line bg-scam-800 text-scam-text shadow-card hover:border-trust-500/60 hover:text-trust-600 dark:hover:text-trust-400"
              >
                Check a number
              </Link>
            </div>

            <ul className="mt-10 flex flex-wrap gap-x-6 gap-y-3 text-sm font-medium text-scam-muted">
              {[
                { icon: Cpu, label: 'Runs on your device' },
                { icon: WifiOff, label: 'Works offline' },
                { icon: Lock, label: 'Messages never uploaded' },
              ].map(({ icon: Icon, label }) => (
                <li key={label} className="inline-flex items-center gap-2">
                  <Icon size={16} className="text-trust-600 dark:text-trust-400" aria-hidden />
                  {label}
                </li>
              ))}
            </ul>
          </motion.div>

          {/* Device + floating alerts */}
          <motion.div
            initial={{ opacity: 0, y: 24, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1], delay: 0.1 }}
            className="relative mx-auto w-full max-w-md"
          >
            <div className="pointer-events-none absolute inset-x-0 top-10 mx-auto h-[420px] w-[420px] rounded-full bg-gradient-to-b from-trust-500/20 to-transparent blur-2xl" />
            <div className="relative">
              <DeviceMockup />
            </div>
            <motion.div
              aria-hidden
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, delay: 0.6 }}
              className="absolute -left-2 top-24 hidden sm:block lg:-left-16"
            >
              <div className="animate-float">
                <PopOutCard tone="risk" />
              </div>
            </motion.div>
            <motion.div
              aria-hidden
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6, delay: 0.85 }}
              className="absolute -right-2 bottom-20 hidden sm:block lg:-right-12"
            >
              <div className="animate-float [animation-delay:1.5s]">
                <PopOutCard
                  tone="safe"
                  title="Reported to registry"
                  body="Others will now be warned too"
                />
              </div>
            </motion.div>
          </motion.div>
        </div>

        {/* What it catches */}
        <div className="relative border-t border-scam-line bg-scam-800/60">
          <div className="mx-auto flex max-w-6xl flex-col gap-4 px-6 py-6 sm:flex-row sm:items-center sm:justify-between">
            <span className="sr-label">Protects you from</span>
            <ul className="grid grid-cols-2 gap-x-8 gap-y-3 sm:flex sm:flex-wrap">
              {THREATS.map(({ icon: Icon, label }) => (
                <li key={label} className="inline-flex items-center gap-2 text-base font-medium text-scam-text">
                  <Icon size={18} className="text-scam-muted" aria-hidden />
                  {label}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ===== FEATURES ===== */}
      <section className="border-b border-scam-line">
        <div className="mx-auto max-w-6xl px-6 py-24">
          <SectionHeading
            eyebrow="Why ScamWatch"
            title="A security layer that lives in your pocket"
            body="Private AI on your phone does the detecting. A shared registry makes every report count for everyone."
          />

          <div className="mt-14 grid gap-5 sm:grid-cols-2">
            {FEATURES.map(({ icon: Icon, title, body }, i) => (
              <motion.div
                key={title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-40px' }}
                transition={{ duration: 0.5, delay: i * 0.06, ease: [0.22, 1, 0.36, 1] }}
                className="sr-card group relative overflow-hidden p-8"
              >
                <div className="pointer-events-none absolute -right-16 -top-16 h-48 w-48 rounded-full bg-trust-500/0 blur-2xl transition duration-500 group-hover:bg-trust-500/10" />
                <span className="relative grid h-12 w-12 place-items-center rounded-xl bg-trust-500/10 text-trust-600 ring-1 ring-inset ring-trust-500/20 dark:text-trust-400">
                  <Icon size={22} aria-hidden />
                </span>
                <h3 className="relative mt-6 font-display text-xl font-semibold tracking-tight text-scam-text">
                  {title}
                </h3>
                <p className="relative mt-2 text-pretty text-base leading-relaxed text-scam-muted">
                  {body}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== PRIVACY COMPARISON ===== */}
      <section className="border-b border-scam-line bg-scam-900">
        <div className="mx-auto grid max-w-6xl items-center gap-14 px-6 py-24 lg:grid-cols-2">
          <SectionHeading
            eyebrow="Privacy first"
            title="Detection that never reads over your shoulder"
            body="Many scam filters send your messages to the cloud to be checked. ScamWatch does the work locally, so your conversations stay on your phone."
          />

          <motion.div {...fade} className="sr-surface overflow-hidden">
            <table className="w-full text-left">
              <caption className="sr-only">ScamWatch compared with cloud-based scam filters</caption>
              <thead>
                <tr className="border-b border-scam-line bg-scam-750/60">
                  <th scope="col" className="px-5 py-4 sr-label">Capability</th>
                  <th scope="col" className="px-4 py-4 text-center text-sm font-semibold text-trust-600 dark:text-trust-400">
                    ScamWatch
                  </th>
                  <th scope="col" className="px-4 py-4 text-center text-sm font-semibold text-scam-muted">
                    Cloud filters
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-scam-line">
                {PRIVACY_ROWS.map((row) => (
                  <tr key={row.label}>
                    <th scope="row" className="px-5 py-4 text-base font-medium text-scam-text">
                      {row.label}
                    </th>
                    {[row.us, row.them].map((value, i) => (
                      <td key={i} className="px-4 py-4 text-center">
                        {value ? (
                          <span className="inline-grid h-7 w-7 place-items-center rounded-full bg-verified-500/15 text-verified-700 dark:text-verified-400">
                            <Check size={16} aria-hidden />
                            <span className="sr-only">Yes</span>
                          </span>
                        ) : (
                          <span className="inline-grid h-7 w-7 place-items-center rounded-full bg-scam-750 text-scam-dim">
                            <X size={15} aria-hidden />
                            <span className="sr-only">No</span>
                          </span>
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </motion.div>
        </div>
      </section>

      {/* ===== HOW IT WORKS ===== */}
      <section className="border-b border-scam-line">
        <div className="mx-auto max-w-6xl px-6 py-24">
          <SectionHeading
            eyebrow="How it works"
            title="Three steps between you and a scammer"
            center
          />

          <ol className="relative mt-16 grid gap-10 sm:grid-cols-3 sm:gap-6">
            {/* Connector line */}
            <span
              aria-hidden
              className="absolute left-[16.66%] right-[16.66%] top-7 hidden h-px bg-gradient-to-r from-trust-500/10 via-trust-500/50 to-trust-500/10 sm:block"
            />
            {STEPS.map(({ icon: Icon, title, body }, i) => (
              <motion.li
                key={title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.1, ease: [0.22, 1, 0.36, 1] }}
                className="relative flex flex-col items-center text-center"
              >
                <span className="relative grid h-14 w-14 place-items-center rounded-2xl border border-scam-line bg-scam-800 text-trust-600 shadow-card dark:text-trust-400">
                  <Icon size={24} aria-hidden />
                  <span className="absolute -right-2 -top-2 grid h-6 w-6 place-items-center rounded-full bg-trust-600 text-xs font-bold text-white">
                    {i + 1}
                  </span>
                </span>
                <h3 className="mt-5 font-display text-xl font-semibold text-scam-text">{title}</h3>
                <p className="mt-2 max-w-xs text-pretty text-base leading-relaxed text-scam-muted">
                  {body}
                </p>
              </motion.li>
            ))}
          </ol>
        </div>
      </section>

      {/* ===== COMMUNITY + CTA ===== */}
      <section>
        <div className="mx-auto max-w-6xl px-6 py-24">
          <motion.div
            {...fade}
            className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-trust-700 via-trust-600 to-trust-700 px-8 py-14 text-white shadow-device sm:px-14"
          >
            <div className="pointer-events-none absolute inset-0 opacity-25 [background-image:radial-gradient(rgba(255,255,255,0.5)_1px,transparent_1px)] [background-size:22px_22px] [mask-image:linear-gradient(to_left,black,transparent_70%)]" />
            <ShieldCheck
              aria-hidden
              strokeWidth={1}
              className="pointer-events-none absolute -bottom-16 -right-10 h-80 w-80 text-white/10"
            />

            <div className="relative max-w-2xl">
              <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-trust-100">
                The ScamWatch community
              </span>
              <h2 className="mt-3 text-balance font-display text-3xl font-bold tracking-tight sm:text-5xl sm:leading-[1.05]">
                Every report makes everyone safer.
              </h2>
              <p className="mt-5 text-pretty text-lg leading-relaxed text-trust-50/90">
                Join the forum to share scams you&rsquo;ve spotted, learn the
                latest tactics, and help warn people before they get caught out.
              </p>
              <div className="mt-9 flex flex-wrap gap-3">
                <Link
                  to="/forum"
                  className="sw-btn-lg bg-white text-trust-700 shadow-button hover:bg-trust-50"
                >
                  Enter the forum <ArrowRight size={18} />
                </Link>
                <Link
                  to="/report"
                  className="sw-btn-lg border border-white/40 text-white hover:border-white hover:bg-white/10"
                >
                  Report a scam
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
