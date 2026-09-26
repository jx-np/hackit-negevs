import { describe, expect, it } from 'vitest';
import { getTags } from './tags';
import { MOCK_TAGS } from './mockData';

describe('getTags (mock mode)', () => {
  it('returns all mock tags', async () => {
    const tags = await getTags();
    expect(tags).toHaveLength(MOCK_TAGS.length);
  });

  it('returns tags with id, name, and count', async () => {
    const tags = await getTags();
    for (const tag of tags) {
      expect(tag).toHaveProperty('id');
      expect(tag).toHaveProperty('name');
      expect(typeof tag.name).toBe('string');
      expect(typeof tag.count).toBe('number');
    }
  });
});
