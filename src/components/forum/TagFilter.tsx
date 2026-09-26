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
      <p className="font-mono text-sm text-risk-600">
        Couldn't load tags. Try again later.
      </p>
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
              className="h-8 w-20 animate-pulse bg-ink-200 dark:bg-ink-800"
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
      className={`inline-flex items-center gap-1.5 border px-3 py-1.5 font-mono text-xs font-medium uppercase tracking-wider transition ${
        active
          ? 'border-safe-600 bg-safe-600 text-white'
          : 'border-ink-300 text-ink-700 hover:border-ink-900 hover:text-ink-900 dark:border-ink-700 dark:text-ink-300 dark:hover:border-white dark:hover:text-white'
      }`}
    >
      {label}
      {typeof count === 'number' && (
        <span className={active ? 'text-safe-100' : 'text-ink-400'}>
          {count}
        </span>
      )}
    </button>
  );
}
