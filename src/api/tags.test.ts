import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import { getTags } from './tags';

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('getTags (scam-types endpoint)', () => {
  it('calls the scam-types endpoint and maps slug → id, name_key → name', async () => {
    mockFetch([
      {
        match: '/community/scam-types',
        json: {
          items: [
            { slug: 'phishing', name_key: 'category.phishing' },
            { slug: 'investment', name_key: 'category.investment' },
          ],
        },
      },
    ]);
    const tags = await getTags();
    expect(tags).toHaveLength(2);
    expect(tags[0].id).toBe('phishing');
    expect(tags[0].name).toBe('Phishing');
    expect(tags[1].id).toBe('investment');
    expect(tags[1].name).toBe('Investment');
  });

  it('returns tags with id and name (no count)', async () => {
    mockFetch([
      {
        match: '/community/scam-types',
        json: {
          items: [{ slug: 'romance', name_key: 'category.romance' }],
        },
      },
    ]);
    const tags = await getTags();
    for (const tag of tags) {
      expect(tag).toHaveProperty('id');
      expect(tag).toHaveProperty('name');
      expect(typeof tag.name).toBe('string');
    }
  });

  it('handles an empty taxonomy', async () => {
    mockFetch([{ match: '/community/scam-types', json: { items: [] } }]);
    const tags = await getTags();
    expect(tags).toHaveLength(0);
  });
});
