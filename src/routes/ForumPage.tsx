import { motion } from 'framer-motion';
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
    <div className="mx-auto max-w-3xl px-4 py-10">
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="mb-8"
      >
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Community Forum
        </h1>
        <p className="mt-2 text-slate-500 dark:text-slate-400">
          Search discussions, filter by topic, and dive into the conversation.
        </p>
      </motion.div>

      <div className="sticky top-[68px] z-20 -mx-4 mb-6 space-y-4 bg-slate-50/80 px-4 py-4 backdrop-blur-lg dark:bg-slate-950/80">
        <SearchBar value={search} onChange={setSearch} />
        <TagFilter selected={tagId} onSelect={setTagId} />
      </div>

      <PostList query={debouncedSearch} tagId={tagId} />
    </div>
  );
}
