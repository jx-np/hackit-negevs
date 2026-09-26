import { useTags } from '../../hooks/useTags';

interface TagFilterProps {
  /** Currently selected tag id, or null for "All". Single-select. */
  selected: string | null;
  onSelect: (tagId: string | null) => void;
}

export function TagFilter({ selected, onSelect }: TagFilterProps) {
  const { data: tags, isLoading, isError } = useTags();

  if (isError) {
    return (
      <p className="text-sm text-red-500">Couldn't load tags. Try again later.</p>
    );
  }

  return (
    <div className="flex flex-wrap gap-2" role="group" aria-label="Filter by tag">
      <TagChip
        label="All"
        active={selected === null}
        onClick={() => onSelect(null)}
      />

      {isLoading
        ? Array.from({ length: 6 }).map((_, i) => (
            <span
              key={i}
              className="h-8 w-20 animate-pulse rounded-full bg-slate-200 dark:bg-slate-800"
            />
          ))
        : tags?.map((tag) => (
            <TagChip
              key={tag.id}
              label={tag.name}
              count={tag.count}
              active={selected === tag.id}
              // Single-select: clicking the active tag clears it.
              onClick={() => onSelect(selected === tag.id ? null : tag.id)}
            />
          ))}
    </div>
  );
}

function TagChip({
  label,
  count,
  active,
  onClick,
}: {
  label: string;
  count?: number;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={`inline-flex items-center gap-1.5 rounded-full px-3.5 py-1.5 text-sm font-medium transition ${
        active
          ? 'bg-brand-600 text-white shadow-sm'
          : 'bg-slate-100 text-slate-700 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700'
      }`}
    >
      {label}
      {typeof count === 'number' && (
        <span
          className={`text-xs ${active ? 'text-brand-100' : 'text-slate-400'}`}
        >
          {count}
        </span>
      )}
    </button>
  );
}
