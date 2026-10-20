import { useQuery } from '@tanstack/react-query';
import { getNews, resolveNewsLocale } from '../api/news';
import type { NewsArticle } from '../types';

/**
 * Pick the first browser language the news API can serve, otherwise English.
 * This keeps the articles localised for visitors without a saved preference.
 */
function browserLocale(): string {
  if (typeof navigator === 'undefined') return 'en';
  const candidates = navigator.languages?.length
    ? navigator.languages
    : [navigator.language];
  for (const candidate of candidates) {
    if (!candidate) continue;
    if (resolveNewsLocale(candidate) !== 'en') return candidate;
  }
  return 'en';
}

/**
 * Active news / scam-awareness articles.
 * Pass a locale (e.g. the signed-in user's locale) to override the browser
 * preference.
 */
export function useNews(locale?: string | null) {
  const resolved = resolveNewsLocale(locale ?? browserLocale());
  return useQuery<NewsArticle[]>({
    queryKey: ['news', resolved],
    queryFn: () => getNews(resolved),
    staleTime: 5 * 60 * 1000, // content changes rarely
  });
}
