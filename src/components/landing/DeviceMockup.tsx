import { ShieldCheck } from 'lucide-react';

/**
 * Placeholder phone mockup for the landing hero scroll animation.
 *
 * REPLACE WITH REAL ASSETS LATER:
 *  - Swap the `<PlaceholderScreen />` contents for your app screenshot(s),
 *    e.g. <img src="/assets/scamreg-screen-1.png" alt="ScamReg app" />.
 *  - The "app pops out" layer is the element with `data-slot="popout"`; drop a
 *    transparent PNG / element there that should appear to lift out of the
 *    screen as the user scrolls.
 */
export function DeviceMockup() {
  return (
    <div className="relative mx-auto w-[280px] sm:w-[320px]">
      {/* Device frame */}
      <div className="relative rounded-[2.75rem] border-[10px] border-slate-900 bg-slate-900 shadow-2xl dark:border-slate-700">
        {/* Notch */}
        <div className="absolute left-1/2 top-0 z-20 h-6 w-32 -translate-x-1/2 rounded-b-2xl bg-slate-900 dark:bg-slate-700" />

        {/* Screen — replace PlaceholderScreen with a real screenshot */}
        <div className="relative aspect-[9/19] overflow-hidden rounded-[2rem] bg-gradient-to-b from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-950">
          <PlaceholderScreen />
        </div>
      </div>
    </div>
  );
}

/** The element that "pops out" of the device; positioned by the hero. */
export function PopOutCard() {
  return (
    <div
      data-slot="popout"
      className="flex w-56 items-center gap-3 rounded-2xl border border-white/60 bg-white/90 p-4 shadow-glow backdrop-blur-xl dark:border-white/10 dark:bg-slate-800/90"
    >
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-gradient text-white">
        <ShieldCheck size={22} />
      </span>
      <div className="text-left">
        <p className="text-sm font-bold leading-tight">Scam detected</p>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          On-device AI flagged this message
        </p>
      </div>
    </div>
  );
}

/** Placeholder in-app UI so the mockup looks real until assets arrive. */
function PlaceholderScreen() {
  return (
    <div className="flex h-full flex-col p-4">
      <div className="mb-4 flex items-center gap-2">
        <span className="grid h-7 w-7 place-items-center rounded-lg bg-brand-gradient text-white">
          <ShieldCheck size={16} />
        </span>
        <span className="text-sm font-bold text-slate-800 dark:text-slate-100">
          ScamReg
        </span>
      </div>

      {/* Fake scanned message list */}
      <div className="space-y-2.5">
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-3 dark:border-rose-900/50 dark:bg-rose-950/30">
          <div className="mb-1 h-2 w-16 rounded bg-rose-300 dark:bg-rose-700" />
          <div className="h-2 w-full rounded bg-rose-200 dark:bg-rose-800/60" />
          <div className="mt-2 inline-block rounded-full bg-rose-500 px-2 py-0.5 text-[9px] font-bold text-white">
            HIGH RISK
          </div>
        </div>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="rounded-xl border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-800"
          >
            <div className="mb-1 h-2 w-12 rounded bg-slate-300 dark:bg-slate-600" />
            <div className="h-2 w-full rounded bg-slate-200 dark:bg-slate-700" />
          </div>
        ))}
      </div>

      <div className="mt-auto grid grid-cols-2 gap-2">
        <div className="rounded-xl bg-brand-gradient py-2 text-center text-[10px] font-semibold text-white">
          Report scam
        </div>
        <div className="rounded-xl border border-slate-200 py-2 text-center text-[10px] font-semibold text-slate-600 dark:border-slate-700 dark:text-slate-300">
          Scan again
        </div>
      </div>
    </div>
  );
}
