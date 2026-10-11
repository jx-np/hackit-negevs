import {
  BadgeCheck,
  Banknote,
  Bell,
  BookOpen,
  Briefcase,
  ChevronDown,
  Flame,
  HelpCircle,
  Home,
  Mail,
  MessageSquareWarning,
  Phone,
  PlusCircle,
  ScrollText,
  ShieldAlert,
  ShieldQuestion,
  ShoppingBag,
  Siren,
  Sparkles,
  Star,
  UserX,
} from 'lucide-react';
import { useState, type ComponentType } from 'react';
import { Link } from 'react-router-dom';
import { useTags } from '../../hooks/useTags';

interface ForumSidebarProps {
  /** Currently selected tag id, or null for "All records". Single-select. */
  selected: string | null;
  onSelect: (tagId: string | null) => void;
}

type IconType = ComponentType<{ size?: number | string; className?: string }>;

/** Primary navigation group at the top of the sidebar. */
const NAV_ITEMS: { icon: IconType; label: string; to?: string }[] = [
  { icon: Home, label: 'Home' },
  { icon: Flame, label: 'Trending Scams' },
  { icon: Sparkles, label: 'Newest Reports' },
  { icon: BookOpen, label: 'How to Stay Safe' },
];

/** Icons mapped by category keyword so backend tags get a sensible glyph. */
const CATEGORY_ICONS: { match: RegExp; icon: IconType }[] = [
  { match: /phish|email/i, icon: Mail },
  { match: /crypto|invest/i, icon: Banknote },
  { match: /romance|dating/i, icon: MessageSquareWarning },
  { match: /tech|support/i, icon: ShieldQuestion },
  { match: /shop|marketplace|deliver/i, icon: ShoppingBag },
  { match: /job|employ/i, icon: Briefcase },
  { match: /impersonat|bank|gov/i, icon: ShieldAlert },
  { match: /phone|sms|smish|vish/i, icon: Phone },
];

function iconForCategory(name: string): IconType {
  return CATEGORY_ICONS.find((c) => c.match.test(name))?.icon ?? ShieldAlert;
}

const COMMUNITY_ITEMS: { icon: IconType; label: string }[] = [
  { icon: ScrollText, label: 'Rules & Posting Guidelines' },
  { icon: BadgeCheck, label: 'Verified Scam Database' },
  { icon: UserX, label: 'Report a User' },
  { icon: HelpCircle, label: 'Help' },
];

export function ForumSidebar({ selected, onSelect }: ForumSidebarProps) {
  const { data: tags, isLoading, isError } = useTags();
  const [categoriesOpen, setCategoriesOpen] = useState(true);

  return (
    <aside
      className="w-full lg:sticky lg:top-20 lg:w-60 lg:shrink-0 lg:self-start lg:max-h-[calc(100vh-6rem)] lg:overflow-y-auto"
      aria-label="Forum navigation"
    >
      {/* Primary nav */}
      <nav className="flex flex-col gap-0.5" aria-label="Main">
        {NAV_ITEMS.map(({ icon: Icon, label }, i) => {
          const active = i === 0 && selected === null;
          return (
            <button
              key={label}
              type="button"
              onClick={() => i === 0 && onSelect(null)}
              aria-current={active ? 'page' : undefined}
              className={`flex items-center gap-3 rounded-md border-l-2 px-3 py-2 text-sm font-medium transition ${
                active
                  ? 'border-trust-400 bg-trust-400/10 text-trust-400'
                  : 'border-transparent text-scam-muted hover:bg-scam-800 hover:text-scam-text'
              }`}
            >
              <Icon size={18} />
              {label}
            </button>
          );
        })}

        {/* Highlighted call-to-action — primary filled CTA */}
        <Link
          to="/report"
          className="mt-1 flex items-center gap-3 rounded-md bg-trust-500 px-3 py-2.5 text-sm font-semibold text-white shadow-card transition hover:bg-trust-600"
        >
          <PlusCircle size={18} />
          Report a Scam
        </Link>
      </nav>

      {/* Scam categories (wired to the real tag filter) */}
      <div className="mt-6 border-t border-scam-line pt-4">
        <button
          type="button"
          onClick={() => setCategoriesOpen((o) => !o)}
          aria-expanded={categoriesOpen}
          className="flex w-full items-center justify-between px-3 pb-1 text-left"
        >
          <span className="sr-label">Scam Categories</span>
          <ChevronDown
            size={14}
            className={`text-scam-muted transition-transform ${
              categoriesOpen ? '' : '-rotate-90'
            }`}
          />
        </button>

        {categoriesOpen && (
          <div className="mt-1 flex flex-col gap-0.5" role="group" aria-label="Scam categories">
            {/* "All records" acts as the clear-filter row */}
            <CategoryRow
              icon={ShieldQuestion}
              label="All records"
              active={selected === null}
              onClick={() => onSelect(null)}
            />

            {isError && (
              <p className="px-3 py-2 text-sm text-risk-high">Couldn't load categories.</p>
            )}

            {isLoading
              ? Array.from({ length: 6 }).map((_, i) => (
                  <span
                    key={i}
                    className="mx-1 h-8 animate-pulse rounded-md bg-scam-800"
                  />
                ))
              : tags?.map((tag) => (
                  <CategoryRow
                    key={tag.id}
                    icon={iconForCategory(tag.name)}
                    label={tag.name}
                    count={tag.count}
                    active={selected === tag.id}
                    onClick={() => onSelect(selected === tag.id ? null : tag.id)}
                  />
                ))}
          </div>
        )}
      </div>

      {/* Your feeds */}
      <div className="mt-6 border-t border-scam-line pt-4">
        <span className="block px-3 pb-1 sr-label">Your Feeds</span>
        <div className="mt-1 flex flex-col gap-0.5">
          {['Phishing & Fake Emails', 'Crypto & Investment Fraud'].map((label) => (
            <div
              key={label}
              className="flex items-center justify-between gap-2 rounded-md px-3 py-2 text-sm text-scam-muted"
            >
              <span className="truncate">{label}</span>
              <Star size={15} className="shrink-0 text-trust-400" fill="currentColor" />
            </div>
          ))}
        </div>
      </div>

      {/* Community */}
      <div className="mt-6 border-t border-scam-line pt-4">
        <span className="block px-3 pb-1 sr-label">Community</span>
        <div className="mt-1 flex flex-col gap-0.5">
          {COMMUNITY_ITEMS.map(({ icon: Icon, label }) => (
            <button
              key={label}
              type="button"
              className="flex items-center gap-3 rounded-md px-3 py-2 text-left text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
            >
              <Icon size={16} />
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Featured active-scam alert card */}
      <div className="mt-6">
        <div className="rounded-lg border border-risk-high/40 bg-risk-high/10 p-3">
          <div className="flex items-center gap-2">
            <Siren size={15} className="text-risk-high" />
            <span className="text-[11px] font-semibold uppercase tracking-[0.14em] text-risk-high">
              Alert
            </span>
          </div>
          <p className="mt-1.5 text-sm font-medium text-scam-text">
            Fake delivery "redelivery fee" texts circulating now
          </p>
          <p className="mt-1 text-xs text-scam-muted">
            Never pay fees via links in SMS. Verify with the courier directly.
          </p>
        </div>
      </div>

      <div className="mt-4 flex items-center gap-2 px-3 text-xs text-scam-dim">
        <Bell size={13} /> You're following 2 feeds
      </div>
    </aside>
  );
}

function CategoryRow({
  icon: Icon,
  label,
  count,
  active,
  onClick,
}: {
  icon: IconType;
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
      className={`flex w-full items-center gap-3 rounded-md border-l-2 px-3 py-2 text-left text-sm font-medium transition ${
        active
          ? 'border-trust-400 bg-trust-400/10 text-trust-400'
          : 'border-transparent text-scam-muted hover:bg-scam-800 hover:text-scam-text'
      }`}
    >
      <Icon size={16} className="shrink-0" />
      <span className="flex-1 truncate">{label}</span>
      {typeof count === 'number' && (
        <span className={`text-xs ${active ? 'text-trust-400' : 'text-scam-dim'}`}>
          {count}
        </span>
      )}
    </button>
  );
}
