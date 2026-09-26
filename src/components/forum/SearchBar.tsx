import { Search, X } from 'lucide-react';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
}

export function SearchBar({ value, onChange }: SearchBarProps) {
  return (
    <div className="relative">
      <Search
        size={20}
        className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-ink-400"
      />
      <input
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Search records, authors…"
        className="w-full border border-ink-300 bg-white py-3.5 pl-12 pr-11 text-ink-900 outline-none transition placeholder:text-ink-400 focus:border-safe-500 focus:ring-2 focus:ring-safe-500/30 dark:border-ink-700 dark:bg-ink-900 dark:text-white"
      />
      {value && (
        <button
          type="button"
          onClick={() => onChange('')}
          aria-label="Clear search"
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-ink-400 transition hover:text-ink-800 dark:hover:text-white"
        >
          <X size={18} />
        </button>
      )}
    </div>
  );
}
