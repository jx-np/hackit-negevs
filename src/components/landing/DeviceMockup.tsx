import { AnimatePresence, motion } from 'framer-motion';
import {
  Link2,
  Lock,
  MessageSquareText,
  Phone,
  ScanLine,
  ShieldCheck,
  TriangleAlert,
} from 'lucide-react';
import type { HeroPhase } from './useHeroSequence';

/**
 * Illustrative phone mockup for the landing hero.
 *
 * The screen is an in-app UI rendering (not a real screenshot): it shows the
 * ScamWatch inbox mid-scan, with one message flagged as high risk. To use a
 * real screenshot later, replace <AppScreen /> with an <img>.
 *
 * Purely decorative — hidden from assistive tech; the hero copy carries the
 * meaning.
 */
export function DeviceMockup({ phase = 'app' }: { phase?: HeroPhase }) {
  return (
    <div className="relative mx-auto w-[272px] sm:w-[300px]" aria-hidden>
      {/* Device frame */}
      <div className="relative rounded-[2.9rem] bg-gradient-to-b from-slate-700 to-slate-900 p-[10px] shadow-device ring-1 ring-black/10">
        {/* Side buttons */}
        <span className="absolute -left-[3px] top-28 h-12 w-[3px] rounded-l bg-slate-700" />
        <span className="absolute -right-[3px] top-36 h-20 w-[3px] rounded-r bg-slate-700" />

        <div className="relative aspect-[9/19.5] overflow-hidden rounded-[2.3rem] bg-white dark:bg-[#0b111c]">
          {/* Dynamic island */}
          <div className="absolute left-1/2 top-2.5 z-20 h-6 w-24 -translate-x-1/2 rounded-full bg-black" />
          <AnimatePresence initial={false}>
            {phase === 'app' ? (
              <motion.div
                key="app"
                className="absolute inset-0"
                initial={{ opacity: 0, scale: 1.04 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.5 }}
              >
                <AppScreen />
              </motion.div>
            ) : (
              <motion.div
                key="lock"
                className="absolute inset-0"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.4 }}
              >
                <LockScreen phase={phase} />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
}

/** Lock screen: scam SMS arrives, ScamWatch scans it and flags it. */
function LockScreen({ phase }: { phase: HeroPhase }) {
  const hasNotice = phase !== 'lock';
  const scanning = phase === 'scanning';
  const flagged = phase === 'flagged';

  return (
    <div className="relative flex h-full flex-col items-center bg-gradient-to-b from-slate-800 via-indigo-950 to-slate-950 px-3 pt-12 text-white">
      <Lock size={14} className="opacity-80" />
      <p className="mt-2 text-5xl font-light tracking-tight">9:41</p>
      <p className="text-[11px] text-white/70">Sunday, 18 October</p>

      <div className="mt-6 w-full space-y-2">
        {hasNotice && (
          <motion.div
            initial={{ opacity: 0, y: -32, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ type: 'spring', stiffness: 260, damping: 22 }}
            className={`relative overflow-hidden rounded-2xl p-2.5 ring-1 backdrop-blur-xl transition-colors duration-500 ${
              flagged
                ? 'bg-risk-600/30 ring-risk-500/70'
                : 'bg-white/15 ring-white/10'
            }`}
          >
            <div className="flex items-center gap-1.5 text-[9px] font-semibold uppercase tracking-wide text-white/70">
              <MessageSquareText size={11} />
              Messages · now
            </div>
            <p className="mt-1 text-[10px] font-semibold">+1 (555) 013 2290</p>
            <p className="text-[10px] leading-snug text-white/90">
              “Your bank account is locked. Verify now at bnk-secure-login.co”
            </p>

            {(scanning || flagged) && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                className="overflow-hidden"
              >
                <div className="mt-2 flex items-center gap-1.5 border-t border-white/15 pt-1.5 text-[9px] font-bold">
                  {flagged ? (
                    <>
                      <TriangleAlert size={11} className="text-risk-500" />
                      <span className="text-risk-500">High risk · phishing link</span>
                    </>
                  ) : (
                    <>
                      <ScanLine size={11} className="text-trust-400" />
                      <span className="text-trust-400">ScamWatch is checking…</span>
                    </>
                  )}
                </div>
              </motion.div>
            )}

            {scanning && (
              <motion.div
                aria-hidden
                initial={{ x: '-100%' }}
                animate={{ x: '400%' }}
                transition={{ duration: 1.4, ease: 'easeInOut' }}
                className="pointer-events-none absolute inset-y-0 left-0 w-1/3 bg-gradient-to-r from-transparent via-trust-400/40 to-transparent"
              />
            )}
          </motion.div>
        )}

        {flagged && (
          <motion.div
            initial={{ opacity: 0, y: 12, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ type: 'spring', stiffness: 260, damping: 22 }}
            className="flex items-center gap-2 rounded-2xl bg-risk-600 p-2.5 shadow-lg shadow-risk-600/30"
          >
            <span className="grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-white/20">
              <ShieldCheck size={15} />
            </span>
            <div className="min-w-0">
              <p className="text-[11px] font-bold leading-tight">Scam detected</p>
              <p className="text-[9px] leading-snug text-white/85">
                ScamWatch blocked this message
              </p>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
}

/** Floating notification that "pops out" next to the device in the hero. */
export function PopOutCard({
  tone = 'risk',
  title,
  body,
}: {
  tone?: 'risk' | 'safe';
  title?: string;
  body?: string;
}) {
  const isRisk = tone === 'risk';
  return (
    <div
      data-slot="popout"
      className="flex w-60 items-start gap-3 rounded-2xl border border-scam-line bg-scam-800/95 p-3.5 shadow-card-hover backdrop-blur-xl"
    >
      <span
        className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl text-white ${
          isRisk ? 'bg-risk-600' : 'bg-verified-600'
        }`}
      >
        {isRisk ? <TriangleAlert size={18} /> : <ShieldCheck size={18} />}
      </span>
      <div className="min-w-0 text-left">
        <p className="text-sm font-bold leading-tight text-scam-text">
          {title ?? (isRisk ? 'Scam detected' : 'Looks safe')}
        </p>
        <p className="mt-0.5 text-xs leading-snug text-scam-muted">
          {body ??
            (isRisk
              ? 'On-device AI flagged this message'
              : 'No known scam patterns found')}
        </p>
      </div>
    </div>
  );
}

const ROWS = [
  { Icon: Phone, from: 'Unknown caller', line: 'Missed call · 2 min ago', tone: 'caution' },
  { Icon: MessageSquareText, from: 'Mum', line: 'See you at 6!', tone: 'safe' },
  { Icon: Link2, from: 'Parcel Svc', line: 'Delivery on hold…', tone: 'safe' },
] as const;

/** In-app UI rendering: inbox being scanned with one flagged message. */
function AppScreen() {
  return (
    <div className="relative flex h-full flex-col px-4 pb-5 pt-11 text-slate-900 dark:text-slate-100">
      {/* App bar */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="grid h-7 w-7 place-items-center rounded-lg bg-trust-600 text-white">
            <ShieldCheck size={15} />
          </span>
          <span className="text-[13px] font-bold tracking-tight">ScamWatch</span>
        </div>
        <span className="flex items-center gap-1 rounded-full bg-verified-500/15 px-2 py-0.5 text-[9px] font-bold text-verified-700 dark:text-verified-400">
          <span className="h-1.5 w-1.5 rounded-full bg-verified-500" />
          PROTECTED
        </span>
      </div>

      {/* Shield status ring */}
      <div className="mt-5 flex flex-col items-center">
        <div className="relative grid h-24 w-24 place-items-center">
          <span className="absolute inset-0 rounded-full border-2 border-trust-500/20" />
          <span className="absolute inset-0 animate-ping-slow rounded-full border-2 border-trust-500/30" />
          <span className="absolute inset-2.5 rounded-full bg-gradient-to-b from-trust-500 to-trust-700 shadow-lg shadow-trust-600/30" />
          <ShieldCheck size={34} className="relative text-white" />
        </div>
        <p className="mt-3 text-[12px] font-bold">Scanning on-device</p>
        <p className="text-[10px] text-slate-500 dark:text-slate-400">
          Nothing leaves your phone
        </p>
      </div>

      {/* Flagged message */}
      <div className="relative mt-5 overflow-hidden rounded-2xl border border-risk-500/40 bg-risk-50 p-3 dark:bg-risk-500/10">
        <div className="flex items-center gap-1.5">
          <TriangleAlert size={12} className="text-risk-600 dark:text-risk-500" />
          <span className="text-[10px] font-bold uppercase tracking-wider text-risk-700 dark:text-risk-500">
            High risk · SMS
          </span>
        </div>
        <p className="mt-1.5 text-[11px] leading-snug text-slate-700 dark:text-slate-200">
          “Your bank account is locked. Verify now at bnk-secure-login.co”
        </p>
        <div className="mt-2 flex gap-1.5">
          <span className="rounded-md bg-risk-600 px-2 py-1 text-[9px] font-bold text-white">
            Block &amp; report
          </span>
          <span className="rounded-md border border-risk-500/30 px-2 py-1 text-[9px] font-semibold text-risk-700 dark:text-risk-500">
            Why?
          </span>
        </div>
      </div>

      {/* Other items */}
      <div className="mt-2.5 space-y-1.5">
        {ROWS.map(({ Icon, from, line, tone }) => (
          <div
            key={from}
            className="flex items-center gap-2.5 rounded-xl border border-slate-200 bg-white px-2.5 py-2 dark:border-slate-800 dark:bg-slate-900"
          >
            <span className="grid h-6 w-6 shrink-0 place-items-center rounded-lg bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400">
              <Icon size={12} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[10px] font-semibold">{from}</p>
              <p className="truncate text-[9px] text-slate-500 dark:text-slate-400">
                {line}
              </p>
            </div>
            <span
              className={`h-2 w-2 shrink-0 rounded-full ${
                tone === 'caution' ? 'bg-caution-500' : 'bg-verified-500'
              }`}
            />
          </div>
        ))}
      </div>

      {/* Scan sweep */}
      <div className="pointer-events-none absolute inset-x-0 top-0 h-1/4 animate-scan bg-gradient-to-b from-transparent via-trust-500/10 to-transparent" />
    </div>
  );
}
