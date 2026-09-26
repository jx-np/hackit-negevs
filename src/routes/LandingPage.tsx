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
import { DeviceMockup, PopOutCard } from '../components/landing/DeviceMockup';

const FEATURES = [
  {
    icon: Cpu,
    title: 'On-device AI detection',
    body: 'ScamReg analyzes messages, calls, and links with AI models that run entirely on your device — no data leaves your phone to spot a scam.',
  },
  {
    icon: Database,
    title: 'Centralized reporting',
    body: 'Report scams to a shared registry so the whole community is warned. Every report helps the models and other users stay ahead of new threats.',
  },
  {
    icon: Lock,
    title: 'Private by design',
    body: 'Because detection happens locally, your personal messages stay yours. Only the scam reports you choose to submit are ever shared.',
  },
  {
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

export function LandingPage() {
  return (
    <div>
      {/* ===== HERO (static — no scroll animation) ===== */}
      <section className="relative overflow-hidden">
        {/* Background mesh + soft blobs */}
        <div className="pointer-events-none absolute inset-0 bg-mesh-light dark:bg-mesh-dark" />
        <div className="pointer-events-none absolute left-1/4 top-10 h-72 w-72 -translate-x-1/2 rounded-full bg-brand-400/20 blur-3xl" />
        <div className="pointer-events-none absolute right-1/4 top-24 h-80 w-80 translate-x-1/2 rounded-full bg-accent-400/20 blur-3xl" />

        <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-6 py-20 lg:grid-cols-2 lg:py-28">
          {/* Left: title + copy + CTAs */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: 'easeOut' }}
            className="text-center lg:text-left"
          >
            <span className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-white/60 px-4 py-1.5 text-sm font-semibold text-brand-700 backdrop-blur dark:border-brand-800 dark:bg-slate-900/60 dark:text-brand-300">
              <ShieldCheck size={15} /> On-device AI scam protection
            </span>

            <h1 className="mt-6 text-6xl font-black tracking-tighter sm:text-7xl lg:text-8xl">
              <span className="text-gradient">ScamReg</span>
            </h1>
            <p className="mx-auto mt-4 max-w-xl text-xl text-slate-600 dark:text-slate-300 lg:mx-0">
              Spot scams with on-device AI. Report them to a shared registry and
              protect everyone.
            </p>

            <div className="mt-10 flex flex-wrap items-center justify-center gap-4 lg:justify-start">
              <Link
                to="/forum"
                className="inline-flex items-center gap-2 rounded-2xl bg-brand-600 px-8 py-4 text-lg font-bold text-white shadow-soft transition hover:scale-[1.03] hover:bg-brand-700"
              >
                Enter the forum <ArrowRight size={20} />
              </Link>
              <Link
                to="/auth"
                className="inline-flex items-center gap-2 rounded-2xl border-2 border-slate-300 px-8 py-4 text-lg font-bold text-slate-700 transition hover:border-brand-400 hover:text-brand-600 dark:border-slate-700 dark:text-slate-200 dark:hover:text-brand-300"
              >
                Sign in
              </Link>
            </div>
          </motion.div>

          {/* Right: static device mockup with the detection card beside it */}
          <motion.div
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, ease: 'easeOut', delay: 0.1 }}
            className="relative mx-auto"
          >
            <DeviceMockup />
            <div className="absolute -right-6 top-16 z-10 hidden sm:block lg:-right-10">
              <PopOutCard />
            </div>
          </motion.div>
        </div>
      </section>

      {/* ===== What is ScamReg ===== */}
      <section className="mx-auto max-w-6xl px-6 py-20 text-center">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6 }}
        >
          <span className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-brand-50 px-4 py-1.5 text-sm font-semibold text-brand-700 dark:border-brand-800 dark:bg-brand-900/30 dark:text-brand-300">
            <ShieldCheck size={16} /> What is ScamReg?
          </span>
          <h2 className="mx-auto mt-6 max-w-3xl text-3xl font-bold tracking-tight sm:text-5xl">
            Your first line of defense against{' '}
            <span className="text-gradient">scams</span>
          </h2>
          <p className="mx-auto mt-5 max-w-2xl text-lg text-slate-600 dark:text-slate-400 sm:text-xl">
            ScamReg combines private, on-device AI that identifies scams in real
            time with a centralized reporting system that warns the whole
            community. This forum is where members discuss threats, share
            tactics, and help each other stay safe.
          </p>
        </motion.div>
      </section>

      {/* ===== Feature grid ===== */}
      <section className="mx-auto max-w-6xl px-6 pb-8">
        <div className="grid gap-6 sm:grid-cols-2">
          {FEATURES.map(({ icon: Icon, title, body }, i) => (
            <motion.div
              key={title}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-60px' }}
              transition={{ duration: 0.5, delay: i * 0.05 }}
              className="group rounded-3xl border border-slate-200 bg-white p-8 shadow-sm transition hover:shadow-glow dark:border-slate-800 dark:bg-slate-900"
            >
              <span className="grid h-14 w-14 place-items-center rounded-2xl bg-brand-gradient text-white shadow-soft">
                <Icon size={26} />
              </span>
              <h3 className="mt-5 text-xl font-bold">{title}</h3>
              <p className="mt-2 text-lg leading-relaxed text-slate-600 dark:text-slate-400">
                {body}
              </p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* ===== How it works ===== */}
      <section className="mx-auto max-w-6xl px-6 py-20">
        <h2 className="text-center text-3xl font-bold tracking-tight sm:text-4xl">
          How it works
        </h2>
        <div className="mt-12 grid gap-8 sm:grid-cols-3">
          {STEPS.map(({ icon: Icon, title, body }, i) => (
            <motion.div
              key={title}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
              className="relative text-center"
            >
              <span className="mx-auto grid h-16 w-16 place-items-center rounded-2xl bg-white text-brand-600 shadow-soft ring-1 ring-slate-200 dark:bg-slate-900 dark:text-brand-300 dark:ring-slate-800">
                <Icon size={28} />
              </span>
              <div className="mt-2 text-sm font-bold text-brand-500">
                Step {i + 1}
              </div>
              <h3 className="mt-1 text-xl font-bold">{title}</h3>
              <p className="mt-2 text-lg text-slate-600 dark:text-slate-400">
                {body}
              </p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* ===== CTA ===== */}
      <section className="mx-auto max-w-6xl px-6 pb-24">
        <motion.div
          initial={{ opacity: 0, scale: 0.97 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="relative overflow-hidden rounded-[2.5rem] bg-brand-gradient px-8 py-16 text-center text-white shadow-glow"
        >
          <div className="pointer-events-none absolute -right-10 -top-10 h-52 w-52 rounded-full bg-white/10 blur-3xl" />
          <h2 className="relative text-3xl font-bold sm:text-5xl">
            Join the ScamReg community
          </h2>
          <p className="relative mx-auto mt-4 max-w-2xl text-lg text-white/90 sm:text-xl">
            Explore the forum, learn from others' experiences, and share the
            scams you've spotted. Sign in to add your voice.
          </p>
          <div className="relative mt-10 flex flex-wrap items-center justify-center gap-4">
            <Link
              to="/forum"
              className="inline-flex items-center gap-2 rounded-2xl bg-white px-8 py-4 text-lg font-bold text-brand-700 shadow-lg transition hover:scale-[1.03] hover:shadow-xl"
            >
              Enter the forum <ArrowRight size={20} />
            </Link>
            <Link
              to="/auth"
              className="inline-flex items-center gap-2 rounded-2xl border-2 border-white/60 px-8 py-4 text-lg font-bold text-white transition hover:bg-white/10"
            >
              Sign in
            </Link>
          </div>
        </motion.div>
      </section>
    </div>
  );
}
