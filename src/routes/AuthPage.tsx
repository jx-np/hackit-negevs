import { AnimatePresence, motion } from 'framer-motion';
import { Database, ShieldCheck, UserRound, Users } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LoginForm } from '../components/auth/LoginForm';
import { SignupForm } from '../components/auth/SignupForm';
import { useAuth } from '../context/AuthContext';

type Mode = 'login' | 'signup';

const PERKS = [
  { icon: Users, text: 'Join 12,000+ members' },
  { icon: Database, text: 'Access the shared scam registry' },
  { icon: ShieldCheck, text: 'Your data stays on-device' },
];

export function AuthPage() {
  const [mode, setMode] = useState<Mode>('login');
  const [demoLoading, setDemoLoading] = useState(false);
  const [demoError, setDemoError] = useState<string | null>(null);
  const { login } = useAuth();
  const navigate = useNavigate();

  const continueAsDemo = async () => {
    setDemoLoading(true);
    setDemoError(null);
    try {
      await login('demo@gmail.com', 'xSFJ@2KyMQEKYa8');
      navigate('/report');
    } catch {
      setDemoError('Demo login failed. Please try again.');
    } finally {
      setDemoLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-paper dark:bg-ink-950">
      <div className="mx-auto grid min-h-[calc(100vh-140px)] max-w-5xl items-center gap-8 px-6 py-12 lg:grid-cols-2">
        {/* Showcase panel (hidden on small screens) */}
        <motion.aside
          initial={{ opacity: 0, x: -16 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className="relative hidden overflow-hidden bg-ink-900 p-10 text-white lg:block dark:border dark:border-ink-800"
        >
          <div className="pointer-events-none absolute inset-0 ia-grid opacity-30" />

          <div className="relative">
            <span className="grid h-12 w-12 place-items-center border border-white/30 text-white">
              <ShieldCheck size={24} />
            </span>
            <span className="ia-label mt-8 block text-safe-400">
              Secure access
            </span>
            <h2 className="mt-3 font-display text-3xl font-bold leading-tight">
              Report scams. Protect the community.
            </h2>
            <p className="mt-3 text-ink-300">
              Sign in to file reports, comment on records, and keep up with the
              scams other members have flagged.
            </p>

            <ul className="mt-10 space-y-4 border-t border-white/10 pt-8">
              {PERKS.map(({ icon: Icon, text }) => (
                <li key={text} className="flex items-center gap-3">
                  <span className="grid h-9 w-9 place-items-center border border-white/20 text-safe-400">
                    <Icon size={18} />
                  </span>
                  <span className="text-sm font-medium text-white/90">{text}</span>
                </li>
              ))}
            </ul>
          </div>
        </motion.aside>

        {/* Form panel */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, ease: 'easeOut' }}
          className="ia-panel mx-auto w-full max-w-md p-8 shadow-ia"
        >
          <div className="mb-6">
            <span className="ia-label text-safe-700 dark:text-safe-400">
              {mode === 'login' ? 'Sign in' : 'Register'}
            </span>
            <h1 className="mt-2 font-display text-2xl font-bold text-ink-900 dark:text-white">
              {mode === 'login' ? 'Welcome back' : 'Create your account'}
            </h1>
            <p className="mt-1 text-sm text-ink-500 dark:text-ink-400">
              {mode === 'login'
                ? 'Sign in to file reports and comment.'
                : 'Join the registry in a few seconds.'}
            </p>
          </div>

          {/* Mode toggle */}
          <div className="mb-6 flex border border-ink-200 dark:border-ink-800">
            {(['login', 'signup'] as Mode[]).map((m) => (
              <button
                key={m}
                type="button"
                onClick={() => setMode(m)}
                className={`relative flex-1 py-2.5 font-display text-xs font-semibold uppercase tracking-wider transition ${
                  mode === m
                    ? 'bg-ink-900 text-white dark:bg-white dark:text-ink-900'
                    : 'text-ink-500 hover:text-ink-900 dark:text-ink-400 dark:hover:text-white'
                }`}
              >
                {m === 'login' ? 'Sign in' : 'Sign up'}
              </button>
            ))}
          </div>

          <AnimatePresence mode="wait">
            <motion.div
              key={mode}
              initial={{ opacity: 0, x: mode === 'login' ? -12 : 12 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: mode === 'login' ? 12 : -12 }}
              transition={{ duration: 0.2 }}
            >
              {mode === 'login' ? <LoginForm /> : <SignupForm />}
            </motion.div>
          </AnimatePresence>

          {/* Demo access */}
          <div className="mt-6 border-t border-ink-200 pt-6 dark:border-ink-800">
            <button
              type="button"
              onClick={continueAsDemo}
              disabled={demoLoading}
              className="flex w-full items-center justify-center gap-2 border border-ink-300 py-3 text-base font-semibold text-ink-800 transition hover:border-safe-500 hover:text-safe-700 disabled:cursor-not-allowed disabled:opacity-60 dark:border-ink-700 dark:text-ink-100 dark:hover:text-safe-400"
            >
              <UserRound size={18} />
              {demoLoading ? 'Signing in…' : 'Continue as demo user'}
            </button>
            {demoError && (
              <p className="mt-2 text-center text-xs text-red-500">{demoError}</p>
            )}
            {!demoError && (
              <p className="mt-2 text-center text-xs text-ink-400">
                Explore reporting without an account
              </p>
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
}
