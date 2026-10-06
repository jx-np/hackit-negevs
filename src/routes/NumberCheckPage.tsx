import { motion } from 'framer-motion';
import {
  HelpCircle,
  Search,
  ShieldAlert,
  ShieldCheck,
} from 'lucide-react';
import { useState } from 'react';
import { useNumberCheck } from '../hooks/useNumberCheck';
import { parsePhone } from '../lib/phone';
import type { NumberCheckResult, NumberStatus } from '../types';

const STATUS_META: Record<
  NumberStatus,
  { label: string; icon: typeof ShieldCheck; classes: string; blurb: string }
> = {
  scam: {
    label: 'High risk',
    icon: ShieldAlert,
    classes:
      'border-risk-500 bg-risk-50 text-risk-700 dark:bg-risk-500/10 dark:text-risk-500',
    blurb: 'This number has a low trust score and may be associated with scams.',
  },
  trusted: {
    label: 'Trusted',
    icon: ShieldCheck,
    classes:
      'border-safe-500 bg-safe-50 text-safe-700 dark:bg-safe-500/10 dark:text-safe-400',
    blurb: 'This number has a high trust score.',
  },
  unknown: {
    label: 'Unknown',
    icon: HelpCircle,
    classes:
      'border-ink-300 bg-ink-50 text-ink-600 dark:border-ink-700 dark:bg-ink-800/60 dark:text-ink-300',
    blurb:
      'We don\u2019t have enough information to assess this number. Stay cautious.',
  },
};

export function NumberCheckPage() {
  const [input, setInput] = useState('');
  const { result, queried, check, isChecking, checkError } = useNumberCheck();

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
          Enter a phone number to see its trust score and how many scam reports
          back it in the registry.
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
              placeholder="e.g. +65 1234 5678 or 6512345678"
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
            {isChecking ? 'Checking\u2026' : 'Check number'}
          </button>
        </form>

        {/* Inline validation message */}
        {showValidationError && (
          <p className="mt-2 text-sm text-risk-600 dark:text-risk-500">
            {parsed.error}
          </p>
        )}

        <p className="mt-3 text-xs text-ink-400">
          The + prefix is optional — both forms match the same number.
        </p>

        {/* Error */}
        {checkError && (
          <div className="mt-6 border border-risk-500 bg-risk-50 p-4 text-risk-700 dark:bg-risk-500/10 dark:text-risk-500">
            <p className="ia-label">Error</p>
            <p className="mt-1 text-sm">{checkError.message}</p>
          </div>
        )}

        {/* Result */}
        {result && !isChecking && (
          <ResultCard result={result} queried={queried} />
        )}
      </div>
    </div>
  );
}

function ResultCard({
  result,
  queried,
}: {
  result: NumberCheckResult;
  queried: string | null;
}) {
  const meta = STATUS_META[result.status];
  const Icon = meta.icon;

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
          <p className="font-display text-2xl font-bold">
            {queried ?? result.number}
          </p>
        </div>
      </div>

      <div className="p-5">
        <p className="text-lg text-ink-600 dark:text-ink-300">{meta.blurb}</p>

        {/* Stats */}
        <div className="mt-5 grid grid-cols-2 divide-x divide-ink-200 border border-ink-200 dark:divide-ink-800 dark:border-ink-800">
          <Stat
            label="Trust score"
            value={`${result.trustScore}/100`}
            tone={
              result.status === 'scam'
                ? 'text-risk-600 dark:text-risk-500'
                : result.status === 'trusted'
                  ? 'text-safe-700 dark:text-safe-400'
                  : undefined
            }
          />
          <Stat
            label="Scam reports"
            value={result.reportCount}
            tone="text-risk-600 dark:text-risk-500"
          />
        </div>

        {!result.known && (
          <p className="mt-3 text-xs text-ink-400">
            This number isn’t in the database yet — showing the neutral
            default score.
          </p>
        )}
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
  value: number | string;
  tone?: string;
}) {
  return (
    <div className="p-4 text-center">
      <p
        className={`font-display text-3xl font-bold ${
          tone ?? 'text-ink-900 dark:text-white'
        }`}
      >
        {value}
      </p>
      <p className="ia-label mt-1 text-ink-400">{label}</p>
    </div>
  );
}
