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
      className="inline-flex overflow-hidden rounded-md border border-scam-line"
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
            className={`px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition ${
              i > 0 ? 'border-l border-scam-line' : ''
            } ${
              active
                ? 'bg-trust-500 text-white'
                : 'bg-scam-800 text-scam-muted hover:text-scam-text'
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
