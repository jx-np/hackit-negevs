import { motion } from 'framer-motion';
import {
  ArrowRight,
  BellRing,
  Cpu,
  Database,
  Lock,
  ScanLine,
  ShieldCheck,
  Users,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { DeviceMockup } from '../components/landing/DeviceMockup';

const FEATURES = [
  {
    id: 'AI-01',
    icon: Cpu,
    title: 'On-device AI detection',
    body: 'ScamReg analyzes messages, calls, and links with AI models that run entirely on your device — no data leaves your phone to spot a scam.',
  },
  {
    id: 'REG-02',
    icon: Database,
    title: 'Centralized reporting',
    body: 'Report scams to a shared registry so the whole community is warned. Every report helps the models and other users stay ahead of new threats.',
  },
  {
    id: 'PRV-03',
    icon: Lock,
    title: 'Private by design',
    body: 'Because detection happens locally, your personal messages stay yours. Only the scam reports you choose to submit are ever shared.',
  },
  {
    id: 'ALT-04',
    icon: BellRing,
    title: 'Real-time warnings',
    body: 'Get instant alerts when a known scam pattern reaches you, backed by reports from thousands of other people.',
  },
];

const STEPS = [
  { icon: ScanLine, title: 'Scan', body: 'ScamReg checks incoming messages and links on your device.' },
  { icon: ShieldCheck, title: 'Detect', body: 'On-device AI flags anything that looks like a scam.' },
  { icon: Users, title: 'Report', body: 'Submit it to the shared registry to protect others.' },
];

const STATS = [
  { value: '12,431', label: 'Reports filed' },
  { value: '48', label: 'Scam categories' },
  { value: '99.2%', label: 'On-device' },
];

const fade = {
  initial: { opacity: 0, y: 16 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: '-60px' },
  transition: { duration: 0.5, ease: 'easeOut' as const },
};

export function LandingPage() {
  return (
    <div className="bg-paper dark:bg-ink-950">
      {/* ===== HERO — structured, security-grade ===== */}
      <section className="relative border-b border-ink-200 dark:border-ink-800">
        <div className="pointer-events-none absolute inset-0 ia-grid opacity-60" />

        <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-6 py-20 lg:grid-cols-[1.1fr_0.9fr] lg:py-28">
          {/* Left: label + headline + copy + CTAs */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
          >
            <div className="flex items-center gap-3">
              <span className="ia-label flex items-center gap-2 text-safe-700 dark:text-safe-400">
                <span className="h-2 w-2 rounded-full bg-safe-500" />
                Scam registry · live
              </span>
            </div>

            <h1 className="mt-6 font-display text-6xl font-bold leading-[0.95] tracking-tight text-ink-900 dark:text-white sm:text-7xl lg:text-8xl">
              ScamReg
            </h1>
            <p className="mt-6 max-w-xl text-xl leading-relaxed text-ink-600 dark:text-ink-300">
              On-device AI that identifies scams in real time, backed by a
              centralized registry that warns the whole community. Evidence, not
              guesswork.
            </p>

            <div className="mt-10 flex flex-wrap items-center gap-4">
              <Link
                to="/forum"
                className="inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
              >
                Enter the forum <ArrowRight size={18} />
              </Link>
              <Link
                to="/auth"
                className="inline-flex items-center gap-2 border border-ink-300 px-7 py-3.5 text-base font-semibold text-ink-800 transition hover:border-ink-900 dark:border-ink-700 dark:text-ink-100 dark:hover:border-white"
              >
                Sign in
              </Link>
            </div>

            {/* Registry stats row */}
            <dl className="mt-12 grid max-w-lg grid-cols-3 divide-x divide-ink-200 border-y border-ink-200 dark:divide-ink-800 dark:border-ink-800">
              {STATS.map((s) => (
                <div key={s.label} className="px-4 py-4 first:pl-0">
                  <dt className="font-mono text-2xl font-semibold text-ink-900 dark:text-white">
                    {s.value}
                  </dt>
                  <dd className="ia-label mt-1 text-ink-400">{s.label}</dd>
                </div>
              ))}
            </dl>
          </motion.div>

          {/* Right: device presented as a registry record */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut', delay: 0.1 }}
            className="ia-panel relative shadow-ia"
          >
            {/* Record header */}
            <div className="flex items-center justify-between border-b border-ink-200 px-4 py-2.5 dark:border-ink-800">
              <span className="ia-label text-ink-400">Record · SCAM-0421</span>
              <span className="ia-label inline-flex items-center gap-1.5 rounded-sm bg-risk-100 px-2 py-0.5 text-risk-700 dark:bg-risk-500/15 dark:text-risk-500">
                High risk
              </span>
            </div>

            <div className="flex justify-center px-6 py-8">
              <DeviceMockup />
            </div>

            {/* Verification footer */}
            <div className="flex items-center justify-between border-t border-ink-200 px-4 py-2.5 dark:border-ink-800">
              <span className="ia-label inline-flex items-center gap-1.5 text-safe-700 dark:text-safe-400">
                <ShieldCheck size={14} /> Verified on-device
              </span>
              <span className="ia-label text-ink-400">AI confidence 98%</span>
            </div>
          </motion.div>
        </div>
      </section>

      {/* ===== What is ScamReg ===== */}
      <section className="border-b border-ink-200 dark:border-ink-800">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <motion.div {...fade} className="max-w-3xl">
            <span className="ia-label text-safe-700 dark:text-safe-400">
              [ 00 ] About
            </span>
            <h2 className="mt-4 font-display text-4xl font-bold tracking-tight text-ink-900 dark:text-white sm:text-5xl">
              Your first line of defense against scams
            </h2>
            <p className="mt-5 text-xl leading-relaxed text-ink-600 dark:text-ink-300">
              ScamReg pairs private, on-device AI that identifies scams in real
              time with a centralized reporting system that warns the whole
              community. This forum is where members discuss threats, share
              tactics, and help each other stay safe.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ===== Feature grid — registry entries ===== */}
      <section className="border-b border-ink-200 dark:border-ink-800">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <motion.span {...fade} className="ia-label text-safe-700 dark:text-safe-400">
            [ 01 ] Capabilities
          </motion.span>
          <div className="mt-8 grid gap-px overflow-hidden border border-ink-200 bg-ink-200 dark:border-ink-800 dark:bg-ink-800 sm:grid-cols-2">
            {FEATURES.map(({ id, icon: Icon, title, body }, i) => (
              <motion.div
                key={title}
                initial={{ opacity: 0 }}
                whileInView={{ opacity: 1 }}
                viewport={{ once: true, margin: '-40px' }}
                transition={{ duration: 0.4, delay: i * 0.05 }}
                className="group bg-paper p-8 transition-colors hover:bg-white dark:bg-ink-950 dark:hover:bg-ink-900"
              >
                <div className="flex items-center justify-between">
                  <span className="grid h-12 w-12 place-items-center border border-ink-300 text-ink-800 transition group-hover:border-safe-500 group-hover:text-safe-600 dark:border-ink-700 dark:text-ink-100">
                    <Icon size={22} />
                  </span>
                  <span className="ia-label text-ink-300 dark:text-ink-600">
                    {id}
                  </span>
                </div>
                <h3 className="mt-5 font-display text-xl font-semibold text-ink-900 dark:text-white">
                  {title}
                </h3>
                <p className="mt-2 text-lg leading-relaxed text-ink-600 dark:text-ink-400">
                  {body}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== How it works ===== */}
      <section className="border-b border-ink-200 dark:border-ink-800">
        <div className="mx-auto max-w-6xl px-6 py-20">
          <motion.span {...fade} className="ia-label text-safe-700 dark:text-safe-400">
            [ 02 ] Process
          </motion.span>
          <div className="mt-8 grid gap-8 sm:grid-cols-3">
            {STEPS.map(({ icon: Icon, title, body }, i) => (
              <motion.div
                key={title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.08 }}
                className="border-t-2 border-ink-900 pt-5 dark:border-white"
              >
                <div className="flex items-center gap-3">
                  <span className="font-mono text-3xl font-semibold text-ink-900 dark:text-white">
                    0{i + 1}
                  </span>
                  <Icon size={22} className="text-safe-600 dark:text-safe-400" />
                </div>
                <h3 className="mt-4 font-display text-xl font-semibold text-ink-900 dark:text-white">
                  {title}
                </h3>
                <p className="mt-2 text-lg text-ink-600 dark:text-ink-400">
                  {body}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== CTA ===== */}
      <section>
        <div className="mx-auto max-w-6xl px-6 py-20">
          <motion.div
            {...fade}
            className="ia-panel flex flex-col items-start justify-between gap-8 p-10 shadow-ia lg:flex-row lg:items-center"
          >
            <div>
              <span className="ia-label text-safe-700 dark:text-safe-400">
                Join the registry
              </span>
              <h2 className="mt-3 font-display text-3xl font-bold tracking-tight text-ink-900 dark:text-white sm:text-4xl">
                Report a scam. Protect everyone.
              </h2>
              <p className="mt-3 max-w-xl text-lg text-ink-600 dark:text-ink-400">
                Explore the forum, learn from others' experiences, and share the
                scams you've spotted. Sign in to add your voice.
              </p>
            </div>
            <div className="flex shrink-0 flex-wrap gap-4">
              <Link
                to="/forum"
                className="inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
              >
                Enter the forum <ArrowRight size={18} />
              </Link>
              <Link
                to="/auth"
                className="inline-flex items-center gap-2 border border-ink-300 px-7 py-3.5 text-base font-semibold text-ink-800 transition hover:border-ink-900 dark:border-ink-700 dark:text-ink-100 dark:hover:border-white"
              >
                Sign in
              </Link>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
