import { AnimatePresence, motion } from 'framer-motion';
import { useState } from 'react';
import { LoginForm } from '../components/auth/LoginForm';
import { SignupForm } from '../components/auth/SignupForm';

type Mode = 'login' | 'signup';

export function AuthPage() {
  const [mode, setMode] = useState<Mode>('login');

  return (
    <div className="mx-auto flex min-h-[calc(100vh-64px)] max-w-md flex-col justify-center px-4 py-12">
      <motion.div
        initial={{ opacity: 0, y: 20, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.5, ease: 'easeOut' }}
        className="rounded-3xl border border-slate-200 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900"
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
        <div className="mb-6 flex rounded-xl bg-slate-100 p-1 dark:bg-slate-800">
          {(['login', 'signup'] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMode(m)}
              className={`flex-1 rounded-lg py-2 text-sm font-medium transition ${
                mode === m
                  ? 'bg-white text-brand-600 shadow-sm dark:bg-slate-700 dark:text-brand-300'
                  : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
              }`}
            >
              {m === 'login' ? 'Sign in' : 'Sign up'}
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
