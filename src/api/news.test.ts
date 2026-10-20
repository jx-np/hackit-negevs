import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../test/mockFetch';
import type { ApiNewsArticle } from '../types';
import { getNews, resolveNewsLocale } from './news';

function article(over: Partial<ApiNewsArticle> = {}): ApiNewsArticle {
  return {
    id: 'news-1',
    icon: 'message_square_warning',
    title: {
      en: 'Fake bank SMS on the rise',
      ms: 'SMS bank palsu semakin meningkat',
    },
    text: {
      en: 'Scammers are sending texts that look like your bank.',
      ms: 'Penipu menghantar mesej yang kelihatan seperti bank anda.',
    },
    ...over,
  };
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('resolveNewsLocale', () => {
  it('reduces regional locales to a supported language', () => {
    expect(resolveNewsLocale('ms-MY')).toBe('ms');
    expect(resolveNewsLocale('zh_SG')).toBe('zh');
    expect(resolveNewsLocale('ta')).toBe('ta');
  });

  it('falls back to English for unsupported or missing locales', () => {
    expect(resolveNewsLocale('fr-FR')).toBe('en');
    expect(resolveNewsLocale('')).toBe('en');
    expect(resolveNewsLocale(undefined)).toBe('en');
  });
});

describe('getNews', () => {
  it('calls GET /news and resolves titles/text in the requested locale', async () => {
    const fetchMock = mockFetch([
      { match: '/news', json: { articles: [article()] } },
    ]);

    const result = await getNews('ms-MY');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(String(fetchMock.mock.calls[0][0])).toContain('/news');
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      id: 'news-1',
      icon: 'message_square_warning',
      locale: 'ms',
      title: 'SMS bank palsu semakin meningkat',
      text: 'Penipu menghantar mesej yang kelihatan seperti bank anda.',
    });
  });

  it('falls back to English per field when a translation is missing', async () => {
    mockFetch([{ match: '/news', json: { articles: [article()] } }]);

    const result = await getNews('ta');

    expect(result[0].locale).toBe('ta');
    expect(result[0].title).toBe('Fake bank SMS on the rise');
    expect(result[0].text).toBe(
      'Scammers are sending texts that look like your bank.',
    );
  });

  it('returns an empty list when the API omits articles', async () => {
    mockFetch([{ match: '/news', json: {} }]);
    await expect(getNews('en')).resolves.toEqual([]);
  });
});
