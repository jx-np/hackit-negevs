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
        className="w-full rounded-md border border-scam-line bg-scam-750 py-3 pl-12 pr-11 text-scam-text outline-none transition placeholder:text-scam-muted focus:border-trust-400 focus:ring-2 focus:ring-trust-400/30 [&::-webkit-search-cancel-button]:appearance-none [&::-webkit-search-decoration]:appearance-none"
      />
      {value && (
        <button
          type="button"
          onClick={() => onChange('')}
          aria-label="Clear search"
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-scam-muted transition hover:text-trust-400"
        >
          <X size={18} />
        </button>
      )}
    </div>
  );
}
