import type { SortKey } from '../../types';

interface SortControlProps {
  value: SortKey;
  onChange: (sort: SortKey) => void;
}

const OPTIONS: { value: SortKey; label: string }[] = [
  { value: 'new', label: 'Newest' },
  { value: 'comments', label: 'Comments' },
  { value: 'likes', label: 'Likes' },
];

/** Segmented control for ordering posts: newest / most comments / most likes. */
export function SortControl({ value, onChange }: SortControlProps) {
  return (
    <div
      className="inline-flex border border-ink-200 dark:border-ink-800"
      role="group"
      aria-label="Sort posts"
    >
      {OPTIONS.map((opt, i) => {
        const active = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            onClick={() => onChange(opt.value)}
            aria-pressed={active}
            className={`px-4 py-2.5 font-mono text-xs font-semibold uppercase tracking-wider transition ${
              i > 0 ? 'border-l border-ink-200 dark:border-ink-800' : ''
            } ${
              active
                ? 'bg-ink-900 text-white dark:bg-white dark:text-ink-900'
                : 'bg-white text-ink-500 hover:text-ink-900 dark:bg-ink-900 dark:text-ink-400 dark:hover:text-white'
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
