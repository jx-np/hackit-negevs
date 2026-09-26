import { motion } from 'framer-motion';
import {
  CheckCircle2,
  HelpCircle,
  LogIn,
  Search,
  ShieldAlert,
  ShieldCheck,
} from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useNumberCheck } from '../hooks/useNumberCheck';
import { parsePhone } from '../lib/phone';
import type { NumberCheckResult, NumberStatus } from '../types';

const STATUS_META: Record<
  NumberStatus,
  { label: string; icon: typeof ShieldCheck; classes: string; blurb: string }
> = {
  scam: {
    label: 'Reported scam',
    icon: ShieldAlert,
    classes:
      'border-risk-500 bg-risk-50 text-risk-700 dark:bg-risk-500/10 dark:text-risk-500',
    blurb: 'The community has flagged this number as a scam.',
  },
  trusted: {
    label: 'Trusted',
    icon: ShieldCheck,
    classes:
      'border-safe-500 bg-safe-50 text-safe-700 dark:bg-safe-500/10 dark:text-safe-400',
    blurb: 'This number is mostly reported as legitimate.',
  },
  unknown: {
    label: 'Unknown',
    icon: HelpCircle,
    classes:
      'border-ink-300 bg-ink-50 text-ink-600 dark:border-ink-700 dark:bg-ink-800/60 dark:text-ink-300',
    blurb: 'No reports yet. Be the first to add what you know.',
  },
};

export function NumberCheckPage() {
  const [input, setInput] = useState('');
  const {
    result,
    queried,
    check,
    isChecking,
    checkError,
    submitReport,
    isReporting,
    reportedKind,
  } = useNumberCheck();

  const parsed = parsePhone(input);
  const showValidationError = input.trim().length > 0 && !parsed.valid;

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (parsed.valid) check(input);
  };

  return (
    <div className="min-h-screen bg-paper dark:bg-ink-950">
      <div className="mx-auto w-full max-w-3xl px-6 py-12">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-4 border-b border-ink-200 pb-6 dark:border-ink-800"
        >
          <span className="grid h-14 w-14 place-items-center bg-ink-900 text-white dark:bg-white dark:text-ink-900">
            <Search size={26} />
          </span>
          <div>
            <span className="ia-label text-safe-700 dark:text-safe-400">
              Registry lookup
            </span>
            <h1 className="mt-1 font-display text-3xl font-bold tracking-tight text-ink-900 dark:text-white sm:text-4xl">
              Number check
            </h1>
          </div>
        </motion.div>

        <p className="mb-6 text-lg text-ink-600 dark:text-ink-400">
          Enter a phone number to see how many times it's been reported and
          whether the community considers it trusted, a scam, or unknown.
        </p>

        {/* Lookup form */}
        <form onSubmit={onSubmit} className="flex flex-col gap-3 sm:flex-row">
          <div className="relative flex-1">
            <Search
              size={20}
              className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-ink-400"
            />
            <input
              type="tel"
              inputMode="tel"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="e.g. +1 800 555 1234 or 8005551234"
              aria-label="Phone number"
              aria-invalid={showValidationError}
              className={`w-full border bg-white py-3.5 pl-12 pr-4 text-lg text-ink-900 outline-none transition placeholder:text-ink-400 focus:ring-2 dark:bg-ink-900 dark:text-white ${
                showValidationError
                  ? 'border-risk-500 focus:border-risk-500 focus:ring-risk-500/30'
                  : 'border-ink-300 focus:border-safe-500 focus:ring-safe-500/30 dark:border-ink-700'
              }`}
            />
          </div>
          <button
            type="submit"
            disabled={!parsed.valid || isChecking}
            className="border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 disabled:opacity-50 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
          >
            {isChecking ? 'Checking…' : 'Check number'}
          </button>
        </form>

        {/* Inline validation message */}
        {showValidationError && (
          <p className="mt-2 font-mono text-sm text-risk-600 dark:text-risk-500">
            {parsed.error}
          </p>
        )}

        {/* Try-these hint (+ prefix optional — both forms match the same number) */}
        <p className="mt-3 font-mono text-xs text-ink-400">
          Try: +18005551234 or 18005551234 (scam) · +441632960000 (trusted) ·
          the + prefix is optional
        </p>

        {/* Error */}
        {checkError && (
          <div className="mt-6 border border-risk-500 bg-risk-50 p-4 text-risk-700 dark:bg-risk-500/10 dark:text-risk-500">
            <p className="ia-label">Error</p>
            <p className="mt-1 font-mono text-sm">{checkError.message}</p>
          </div>
        )}

        {/* Result */}
        {result && !isChecking && (
          <ResultCard
            result={result}
            queried={queried}
            onReport={submitReport}
            isReporting={isReporting}
            reportedKind={reportedKind}
          />
        )}
      </div>
    </div>
  );
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function ResultCard({
  result,
  queried,
  onReport,
  isReporting,
  reportedKind,
}: {
  result: NumberCheckResult;
  queried: string | null;
  onReport: (input: string, kind: 'scam' | 'trusted') => void;
  isReporting: boolean;
  reportedKind: 'scam' | 'trusted' | null;
}) {
  const { isLoggedIn } = useAuth();
  const meta = STATUS_META[result.status];
  const Icon = meta.icon;
  const lookupInput = queried ?? result.number;

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="mt-8 ia-panel shadow-ia"
    >
      {/* Status header */}
      <div className={`flex items-center gap-4 border-b p-5 ${meta.classes}`}>
        <Icon size={36} />
        <div>
          <p className="ia-label opacity-80">{meta.label}</p>
          <p className="font-display text-2xl font-bold">{result.number}</p>
        </div>
      </div>

      <div className="p-5">
        <p className="text-lg text-ink-600 dark:text-ink-300">{meta.blurb}</p>

        {/* Counts */}
        <div className="mt-5 grid grid-cols-3 divide-x divide-ink-200 border border-ink-200 dark:divide-ink-800 dark:border-ink-800">
          <Stat label="Total reports" value={result.counts.total} />
          <Stat
            label="Scam"
            value={result.counts.scam}
            tone="text-risk-600 dark:text-risk-500"
          />
          <Stat
            label="Trusted"
            value={result.counts.trusted}
            tone="text-safe-700 dark:text-safe-400"
          />
        </div>

        {result.lastReportedAt && (
          <p className="mt-3 font-mono text-xs text-ink-400">
            Last reported {formatDate(result.lastReportedAt)}
          </p>
        )}

        {/* Report action (login-gated) */}
        <div className="mt-6 border-t border-ink-200 pt-5 dark:border-ink-800">
          <p className="ia-label mb-3 text-ink-500 dark:text-ink-400">
            Add your report
          </p>

          {isLoggedIn ? (
            <div className="flex flex-col gap-3 sm:flex-row">
              <button
                type="button"
                onClick={() => onReport(lookupInput, 'scam')}
                disabled={isReporting}
                className="flex flex-1 items-center justify-center gap-2 border border-risk-600 bg-risk-600 px-5 py-3 text-base font-semibold text-white transition hover:bg-risk-700 disabled:opacity-50"
              >
                <ShieldAlert size={18} />
                {isReporting && reportedKind === 'scam'
                  ? 'Reporting…'
                  : 'Report as scam'}
              </button>
              <button
                type="button"
                onClick={() => onReport(lookupInput, 'trusted')}
                disabled={isReporting}
                className="flex flex-1 items-center justify-center gap-2 border border-safe-600 px-5 py-3 text-base font-semibold text-safe-700 transition hover:bg-safe-50 disabled:opacity-50 dark:text-safe-400 dark:hover:bg-safe-500/10"
              >
                <CheckCircle2 size={18} /> Mark as trusted
              </button>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-3 border border-dashed border-ink-300 bg-ink-50 p-5 text-center dark:border-ink-700 dark:bg-ink-900/50 sm:flex-row sm:justify-between sm:text-left">
              <p className="text-base text-ink-600 dark:text-ink-300">
                <span className="font-semibold text-ink-900 dark:text-white">
                  Log in to report
                </span>{' '}
                this number to the registry.
              </p>
              <Link
                to="/auth"
                className="inline-flex shrink-0 items-center gap-2 border border-ink-900 bg-ink-900 px-5 py-2.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
              >
                <LogIn size={18} /> Log in
              </Link>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  );
}

function Stat({
  label,
  value,
  tone,
}: {
  label: string;
  value: number;
  tone?: string;
}) {
  return (
    <div className="p-4 text-center">
      <p
        className={`font-mono text-3xl font-bold ${
          tone ?? 'text-ink-900 dark:text-white'
        }`}
      >
        {value}
      </p>
      <p className="ia-label mt-1 text-ink-400">{label}</p>
    </div>
  );
}
