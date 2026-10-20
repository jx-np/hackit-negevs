/**
 * Home-screen news / scam-awareness articles.
 *
 * `GET /news` returns every article with all of its translations at once, so
 * the client picks a locale and falls back to English per field when a
 * translation is missing. Icon names are resolved client-side (the API never
 * returns image data).
 */
import type {
  ApiNewsArticle,
  ApiNewsResponse,
  NewsArticle,
  NewsLocale,
} from '../types';
import { apiFetch } from './client';

export const NEWS_LOCALES: readonly NewsLocale[] = ['en', 'ms', 'ta', 'zh'];

/** Reduce a BCP 47 locale ("ms-MY", "zh_SG") to a supported news locale. */
export function resolveNewsLocale(locale?: string | null): NewsLocale {
  const base = (locale ?? '').trim().toLowerCase().split(/[-_]/)[0];
  return NEWS_LOCALES.includes(base as NewsLocale) ? (base as NewsLocale) : 'en';
}

/** Pick a translated value, falling back to English, then to any value. */
function pickTranslation(
  translations: Record<string, string> | undefined,
  locale: NewsLocale,
): string {
  return (
    translations?.[locale]?.trim() ||
    translations?.en?.trim() ||
    Object.values(translations ?? {})[0]?.trim() ||
    ''
  );
}

function mapArticle(raw: ApiNewsArticle, locale: NewsLocale): NewsArticle {
  return {
    id: raw.id,
    icon: raw.icon,
    title: pickTranslation(raw.title, locale),
    text: pickTranslation(raw.text, locale),
    locale,
  };
}

/**
 * Fetch the active news articles in the given language.
 * Unknown/missing locales fall back to English.
 */
export async function getNews(locale?: string | null): Promise<NewsArticle[]> {
  const resolved = resolveNewsLocale(locale);
  const res = await apiFetch<ApiNewsResponse>('/news');
  return (res.articles ?? []).map((article) => mapArticle(article, resolved));
}
