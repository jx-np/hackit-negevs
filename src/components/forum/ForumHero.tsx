import { motion } from 'framer-motion';
import { Sparkles, TrendingUp, Users } from 'lucide-react';

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.08, delayChildren: 0.05 },
  },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: 'easeOut' as const },
  },
};

const STATS = [
  { icon: Users, label: 'Members', value: '12.4k' },
  { icon: TrendingUp, label: 'Posts today', value: '340' },
  { icon: Sparkles, label: 'Active tags', value: '48' },
];

export function ForumHero() {
  return (
    <section className="relative overflow-hidden">
      {/* Decorative gradient mesh + floating blobs */}
      <div className="pointer-events-none absolute inset-0 bg-mesh-light dark:bg-mesh-dark" />
      <div className="pointer-events-none absolute -left-20 top-10 h-64 w-64 rounded-full bg-brand-400/20 blur-3xl animate-float" />
      <div
        className="pointer-events-none absolute -right-20 top-0 h-72 w-72 rounded-full bg-accent-400/20 blur-3xl animate-float"
        style={{ animationDelay: '2s' }}
      />

      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="relative mx-auto max-w-4xl px-4 pb-10 pt-16 text-center sm:pt-24"
      >
        <motion.span
          variants={item}
          className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-white/60 px-4 py-1.5 text-sm font-medium text-brand-700 backdrop-blur dark:border-brand-800 dark:bg-slate-900/60 dark:text-brand-300"
        >
          <Sparkles size={15} />
          Welcome to the community
        </motion.span>

        <motion.h1
          variants={item}
          className="mt-6 text-4xl font-extrabold tracking-tight sm:text-6xl"
        >
          Where developers <span className="text-gradient">talk shop</span>
        </motion.h1>

        <motion.p
          variants={item}
          className="mx-auto mt-4 max-w-2xl text-lg text-slate-600 dark:text-slate-400"
        >
          Search thousands of discussions, filter by topic, and join
          conversations on the tools and techniques shaping modern development.
        </motion.p>

        <motion.div
          variants={item}
          className="mt-10 flex flex-wrap items-center justify-center gap-3 sm:gap-6"
        >
          {STATS.map(({ icon: Icon, label, value }) => (
            <div
              key={label}
              className="flex items-center gap-3 rounded-2xl border border-slate-200/60 bg-white/60 px-5 py-3 backdrop-blur dark:border-slate-800/60 dark:bg-slate-900/60"
            >
              <span className="grid h-10 w-10 place-items-center rounded-xl bg-brand-100 text-brand-600 dark:bg-brand-900/40 dark:text-brand-300">
                <Icon size={20} />
              </span>
              <div className="text-left">
                <p className="text-lg font-bold leading-none">{value}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {label}
                </p>
              </div>
            </div>
          ))}
        </motion.div>
      </motion.div>
    </section>
  );
}
