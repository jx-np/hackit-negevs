import {
  BadgeCheck,
  Banknote,
  Bell,
  Bitcoin,
  BookOpen,
  Briefcase,
  Building2,
  ChevronDown,
  CreditCard,
  Gift,
  Globe,
  GraduationCap,
  HeartHandshake,
  HelpCircle,
  Home,
  Landmark,
  Mail,
  MessageSquare,
  Phone,
  PlusCircle,
  ScrollText,
  ShieldAlert,
  ShieldQuestion,
  ShoppingBag,
  Siren,
  Sparkles,
  Star,
  Truck,
  UserRoundX,
  UserX,
  Wallet,
  Wrench,
  X,
} from 'lucide-react';
import { useState, type ComponentType } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTags } from '../../hooks/useTags';
import { useSavedFeeds } from '../../context/SavedFeedsContext';

/**
 * Inline panels that can replace the forum feed. `null` means the default
 * feed (post list) is shown.
 */
export type ForumPanel =
  | 'newest'
  | 'stay-safe'
  | 'rules'
  | 'verified'
  | 'report-user'
  | 'help';

interface ForumSidebarProps {
  /** Currently selected tag id, or null for "All records". Single-select. */
  selected: string | null;
  onSelect: (tagId: string | null) => void;
  /** Panel currently shown in the feed, or null for the default post list. */
  activePanel: ForumPanel | null;
  /** Open an inline panel in the feed (or null to return to the post list). */
  onOpenPanel: (panel: ForumPanel | null) => void;
}

type IconType = ComponentType<{ size?: number | string; className?: string }>;

/** Primary navigation group at the top of the sidebar. */
const NAV_ITEMS: { icon: IconType; label: string; panel?: ForumPanel }[] = [
  { icon: Home, label: 'Home' },
  { icon: Sparkles, label: 'Newest Reports', panel: 'newest' },
  { icon: BookOpen, label: 'How to Stay Safe', panel: 'stay-safe' },
];

/**
 * Icons mapped by category keyword so backend tags get a sensible glyph.
 * Ordered most-specific first so overlapping keywords (e.g. "bank" vs
 * "impersonation") resolve to the most fitting icon.
 */
const CATEGORY_ICONS: { match: RegExp; icon: IconType }[] = [
  { match: /phish/i, icon: Mail },
  { match: /vish|call|phone|robocall|telemarket/i, icon: Phone },
  { match: /smish|sms|text/i, icon: MessageSquare },
  { match: /crypto|bitcoin|token|wallet|nft|blockchain/i, icon: Bitcoin },
  { match: /invest|ponzi|pump|trading|stock|forex/i, icon: Banknote },
  { match: /romance|dating|love|relationship/i, icon: HeartHandshake },
  { match: /tech|support/i, icon: Wrench },
  { match: /deliver|parcel|courier|package|shipping/i, icon: Truck },
  { match: /shop|marketplace|retail|store|ecommerce|e-commerce/i, icon: ShoppingBag },
  { match: /job|employ|recruit|work.?from.?home|career/i, icon: Briefcase },
  { match: /bank/i, icon: Landmark },
  { match: /card|credit|debit|payment/i, icon: CreditCard },
  { match: /gov|tax|irs|hmrc|benefit|refund/i, icon: Building2 },
  { match: /impersonat|identity|spoof|fake.?profile/i, icon: UserRoundX },
  { match: /charity|donat|fundrais|disaster/i, icon: Gift },
  { match: /loan|debt|credit.?repair|advance.?fee/i, icon: Wallet },
  { match: /lottery|prize|giveaway|reward|inherit/i, icon: Gift },
  { match: /education|scholar|student|tuition|visa/i, icon: GraduationCap },
  { match: /social|message|whatsapp|telegram|chat/i, icon: MessageSquare },
  { match: /website|phish.?site|clone|url|domain|online/i, icon: Globe },
  { match: /email|mail|spam/i, icon: Mail },
];

function iconForCategory(name: string, slug = ''): IconType {
  const haystack = `${slug} ${name}`;
  return CATEGORY_ICONS.find((c) => c.match.test(haystack))?.icon ?? ShieldAlert;
}

const COMMUNITY_ITEMS: { icon: IconType; label: string; panel: ForumPanel }[] = [
  { icon: ScrollText, label: 'Rules & Posting Guidelines', panel: 'rules' },
  { icon: BadgeCheck, label: 'Verified Scam Database', panel: 'verified' },
  { icon: UserX, label: 'Report a User', panel: 'report-user' },
  { icon: HelpCircle, label: 'Help', panel: 'help' },
];

export function ForumSidebar({
  selected,
  onSelect,
  activePanel,
  onOpenPanel,
}: ForumSidebarProps) {
  const { data: tags, isLoading, isError } = useTags();
  const navigate = useNavigate();
  const { savedFeeds, removeFeed } = useSavedFeeds();
  const [categoriesOpen, setCategoriesOpen] = useState(true);

  return (
    <aside
      className="w-full lg:sticky lg:top-[6.5rem] lg:w-60 lg:shrink-0 lg:self-start lg:max-h-[calc(100vh-7.5rem)] lg:overflow-y-auto lg:overscroll-contain lg:pb-6"
      aria-label="Forum navigation"
    >
      {/* Primary nav */}
      <nav className="flex flex-col gap-0.5" aria-label="Main">
        {NAV_ITEMS.map(({ icon: Icon, label, panel }, i) => {
          const active = panel
            ? activePanel === panel
            : i === 0 && activePanel === null && selected === null;
          return (
            <button
              key={label}
              type="button"
              onClick={() => {
                if (panel) {
                  onOpenPanel(panel);
                } else {
                  onOpenPanel(null);
                  onSelect(null);
                }
              }}
              aria-current={active ? 'page' : undefined}
              className={`sr-focus flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition ${
                active
                  ? 'bg-trust-500/10 text-trust-700 ring-1 ring-inset ring-trust-500/20 dark:text-trust-300'
                  : 'text-scam-muted hover:bg-scam-800 hover:text-scam-text'
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
          className="sr-focus mt-2 flex items-center gap-3 rounded-lg bg-trust-600 px-3 py-2.5 text-sm font-semibold text-white shadow-button transition hover:bg-trust-700"
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
                    icon={iconForCategory(tag.name, tag.id)}
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
        {savedFeeds.length === 0 ? (
          <p className="px-3 py-2 text-xs text-scam-dim">
            Save a post with the bookmark icon to pin it here.
          </p>
        ) : (
          <div className="mt-1 flex flex-col gap-0.5">
            {savedFeeds.map((feed) => (
              <div
                key={feed.id}
                className="group/feed flex items-center gap-2 rounded-md px-3 py-2 text-sm text-scam-muted transition hover:bg-scam-800 hover:text-scam-text"
              >
                <button
                  type="button"
                  onClick={() => navigate(`/forum/${feed.id}`)}
                  className="flex min-w-0 flex-1 items-center gap-2 text-left"
                >
                  <Star size={15} className="shrink-0 text-trust-400" fill="currentColor" />
                  <span className="truncate">{feed.title}</span>
                </button>
                <button
                  type="button"
                  onClick={() => removeFeed(feed.id)}
                  aria-label={`Remove ${feed.title} from saved feeds`}
                  className="shrink-0 rounded p-0.5 text-scam-dim opacity-0 transition hover:text-risk-high focus:opacity-100 group-hover/feed:opacity-100"
                >
                  <X size={14} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Community */}
      <div className="mt-6 border-t border-scam-line pt-4">
        <span className="block px-3 pb-1 sr-label">Community</span>
        <div className="mt-1 flex flex-col gap-0.5">
          {COMMUNITY_ITEMS.map(({ icon: Icon, label, panel }) => {
            const active = activePanel === panel;
            return (
              <button
                key={label}
                type="button"
                onClick={() => onOpenPanel(panel)}
                aria-current={active ? 'page' : undefined}
                className={`flex items-center gap-3 rounded-md px-3 py-2 text-left text-sm transition ${
                  active
                    ? 'bg-trust-400/10 text-trust-400'
                    : 'text-scam-muted hover:bg-scam-800 hover:text-scam-text'
                }`}
              >
                <Icon size={16} />
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Featured active-scam alert card */}
      <div className="mt-6">
        <div className="rounded-2xl border border-risk-high/30 bg-risk-high/[0.07] p-4">
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
        <Bell size={13} /> You're following {savedFeeds.length}{' '}
        {savedFeeds.length === 1 ? 'feed' : 'feeds'}
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
      className={`sr-focus flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm font-medium transition ${
        active
          ? 'bg-trust-500/10 text-trust-700 ring-1 ring-inset ring-trust-500/20 dark:text-trust-300'
          : 'text-scam-muted hover:bg-scam-800 hover:text-scam-text'
      }`}
    >
      <Icon size={16} className="shrink-0" />
      <span className="flex-1 truncate">{label}</span>
      {typeof count === 'number' && (
        <span
          className={`sr-nums rounded-full px-1.5 py-0.5 text-[11px] font-semibold ${
            active ? 'bg-trust-500/15 text-trust-700 dark:text-trust-300' : 'bg-scam-750 text-scam-dim'
          }`}
        >
          {count}
        </span>
      )}
    </button>
  );
}
