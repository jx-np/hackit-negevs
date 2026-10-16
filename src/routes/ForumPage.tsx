import { motion } from 'framer-motion';
import { ArrowLeft, ShieldCheck } from 'lucide-react';
import { useState } from 'react';
import { ForumSidebar, type ForumPanel } from '../components/forum/ForumSidebar';
import { NewestReportsContent } from '../components/forum/NewestReports';
import { PostList } from '../components/forum/PostList';
import { RecentReports } from '../components/forum/RecentReports';
import { SearchBar } from '../components/forum/SearchBar';
import { SortControl } from '../components/forum/SortControl';
import { useDebounce } from '../hooks/useDebounce';
import type { SortKey } from '../types';
import { HelpContent } from './HelpPage';
import { ReportUserContent } from './ReportUserPage';
import { RulesContent } from './RulesPage';
import { StaySafeContent } from './StaySafePage';
import { VerifiedContent } from './VerifiedDatabasePage';

/** Renders the inline content for a given forum navigation panel. */
function PanelContent({ panel }: { panel: ForumPanel }) {
  switch (panel) {
    case 'newest':
      return <NewestReportsContent />;
    case 'stay-safe':
      return <StaySafeContent />;
    case 'rules':
      return <RulesContent />;
    case 'help':
      return <HelpContent />;
    case 'verified':
      return <VerifiedContent />;
    case 'report-user':
      return <ReportUserContent />;
  }
}

export function ForumPage() {
  const [search, setSearch] = useState('');
  const [tagId, setTagId] = useState<string | null>(null);
  const [sort, setSort] = useState<SortKey>('new');
  const [panel, setPanel] = useState<ForumPanel | null>(null);

  // Debounce the search input so we don't query on every keystroke.
  const debouncedSearch = useDebounce(search, 350);

  return (
    // The forum adopts the ScamWatch dark theme regardless of the global mode.
    // Inter is used here for a trustworthy, contemporary feel.
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
      style={{ fontFamily: "'Inter', system-ui, -apple-system, sans-serif" }}
    >
      <div className="mx-auto grid w-full max-w-[1500px] grid-cols-1 gap-8 px-5 py-8 lg:grid-cols-[15rem_minmax(0,1fr)_310px] lg:px-8">
        {/* Left sidebar — navigation & scam categories (tag filter) */}
        <ForumSidebar
          selected={tagId}
          onSelect={(id) => {
            setPanel(null);
            setTagId(id);
          }}
          activePanel={panel}
          onOpenPanel={setPanel}
        />

        {/* Center feed */}
        <main className="min-w-0">
          {panel ? (
            <>
              <button
                type="button"
                onClick={() => setPanel(null)}
                className="mb-6 inline-flex items-center gap-2 rounded-md border border-scam-line px-3 py-2 text-sm font-medium text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
              >
                <ArrowLeft size={16} /> Back to the forum
              </button>
              <PanelContent panel={panel} />
            </>
          ) : (
            <>
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
            </>
          )}
        </main>

        {/* Right sidebar — recently reported scams + active threat alerts */}
        <RecentReports
          onSeeAll={() => {
            setPanel('newest');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      </div>
    </div>
  );
}
