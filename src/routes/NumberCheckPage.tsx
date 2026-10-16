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
    classes: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
    blurb: 'This number has a low trust score and may be associated with scams.',
  },
  trusted: {
    label: 'Trusted',
    icon: ShieldCheck,
    classes:
      'border-verified-500/40 bg-verified-500/10 text-verified-700 dark:text-verified-400',
    blurb: 'This number has a high trust score.',
  },
  unknown: {
    label: 'Unknown',
    icon: HelpCircle,
    classes: 'border-scam-line bg-scam-750 text-scam-muted',
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
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto w-full max-w-3xl px-5 py-10 lg:px-8">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <Search size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Registry lookup</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Number check
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              Enter a phone number to see its trust score and how many scam
              reports back it in the registry.
            </p>
          </div>
        </motion.div>

        {/* Lookup form */}
        <div className="sr-surface p-5 sm:p-6">
          <form onSubmit={onSubmit} className="flex flex-col gap-3 sm:flex-row">
            <div className="relative flex-1">
              <Search
                size={20}
                className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-scam-muted"
              />
              <input
                type="tel"
                inputMode="tel"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="e.g. +65 1234 5678 or 6512345678"
                aria-label="Phone number"
                aria-invalid={showValidationError}
                className={`w-full rounded-lg border bg-scam-750 py-3 pl-12 pr-4 text-lg text-scam-text outline-none transition placeholder:text-scam-muted focus:ring-2 ${
                  showValidationError
                    ? 'border-risk-high focus:border-risk-high focus:ring-risk-high/30'
                    : 'border-scam-line focus:border-trust-500 focus:ring-trust-500/30'
                }`}
              />
            </div>
            <button
              type="submit"
              disabled={!parsed.valid || isChecking}
              className="sr-btn-primary sr-focus px-6 py-3 text-base disabled:cursor-not-allowed disabled:opacity-50"
            >
              {isChecking ? 'Checking\u2026' : 'Check number'}
            </button>
          </form>

          {/* Inline validation message */}
          {showValidationError && (
            <p className="mt-2 text-sm font-medium text-risk-high">
              {parsed.error}
            </p>
          )}

          <p className="mt-3 text-xs text-scam-muted">
            The + prefix is optional — both forms match the same number.
          </p>
        </div>

        {/* Error */}
        {checkError && (
          <div className="mt-6 rounded-lg border border-risk-high/40 bg-risk-high/10 p-4 text-risk-high">
            <p className="sr-label text-risk-high">Error</p>
            <p className="mt-1 text-sm text-scam-text">{checkError.message}</p>
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
      className="sr-surface mt-8 overflow-hidden"
    >
      {/* Status header */}
      <div className={`flex items-center gap-4 border-b p-5 ${meta.classes}`}>
        <Icon size={36} />
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.14em] opacity-90">
            {meta.label}
          </p>
          <p className="text-2xl font-bold tracking-tight text-scam-text">
            {queried ?? result.number}
          </p>
        </div>
      </div>

      <div className="p-5">
        <p className="text-base leading-relaxed text-scam-muted">{meta.blurb}</p>

        {result.classification && (
          <p className="mt-3 inline-flex items-center gap-2 rounded-lg border border-scam-line bg-scam-750 px-3 py-1.5 text-sm text-scam-text">
            <span className="sr-label">Reported as</span>
            {result.classification}
          </p>
        )}

        {/* Stats */}
        <div className="mt-5 grid grid-cols-2 divide-x divide-scam-line overflow-hidden rounded-lg border border-scam-line bg-scam-850">
          <Stat
            label="Trust score"
            value={`${result.trustScore}/100`}
            tone={
              result.status === 'scam'
                ? 'text-risk-high'
                : result.status === 'trusted'
                  ? 'text-verified-700 dark:text-verified-400'
                  : undefined
            }
          />
          <Stat
            label="Scam reports"
            value={result.reportCount}
            tone="text-risk-high"
          />
        </div>

        {!result.known && (
          <p className="mt-3 text-xs text-scam-muted">
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
        className={`text-3xl font-bold tabular-nums ${
          tone ?? 'text-scam-text'
        }`}
      >
        {value}
      </p>
      <p className="sr-label mt-1">{label}</p>
    </div>
  );
}
