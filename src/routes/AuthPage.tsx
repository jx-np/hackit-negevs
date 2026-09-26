import { AnimatePresence, motion } from 'framer-motion';
import { MessagesSquare, ShieldCheck, Sparkles, Users } from 'lucide-react';
import { useState } from 'react';
import { LoginForm } from '../components/auth/LoginForm';
import { SignupForm } from '../components/auth/SignupForm';

type Mode = 'login' | 'signup';

const PERKS = [
  { icon: Users, text: 'Join 12,000+ developers' },
  { icon: Sparkles, text: 'Follow topics you care about' },
  { icon: ShieldCheck, text: 'Your data stays private' },
];

export function AuthPage() {
  const [mode, setMode] = useState<Mode>('login');

  return (
    <div className="mx-auto grid min-h-[calc(100vh-140px)] max-w-5xl items-center gap-8 px-4 py-12 lg:grid-cols-2">
      {/* Branded showcase panel (hidden on small screens) */}
      <motion.aside
        initial={{ opacity: 0, x: -24 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6, ease: 'easeOut' }}
        className="relative hidden overflow-hidden rounded-3xl bg-brand-gradient p-10 text-white shadow-glow lg:block"
      >
        <div className="pointer-events-none absolute -right-10 -top-10 h-48 w-48 rounded-full bg-white/10 blur-2xl animate-float" />
        <div className="pointer-events-none absolute bottom-0 left-0 h-40 w-40 rounded-full bg-black/10 blur-2xl" />

        <span className="grid h-12 w-12 place-items-center rounded-2xl bg-white/20 backdrop-blur">
          <MessagesSquare size={24} />
        </span>
        <h2 className="mt-8 text-3xl font-bold leading-tight">
          Join the conversation shaping modern development.
        </h2>
        <p className="mt-3 text-white/80">
          Ask questions, share what you know, and keep up with the tools and
          ideas moving the community forward.
        </p>

        <ul className="mt-10 space-y-4">
          {PERKS.map(({ icon: Icon, text }) => (
            <li key={text} className="flex items-center gap-3">
              <span className="grid h-9 w-9 place-items-center rounded-xl bg-white/15 backdrop-blur">
                <Icon size={18} />
              </span>
              <span className="text-sm font-medium text-white/90">{text}</span>
            </li>
          ))}
        </ul>
      </motion.aside>

      {/* Form panel */}
      <motion.div
        initial={{ opacity: 0, y: 20, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.5, ease: 'easeOut' }}
        className="mx-auto w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900"
      >
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold">
            {mode === 'login' ? 'Welcome back' : 'Create your account'}
          </h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {mode === 'login'
              ? 'Sign in to join the conversation.'
              : 'Join the community in a few seconds.'}
          </p>
        </div>

        {/* Mode toggle */}
        <div className="relative mb-6 flex rounded-xl bg-slate-100 p-1 dark:bg-slate-800">
          {(['login', 'signup'] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMode(m)}
              className="relative flex-1 rounded-lg py-2 text-sm font-medium transition"
            >
              {mode === m && (
                <motion.span
                  layoutId="auth-toggle"
                  className="absolute inset-0 rounded-lg bg-white shadow-sm dark:bg-slate-700"
                  transition={{ type: 'spring', duration: 0.4 }}
                />
              )}
              <span
                className={`relative z-10 ${
                  mode === m
                    ? 'text-brand-600 dark:text-brand-300'
                    : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
                }`}
              >
                {m === 'login' ? 'Sign in' : 'Sign up'}
              </span>
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={mode}
            initial={{ opacity: 0, x: mode === 'login' ? -16 : 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: mode === 'login' ? 16 : -16 }}
            transition={{ duration: 0.25 }}
          >
            {mode === 'login' ? <LoginForm /> : <SignupForm />}
          </motion.div>
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
