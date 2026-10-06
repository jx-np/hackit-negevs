import type { Post, Tag } from '../types';

export const MOCK_TAGS: Tag[] = [
  { id: 't-phishing', name: 'Phishing', count: 42 },
  { id: 't-investment', name: 'Investment', count: 31 },
  { id: 't-romance', name: 'Romance', count: 27 },
  { id: 't-impersonation', name: 'Impersonation', count: 19 },
  { id: 't-blackmail', name: 'Blackmail', count: 15 },
  { id: 't-tech-support', name: 'Tech Support', count: 12 },
  { id: 't-lottery', name: 'Lottery & Prize', count: 9 },
  { id: 't-job', name: 'Job Offer', count: 8 },
];

const AUTHORS = [
  { id: 'u1', name: 'Ada Lovelace' },
  { id: 'u2', name: 'Grace Hopper' },
  { id: 'u3', name: 'Alan Turing' },
  { id: 'u4', name: 'Katherine Johnson' },
  { id: 'u5', name: 'Linus Torvalds' },
];

const TITLES = [
  'Fake bank SMS asking to verify my account',
  'WhatsApp "investment mentor" promising 300% returns',
  'Romance scammer asked for gift cards after two weeks',
  'Caller impersonating the tax authority demanding payment',
  'Sextortion email threatening to leak my photos',
  'Fake Microsoft "tech support" pop-up locked my browser',
  'You\'ve won a lottery you never entered — pay the fee',
  'Work-from-home job offer that asked for a deposit',
  'Phishing link disguised as a parcel delivery notice',
  'Crypto "trading platform" that won\'t let me withdraw',
  'Fake landlord asking for a deposit before viewing',
  'Cloned social media account messaging my friends',
  'Fake charity collecting donations after a disaster',
  'QR code sticker over a real parking meter payment',
  'Bank "fraud team" call spoofing the official number',
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
      'A firsthand account of how the scam unfolded, the red flags that gave it away, and what to watch for so the community can avoid it.',
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
