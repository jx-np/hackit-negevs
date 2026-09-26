import { useState } from 'react';
import { ForumHero } from '../components/forum/ForumHero';
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
    <div>
      <ForumHero />

      <div className="mx-auto max-w-3xl px-4 pb-16">
        {/* Sticky search + tag filter bar */}
        <div className="sticky top-[68px] z-20 -mx-4 mb-8 space-y-4 border-b border-slate-200/0 px-4 py-4 transition-all">
          <div className="glass rounded-3xl p-4 shadow-soft">
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
