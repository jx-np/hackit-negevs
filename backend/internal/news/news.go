// Package news implements the public scam-awareness news feed: short,
// plain-language articles shown to users on the home screen.
//
// Articles are content-managed rows (see news_articles and
// news_article_translations in init.sql) seeded by migration. Unlike guidance,
// the API returns every available locale for an article at once, so the client
// can pick the language itself. Icons are client-side icon names (for example
// "message_square_warning"); the API never returns image data.
package news

// Article is the internal representation of a news article plus all of its
// locale translations, keyed by locale (e.g. "en", "ms", "ta", "zh").
type Article struct {
	ID           int64
	Slug         string
	Icon         string
	SortOrder    int
	Translations map[string]Translation
}

// Translation is a locale-specific title and body for an article.
type Translation struct {
	Locale string
	Title  string
	Body   string
}
