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
      className="inline-flex gap-1 rounded-xl border border-scam-line bg-scam-800 p-1 shadow-card"
      role="group"
      aria-label="Sort posts"
    >
      {OPTIONS.map((opt) => {
        const active = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            onClick={() => onChange(opt.value)}
            aria-pressed={active}
            className={`sr-focus rounded-lg px-3.5 py-2 text-sm font-semibold transition ${
              active
                ? 'bg-trust-600 text-white shadow-button'
                : 'text-scam-muted hover:bg-scam-750 hover:text-scam-text'
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
