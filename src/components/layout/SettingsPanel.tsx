import { AnimatePresence, motion } from 'framer-motion';
import { Check, Minus, Moon, Plus, Settings, Sun, X } from 'lucide-react';
import { useState } from 'react';
import { createPortal } from 'react-dom';
import {
  useAppearance,
  type FontChoice,
  type FontSize,
} from '../../context/AppearanceContext';

// Font options with a preview stack + a short "why" note. The readability
// options are surfaced prominently for low-vision / dyslexic readers.
const FONT_OPTIONS: {
  value: FontChoice;
  label: string;
  note: string;
  css: string;
}[] = [
  {
    value: 'atkinson',
    label: 'Atkinson Hyperlegible',
    note: 'Default · high legibility, low vision',
    css: "'Atkinson Hyperlegible', system-ui, sans-serif",
  },
  {
    value: 'lexend',
    label: 'Lexend',
    note: 'Reduces reading stress',
    css: "'Lexend', system-ui, sans-serif",
  },
  {
    value: 'opensans',
    label: 'Open Sans',
    note: 'Clean & easy on the eye',
    css: "'Open Sans', system-ui, sans-serif",
  },
  {
    value: 'sans',
    label: 'Inter',
    note: 'Modern sans-serif',
    css: "'Inter', system-ui, sans-serif",
  },
  {
    value: 'serif',
    label: 'Serif',
    note: 'Georgia',
    css: "'Georgia', 'Times New Roman', serif",
  },
  {
    value: 'mono',
    label: 'Monospace',
    note: 'System mono',
    css: "ui-monospace, 'SF Mono', Menlo, Consolas, monospace",
  },
];

const SIZE_ORDER: FontSize[] = ['sm', 'md', 'lg'];
const SIZE_LABEL: Record<FontSize, string> = {
  sm: 'Small',
  md: 'Medium',
  lg: 'Large',
};

export function SettingsPanel() {
  const [open, setOpen] = useState(false);
  const { theme, font, fontSize, toggleTheme, setFont, setFontSize } =
    useAppearance();

  const sizeIndex = SIZE_ORDER.indexOf(fontSize);
  const decreaseSize = () => {
    if (sizeIndex > 0) setFontSize(SIZE_ORDER[sizeIndex - 1]);
  };
  const increaseSize = () => {
    if (sizeIndex < SIZE_ORDER.length - 1) setFontSize(SIZE_ORDER[sizeIndex + 1]);
  };

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Open appearance settings"
        className="grid h-10 w-10 place-items-center text-ink-600 transition hover:bg-ink-100 hover:text-ink-900 dark:text-ink-300 dark:hover:bg-ink-800 dark:hover:text-white"
      >
        <Settings size={20} />
      </button>

      {createPortal(
        <AnimatePresence>
          {open && (
            <>
              {/* Dim the entire screen behind the drawer */}
              <motion.div
                className="fixed inset-0 z-[100] bg-ink-950/60 backdrop-blur-sm"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={() => setOpen(false)}
              />
              {/* Drawer slides in from the RIGHT */}
              <motion.aside
                className="fixed right-0 top-0 z-[101] flex h-full w-96 max-w-[90vw] flex-col overflow-y-auto border-l border-ink-200 bg-paper text-ink-900 shadow-2xl dark:border-ink-800 dark:bg-ink-950 dark:text-ink-50"
                initial={{ x: '100%' }}
                animate={{ x: 0 }}
                exit={{ x: '100%' }}
                transition={{ type: 'spring', damping: 28, stiffness: 260 }}
              >
              <div className="flex items-center justify-between border-b border-ink-200 px-6 py-4 dark:border-ink-800">
                <div>
                  <span className="ia-label text-safe-700 dark:text-safe-400">
                    Settings
                  </span>
                  <h2 className="font-display text-xl font-bold">Appearance</h2>
                </div>
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  aria-label="Close settings"
                  className="grid h-9 w-9 place-items-center text-ink-500 transition hover:bg-ink-100 hover:text-ink-900 dark:hover:bg-ink-800 dark:hover:text-white"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="space-y-8 px-6 py-6">
                {/* Theme */}
                <section>
                  <p className="ia-label mb-3 text-ink-500 dark:text-ink-400">
                    Theme
                  </p>
                  <button
                    type="button"
                    onClick={toggleTheme}
                    className="flex w-full items-center justify-between border border-ink-200 px-4 py-3.5 text-left transition hover:border-safe-500 dark:border-ink-700"
                  >
                    <span className="flex items-center gap-2.5 text-base font-medium">
                      {theme === 'dark' ? (
                        <>
                          <Moon size={20} /> Dark
                        </>
                      ) : (
                        <>
                          <Sun size={20} /> Light
                        </>
                      )}
                    </span>
                    <span className="font-display text-xs uppercase tracking-wider text-ink-400">
                      Tap to toggle
                    </span>
                  </button>
                </section>

                {/* Font size:  − A a +  */}
                <section>
                  <p className="ia-label mb-3 text-ink-500 dark:text-ink-400">
                    Text size · {SIZE_LABEL[fontSize]}
                  </p>
                  <div className="flex items-stretch border border-ink-200 dark:border-ink-700">
                    <button
                      type="button"
                      onClick={decreaseSize}
                      disabled={sizeIndex === 0}
                      aria-label="Decrease text size"
                      className="grid w-16 place-items-center border-r border-ink-200 text-ink-700 transition hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-30 dark:border-ink-700 dark:text-ink-200 dark:hover:bg-ink-800"
                    >
                      <Minus size={22} />
                    </button>
                    <div className="flex flex-1 items-baseline justify-center gap-1.5 py-3">
                      <span
                        aria-hidden="true"
                        className="font-display font-bold leading-none text-ink-900 dark:text-white"
                        style={{ fontSize: '2.5rem' }}
                      >
                        A
                      </span>
                      <span
                        aria-hidden="true"
                        className="font-display font-bold leading-none text-ink-400 dark:text-ink-500"
                        style={{ fontSize: '0.95rem' }}
                      >
                        A
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={increaseSize}
                      disabled={sizeIndex === SIZE_ORDER.length - 1}
                      aria-label="Increase text size"
                      className="grid w-16 place-items-center border-l border-ink-200 text-ink-700 transition hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-30 dark:border-ink-700 dark:text-ink-200 dark:hover:bg-ink-800"
                    >
                      <Plus size={22} />
                    </button>
                  </div>
                  {/* Step indicator */}
                  <div className="mt-2 flex gap-1.5">
                    {SIZE_ORDER.map((s, i) => (
                      <span
                        key={s}
                        className={`h-1 flex-1 transition-colors ${
                          i <= sizeIndex
                            ? 'bg-safe-500'
                            : 'bg-ink-200 dark:bg-ink-700'
                        }`}
                      />
                    ))}
                  </div>
                </section>

                {/* Font family — bigger list with previews */}
                <section>
                  <p className="ia-label mb-3 text-ink-500 dark:text-ink-400">
                    Font
                  </p>
                  <div className="flex flex-col gap-2">
                    {FONT_OPTIONS.map((opt) => {
                      const active = opt.value === font;
                      return (
                        <button
                          key={opt.value}
                          type="button"
                          onClick={() => setFont(opt.value)}
                          aria-pressed={active}
                          className={`flex items-center justify-between border px-4 py-3 text-left transition ${
                            active
                              ? 'border-safe-500 bg-safe-50 dark:bg-safe-500/10'
                              : 'border-ink-200 hover:border-ink-400 dark:border-ink-700 dark:hover:border-ink-500'
                          }`}
                        >
                          <span className="min-w-0">
                            <span
                              className="block truncate text-lg font-semibold text-ink-900 dark:text-white"
                              style={{ fontFamily: opt.css }}
                            >
                              {opt.label}
                            </span>
                            <span
                              className="block truncate text-sm text-ink-500 dark:text-ink-400"
                              style={{ fontFamily: opt.css }}
                            >
                              The quick brown fox — {opt.note}
                            </span>
                          </span>
                          {active && (
                            <Check
                              size={20}
                              className="ml-3 shrink-0 text-safe-600 dark:text-safe-400"
                            />
                          )}
                        </button>
                      );
                    })}
                  </div>
                </section>
              </div>
            </motion.aside>
            </>
          )}
        </AnimatePresence>,
        document.body,
      )}
    </>
  );
}
