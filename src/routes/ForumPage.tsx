import { motion } from 'framer-motion';
import { ShieldCheck } from 'lucide-react';
import { useState } from 'react';
import { ForumSidebar } from '../components/forum/ForumSidebar';
import { PostList } from '../components/forum/PostList';
import { RecentReports } from '../components/forum/RecentReports';
import { SearchBar } from '../components/forum/SearchBar';
import { SortControl } from '../components/forum/SortControl';
import { useDebounce } from '../hooks/useDebounce';
import type { SortKey } from '../types';

export function ForumPage() {
  const [search, setSearch] = useState('');
  const [tagId, setTagId] = useState<string | null>(null);
  const [sort, setSort] = useState<SortKey>('new');

  // Debounce the search input so we don't query on every keystroke.
  const debouncedSearch = useDebounce(search, 350);

  return (
    // The forum adopts the ScamReg dark theme regardless of the global mode.
    // Inter is used here for a trustworthy, contemporary feel.
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
      style={{ fontFamily: "'Inter', system-ui, -apple-system, sans-serif" }}
    >
      <div className="mx-auto grid w-full max-w-[1500px] grid-cols-1 gap-8 px-5 py-8 lg:grid-cols-[15rem_minmax(0,1fr)_310px] lg:px-8">
        {/* Left sidebar — navigation & scam categories (tag filter) */}
        <ForumSidebar selected={tagId} onSelect={setTagId} />

        {/* Center feed */}
        <main className="min-w-0">
          {/* Page header */}
          <motion.div
            initial={{ opacity: 0, y: -12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="mb-6 flex items-center gap-3 border-b border-scam-line pb-6"
          >
            <span className="sr-tile h-12 w-12">
              <ShieldCheck size={24} />
            </span>
            <div>
              <span className="sr-eyebrow">Community registry</span>
              <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
                Scam Forum
              </h1>
            </div>
          </motion.div>

          {/* Search + sort bar */}
          <div className="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="flex-1">
              <SearchBar value={search} onChange={setSearch} />
            </div>
            <SortControl value={sort} onChange={setSort} />
          </div>

          <PostList query={debouncedSearch} tagId={tagId} sort={sort} />
        </main>

        {/* Right sidebar — recently reported scams + active threat alerts */}
        <RecentReports />
      </div>
    </div>
  );
}
