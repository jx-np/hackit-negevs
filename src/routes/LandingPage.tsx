import { motion, useScroll, useTransform } from 'framer-motion';
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
import { useRef } from 'react';
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
  const heroRef = useRef<HTMLDivElement>(null);

  // Scroll progress across the hero drives the "pop out of device" animation.
  const { scrollYProgress } = useScroll({
    target: heroRef,
    offset: ['start start', 'end start'],
  });

  // The device scales up and drifts as you scroll through the hero.
  const deviceScale = useTransform(scrollYProgress, [0, 0.6], [1, 1.35]);
  const deviceY = useTransform(scrollYProgress, [0, 0.6], [0, -40]);
  // The huge "ScamReg" title lifts and fades as the app takes over.
  const titleY = useTransform(scrollYProgress, [0, 0.5], [0, -120]);
  const titleOpacity = useTransform(scrollYProgress, [0, 0.4], [1, 0]);
  // The app "pops out" of the screen: rises, scales, and fades in.
  const popY = useTransform(scrollYProgress, [0.05, 0.55], [40, -150]);
  const popScale = useTransform(scrollYProgress, [0.05, 0.55], [0.6, 1.1]);
  const popOpacity = useTransform(scrollYProgress, [0.05, 0.25, 0.9], [0, 1, 1]);

  return (
    <div>
      {/* ===== HERO with scroll-driven pop-out animation =====
          Tall section so there is scroll distance to drive the animation. */}
      <section ref={heroRef} className="relative h-[200vh]">
        <div className="sticky top-0 flex h-screen flex-col items-center justify-center overflow-hidden">
          {/* Background mesh + blobs */}
          <div className="pointer-events-none absolute inset-0 bg-mesh-light dark:bg-mesh-dark" />
          <div className="pointer-events-none absolute left-1/4 top-1/4 h-72 w-72 -translate-x-1/2 rounded-full bg-brand-400/20 blur-3xl animate-float" />
          <div
            className="pointer-events-none absolute right-1/4 top-1/3 h-80 w-80 translate-x-1/2 rounded-full bg-accent-400/20 blur-3xl animate-float"
            style={{ animationDelay: '2s' }}
          />

          {/* Huge ScamReg title, in front */}
          <motion.h1
            style={{ y: titleY, opacity: titleOpacity }}
            className="pointer-events-none relative z-20 select-none text-center text-6xl font-black tracking-tighter sm:text-8xl lg:text-[10rem]"
          >
            <span className="text-gradient">ScamReg</span>
          </motion.h1>
          <motion.p
            style={{ opacity: titleOpacity }}
            className="relative z-20 mt-2 max-w-xl px-4 text-center text-lg text-slate-600 dark:text-slate-300 sm:text-xl"
          >
            Spot scams with on-device AI. Report them to protect everyone.
          </motion.p>

          {/* Device (first frame sits under the title) */}
          <motion.div
            style={{ scale: deviceScale, y: deviceY }}
            className="relative z-10 mt-10"
          >
            <DeviceMockup />

            {/* The app popping out of the device */}
            <motion.div
              style={{ y: popY, scale: popScale, opacity: popOpacity }}
              className="absolute -right-8 top-16 z-30 sm:-right-24"
            >
              <PopOutCard />
            </motion.div>
          </motion.div>

          {/* Scroll hint */}
          <motion.div
            style={{ opacity: titleOpacity }}
            className="absolute bottom-8 flex flex-col items-center gap-2 text-sm text-slate-400"
          >
            <span>Scroll to see it in action</span>
            <span className="h-8 w-5 rounded-full border-2 border-slate-300 dark:border-slate-600">
              <span className="mx-auto mt-1.5 block h-1.5 w-1.5 animate-bounce rounded-full bg-slate-400" />
            </span>
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
