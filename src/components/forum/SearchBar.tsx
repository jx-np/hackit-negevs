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
        className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-scam-muted"
      />
      <input
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Search records, authors…"
        aria-label="Search the forum"
        className="w-full rounded-xl border border-scam-line bg-scam-800 py-3 pl-12 pr-11 text-scam-text shadow-card outline-none transition placeholder:text-scam-muted focus:border-trust-500 focus:ring-4 focus:ring-trust-500/15 [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-decoration]:appearance-none"
      />
      {value && (
        <button
          type="button"
          onClick={() => onChange('')}
          aria-label="Clear search"
          className="sr-focus absolute right-3 top-1/2 -translate-y-1/2 rounded-md p-1 text-scam-muted transition hover:bg-scam-750 hover:text-scam-text"
        >
          <X size={18} />
        </button>
      )}
    </div>
  );
}
