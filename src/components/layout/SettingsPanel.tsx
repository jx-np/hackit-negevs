import { AnimatePresence, motion } from 'framer-motion';
import { Moon, Settings, Sun, X } from 'lucide-react';
import { useState } from 'react';
import {
  useAppearance,
  type FontChoice,
  type FontSize,
} from '../../context/AppearanceContext';

const FONT_OPTIONS: { value: FontChoice; label: string }[] = [
  { value: 'sans', label: 'Sans' },
  { value: 'serif', label: 'Serif' },
  { value: 'mono', label: 'Mono' },
];

const SIZE_OPTIONS: { value: FontSize; label: string }[] = [
  { value: 'sm', label: 'A-' },
  { value: 'md', label: 'A' },
  { value: 'lg', label: 'A+' },
];

function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  label,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (v: T) => void;
  label: string;
}) {
  return (
    <div>
      <p className="mb-2 text-sm font-medium text-slate-500 dark:text-slate-400">
        {label}
      </p>
      <div className="flex gap-1 rounded-xl bg-slate-100 p-1 dark:bg-slate-800">
        {options.map((opt) => {
          const active = opt.value === value;
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => onChange(opt.value)}
              className={`flex-1 rounded-lg px-3 py-2 text-sm font-medium transition ${
                active
                  ? 'bg-white text-brand-600 shadow-sm dark:bg-slate-700 dark:text-brand-300'
                  : 'text-slate-600 hover:text-slate-900 dark:text-slate-300 dark:hover:text-white'
              }`}
            >
              {opt.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function SettingsPanel() {
  const [open, setOpen] = useState(false);
  const { theme, font, fontSize, toggleTheme, setFont, setFontSize } =
    useAppearance();

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Open appearance settings"
        className="rounded-full p-2 text-slate-600 transition hover:bg-slate-100 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 dark:hover:text-white"
      >
        <Settings size={20} />
      </button>

      <AnimatePresence>
        {open && (
          <>
            <motion.div
              className="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setOpen(false)}
            />
            <motion.aside
              className="fixed right-0 top-0 z-50 h-full w-80 max-w-[85vw] bg-white p-6 shadow-2xl dark:bg-slate-900"
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', damping: 28, stiffness: 260 }}
            >
              <div className="mb-6 flex items-center justify-between">
                <h2 className="text-lg font-semibold">Appearance</h2>
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  aria-label="Close settings"
                  className="rounded-full p-1.5 text-slate-500 transition hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="space-y-6">
                <div>
                  <p className="mb-2 text-sm font-medium text-slate-500 dark:text-slate-400">
                    Theme
                  </p>
                  <button
                    type="button"
                    onClick={toggleTheme}
                    className="flex w-full items-center justify-between rounded-xl border border-slate-200 px-4 py-3 text-left transition hover:border-brand-400 dark:border-slate-700"
                  >
                    <span className="flex items-center gap-2 text-sm font-medium">
                      {theme === 'dark' ? (
                        <>
                          <Moon size={18} /> Dark
                        </>
                      ) : (
                        <>
                          <Sun size={18} /> Light
                        </>
                      )}
                    </span>
                    <span className="text-xs text-slate-400">tap to toggle</span>
                  </button>
                </div>

                <SegmentedControl
                  label="Font"
                  options={FONT_OPTIONS}
                  value={font}
                  onChange={setFont}
                />

                <SegmentedControl
                  label="Font size"
                  options={SIZE_OPTIONS}
                  value={fontSize}
                  onChange={setFontSize}
                />
              </div>
            </motion.aside>
          </>
        )}
      </AnimatePresence>
    </>
  );
}
