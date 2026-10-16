import { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, BadgeCheck, ShieldCheck } from 'lucide-react';
import { Link } from 'react-router-dom';
import { SearchBar } from '../components/forum/SearchBar';
import { SortControl } from '../components/forum/SortControl';
import { PostList } from '../components/forum/PostList';
import type { SortKey } from '../types';

/**
 * Verified Scam Database — a searchable record of reports that moderators have
 * reviewed and confirmed. It reuses the same cursor-paginated community feed as
 * the forum, filtered client-side to posts whose `reviewStatus` is `reviewed`,
 * so the view stays in sync with the live backend without a dedicated endpoint.
 */
export function VerifiedDatabasePage() {
  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <VerifiedContent />
      </div>
    </div>
  );
}

/**
 * Inner content for the Verified Scam Database, without the full-page wrapper,
 * so it can also be rendered inline inside the forum feed panel. It owns its
 * own search/sort state.
 */
export function VerifiedContent() {
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<SortKey>('new');

  return (
    <>
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-6 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <BadgeCheck size={24} />
          </span>
          <div className="min-w-0">
            <span className="sr-eyebrow">Community</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Verified Scam Database
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              A searchable record of confirmed scams, reviewed by moderators.
            </p>
          </div>
        </motion.div>

        <div className="mb-5 flex items-center gap-2 rounded-md border border-trust-500/30 bg-trust-500/5 px-4 py-3 text-sm text-trust-200">
          <ShieldCheck size={18} className="shrink-0 text-trust-300" />
          <span>
            These reports have been reviewed and verified by our moderation
            team. Browse the full forum to see every community submission.
          </span>
        </div>

        <div className="mb-5 space-y-3">
          <SearchBar value={query} onChange={setQuery} />
          <div className="flex items-center justify-between gap-3">
            <SortControl value={sort} onChange={setSort} />
            <Link
              to="/forum"
              className="inline-flex items-center gap-1.5 text-sm font-medium text-trust-400 transition hover:text-trust-300"
            >
              <ArrowLeft size={15} /> All reports
            </Link>
          </div>
        </div>

        <PostList
          query={query}
          tagId={null}
          sort={sort}
          filter={(post) => post.reviewStatus === 'reviewed'}
          emptyTitle="No verified reports yet"
          emptyHint="Moderators haven't confirmed any reports matching this search. Check the full forum for the latest community submissions."
        />
    </>
  );
}
