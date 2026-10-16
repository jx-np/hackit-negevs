import { Sparkles } from 'lucide-react';
import type { Post } from '../../types';
import { PostList } from './PostList';

/** Reports created within this window (ms) count as "new". */
const NEW_WINDOW_MS = 24 * 60 * 60 * 1000;

/** True when the post was created within the last day. */
function isWithinLastDay(post: Post): boolean {
  return Date.now() - new Date(post.createdAt).getTime() <= NEW_WINDOW_MS;
}

/**
 * Dedicated "Newest Reports" view: the standard feed restricted to reports
 * from the last 24 hours, newest first. Shared by the sidebar nav item and
 * the "See all" link on the recently-reported panel.
 */
export function NewestReportsContent() {
  return (
    <div>
      <div className="mb-6 flex items-center gap-3 border-b border-scam-line pb-6">
        <span className="sr-tile h-12 w-12">
          <Sparkles size={24} />
        </span>
        <div>
          <span className="sr-eyebrow">Last 24 hours</span>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
            Newest Reports
          </h1>
        </div>
      </div>

      <PostList
        query=""
        tagId={null}
        sort="new"
        filter={isWithinLastDay}
        emptyTitle="No reports in the last 24 hours"
        emptyHint="Check back soon — new scams are reported throughout the day."
      />
    </div>
  );
}
