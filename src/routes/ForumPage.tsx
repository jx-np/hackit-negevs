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
    <div className="mx-auto w-full max-w-[1400px] px-6 py-10">
      {/* Page header */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-8 flex items-center gap-4"
      >
        <span className="grid h-14 w-14 place-items-center rounded-2xl bg-brand-gradient text-white shadow-soft">
          <MessagesSquare size={28} />
        </span>
        <div>
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Community Forum
          </h1>
          <p className="mt-1 text-lg text-slate-500 dark:text-slate-400">
            Discuss scams, share warnings, and learn from the community.
          </p>
        </div>
      </motion.div>

      {/* Sticky search + tag filter bar */}
      <div className="sticky top-[76px] z-20 mb-8">
        <div className="glass rounded-3xl p-5 shadow-soft">
          <SearchBar value={search} onChange={setSearch} />
          <div className="mt-4">
            <TagFilter selected={tagId} onSelect={setTagId} />
          </div>
        </div>
      </div>

      <PostList query={debouncedSearch} tagId={tagId} />
    </div>
  );
}
