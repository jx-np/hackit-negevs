import { GripVertical } from 'lucide-react';
import { useState } from 'react';
import { useTags } from '../../hooks/useTags';
import type { PanelSide } from '../../hooks/usePanelSide';

interface TagPanelProps {
  /** Currently selected tag id, or null for "All". Single-select. */
  selected: string | null;
  onSelect: (tagId: string | null) => void;
  side: PanelSide;
  /** Called when the user drags the header and releases on a side. */
  onMove: (side: PanelSide) => void;
}

/**
 * Sidebar tag filter. The header is draggable: grab it and release on the
 * left or right half of the viewport to snap the panel to that side.
 * One tag per line.
 */
export function TagPanel({ selected, onSelect, side, onMove }: TagPanelProps) {
  const { data: tags, isLoading, isError } = useTags();
  const [dragging, setDragging] = useState(false);

  const handlePointerDown = (e: React.PointerEvent) => {
    setDragging(true);
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const handlePointerUp = (e: React.PointerEvent) => {
    if (!dragging) return;
    setDragging(false);
    onMove(e.clientX > window.innerWidth / 2 ? 'right' : 'left');
  };

  return (
    <aside
      className={`ia-panel w-full overflow-hidden lg:sticky lg:top-20 lg:max-h-[calc(100vh-6rem)] lg:w-64 lg:shrink-0 lg:self-start lg:overflow-y-auto ${
        dragging ? 'opacity-60' : ''
      }`}
      aria-label="Filter by tag"
    >
      {/* Draggable header */}
      <div
        onPointerDown={handlePointerDown}
        onPointerUp={handlePointerUp}
        className="flex cursor-grab items-center justify-between bg-ink-900 px-4 py-3 text-white select-none active:cursor-grabbing dark:bg-white dark:text-ink-900"
        title="Drag to move left or right"
      >
        <span className="ia-label">Filter by tag</span>
        <GripVertical size={16} className="opacity-60" />
      </div>
      <p className="ia-label px-4 pt-2.5 text-[10px] text-ink-400">
        Drag the header · now on {side}
      </p>

      {isError ? (
        <p className="px-4 py-3 font-mono text-sm text-risk-600">
          Couldn't load tags.
        </p>
      ) : (
        <div
          className="flex flex-col gap-0.5 p-2.5"
          role="group"
          aria-label="Tags"
        >
          <TagRow
            label="All records"
            active={selected === null}
            onClick={() => onSelect(null)}
          />
          {isLoading
            ? Array.from({ length: 6 }).map((_, i) => (
                <span
                  key={i}
                  className="h-9 animate-pulse bg-ink-100 dark:bg-ink-800"
                />
              ))
            : tags?.map((tag) => (
                <TagRow
                  key={tag.id}
                  label={tag.name}
                  count={tag.count}
                  active={selected === tag.id}
                  onClick={() =>
                    onSelect(selected === tag.id ? null : tag.id)
                  }
                />
              ))}
        </div>
      )}
    </aside>
  );
}

function TagRow({
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
      className={`flex w-full items-center justify-between border-l-2 px-3 py-2.5 text-left text-base font-medium transition ${
        active
          ? 'border-safe-600 bg-safe-50 text-safe-700 dark:bg-safe-500/10 dark:text-safe-400'
          : 'border-transparent text-ink-700 hover:bg-ink-50 dark:text-ink-300 dark:hover:bg-ink-800'
      }`}
    >
      <span>{label}</span>
      {typeof count === 'number' && (
        <span
          className={`font-mono text-xs ${
            active ? 'text-safe-700 dark:text-safe-400' : 'text-ink-400'
          }`}
        >
          {count}
        </span>
      )}
    </button>
  );
}
