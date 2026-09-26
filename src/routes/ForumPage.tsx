import { motion } from 'framer-motion';
import { MessagesSquare } from 'lucide-react';
import { useState } from 'react';
import { PostList } from '../components/forum/PostList';
import { SearchBar } from '../components/forum/SearchBar';
import { TagFilter } from '../components/forum/TagFilter';
import { useDebounce } from '../hooks/useDebounce';

export function ForumPage() {
  const [search, setSearch] = useState('');
  const [tagId, setTagId] = useState<string | null>(null);

  // Debounce the search input so we don't query on every keystroke.
  const debouncedSearch = useDebounce(search, 350);

  return (
    <div className="min-h-screen bg-paper dark:bg-ink-950">
      <div className="mx-auto w-full max-w-[1400px] px-6 py-10">
        {/* Page header */}
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-4 border-b border-ink-200 pb-6 dark:border-ink-800"
        >
          <span className="grid h-14 w-14 place-items-center bg-ink-900 text-white dark:bg-white dark:text-ink-900">
            <MessagesSquare size={28} />
          </span>
          <div>
            <span className="ia-label text-safe-700 dark:text-safe-400">
              Community registry
            </span>
            <h1 className="mt-1 font-display text-3xl font-bold tracking-tight text-ink-900 dark:text-white sm:text-4xl">
              Forum
            </h1>
          </div>
        </motion.div>

        {/* Sticky search + tag filter bar */}
        <div className="sticky top-[72px] z-20 mb-8">
          <div className="ia-panel p-5 shadow-ia">
            <SearchBar value={search} onChange={setSearch} />
            <div className="mt-4">
              <TagFilter selected={tagId} onSelect={setTagId} />
            </div>
          </div>
        </div>

        <PostList query={debouncedSearch} tagId={tagId} />
      </div>
    </div>
  );
}
