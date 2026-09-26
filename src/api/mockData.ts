import type { Post, Tag } from '../types';

export const MOCK_TAGS: Tag[] = [
  { id: 't-react', name: 'React', count: 42 },
  { id: 't-typescript', name: 'TypeScript', count: 31 },
  { id: 't-css', name: 'CSS', count: 27 },
  { id: 't-design', name: 'Design', count: 19 },
  { id: 't-performance', name: 'Performance', count: 15 },
  { id: 't-accessibility', name: 'Accessibility', count: 12 },
  { id: 't-tooling', name: 'Tooling', count: 9 },
  { id: 't-career', name: 'Career', count: 8 },
];

const AUTHORS = [
  { id: 'u1', name: 'Ada Lovelace' },
  { id: 'u2', name: 'Grace Hopper' },
  { id: 'u3', name: 'Alan Turing' },
  { id: 'u4', name: 'Katherine Johnson' },
  { id: 'u5', name: 'Linus Torvalds' },
];

const TITLES = [
  'How do you structure large React apps?',
  'Tailwind vs CSS Modules in 2026',
  'Debouncing search inputs the right way',
  'Infinite scroll: pitfalls and best practices',
  'Making dark mode flicker-free on first paint',
  'Accessible tag filters with keyboard support',
  'Type-safe API layers with Zod',
  'When to reach for React Query',
  'Beautiful scroll animations without jank',
  'Designing a font-size toggle that actually works',
  'State management in 2026: what changed?',
  'Reducing bundle size in Vite projects',
  'Building a design system from scratch',
  'Framer Motion recipes for page transitions',
  'Optimistic UI updates explained',
];

function pick<T>(arr: T[], i: number): T {
  return arr[i % arr.length];
}

const RISK_CYCLE: Array<'high' | 'medium' | null> = [
  'high',
  'medium',
  null,
  'high',
  null,
];

/** Deterministically generate a large set of mock posts. */
export const MOCK_POSTS: Post[] = Array.from({ length: 60 }, (_, i) => {
  const author = pick(AUTHORS, i);
  const title = pick(TITLES, i);
  // Assign 1–2 tags per post, spread across the tag list.
  const tagA = MOCK_TAGS[i % MOCK_TAGS.length];
  const tagB = MOCK_TAGS[(i * 3 + 1) % MOCK_TAGS.length];
  const tags = tagA.id === tagB.id ? [tagA] : [tagA, tagB];

  // Most (but not all) reports include a screenshot. Seeded placeholder
  // images stay stable; real images come from the API later.
  const hasImage = i % 4 !== 2;

  return {
    id: `post-${i + 1}`,
    title: `${title}`,
    excerpt:
      'A thoughtful discussion covering practical patterns, trade-offs, and real-world examples the community has found useful.',
    body: 'Full post body would appear here in a detail view.',
    author,
    tags,
    createdAt: new Date(Date.now() - i * 1000 * 60 * 60 * 7).toISOString(),
    replyCount: (i * 7) % 34,
    likeCount: (i * 13) % 120,
    imageUrl: hasImage
      ? `https://picsum.photos/seed/scamreg${i + 1}/640/400`
      : null,
    risk: RISK_CYCLE[i % RISK_CYCLE.length],
  };
});
