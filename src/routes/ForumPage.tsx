import { motion } from 'framer-motion';
import { ArrowLeft, PlusCircle, ShieldCheck } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
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
    // The forum follows the global theme and the user's chosen reading font
    // (AppearanceContext), so accessibility settings apply here too.
    <div className="relative min-h-screen bg-scam-950 text-scam-text">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 h-72 sw-dots opacity-60 [mask-image:linear-gradient(to_bottom,black,transparent)]"
      />
      <div className="relative mx-auto grid w-full max-w-[1500px] grid-cols-1 gap-8 px-5 py-8 lg:grid-cols-[15rem_minmax(0,1fr)_310px] lg:px-8">
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
        <section className="min-w-0" aria-label="Forum feed">
          {panel ? (
            <>
              <button
                type="button"
                onClick={() => setPanel(null)}
                className="sr-btn-ghost sr-focus mb-6 bg-scam-800 text-scam-muted"
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
                className="sr-surface relative mb-6 overflow-hidden p-6 sm:p-7"
              >
                <div
                  aria-hidden
                  className="pointer-events-none absolute -right-24 -top-24 h-64 w-64 sw-halo"
                />
                <ShieldCheck
                  aria-hidden
                  strokeWidth={1}
                  className="pointer-events-none absolute -bottom-10 right-4 h-40 w-40 text-trust-500/[0.07]"
                />
                <div className="relative flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
                  <div className="flex items-center gap-4">
                    <span className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-gradient-to-b from-trust-500 to-trust-700 text-white shadow-button">
                      <ShieldCheck size={26} aria-hidden />
                    </span>
                    <div>
                      <span className="sr-eyebrow">Community registry</span>
                      <h1 className="mt-1 font-display text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
                        Scam Forum
                      </h1>
                      <p className="mt-1 max-w-md text-pretty text-sm leading-relaxed text-scam-muted">
                        Share what you&rsquo;ve seen, confirm what others report,
                        and help warn people before they get caught out.
                      </p>
                    </div>
                  </div>
                  <Link
                    to="/report"
                    className="sr-btn-primary sr-focus shrink-0 self-start px-5 py-2.5 sm:self-center"
                  >
                    <PlusCircle size={17} aria-hidden /> Share a report
                  </Link>
                </div>
              </motion.div>

              {/* Search + sort bar */}
              <div className="sticky top-[4.75rem] z-30 -mx-2 mb-6 flex flex-col gap-3 rounded-2xl bg-scam-950 px-2 py-2 shadow-[0_8px_24px_-12px_rgba(0,0,0,0.9)] sm:flex-row sm:items-center">
                <div className="flex-1">
                  <SearchBar value={search} onChange={setSearch} />
                </div>
                <SortControl value={sort} onChange={setSort} />
              </div>

              <PostList query={debouncedSearch} tagId={tagId} sort={sort} />
            </>
          )}
        </section>

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
