// Package grok implements the "@help" community reply bot. (The package name is
// kept for historical reasons; the public trigger is @help.)
//
// When a resident comments on a public community post and mentions @help, this
// package asynchronously asks an OpenAI-compatible chat model (via a LiteLLM
// gateway) for a short, plain-language answer and posts it back as a reply
// comment authored by the dedicated bot user.
//
// PRIVACY: the only content this package ever reads is already-public community
// data: the post title and server-scrubbed text, the post's already-published
// PII-redacted images (report_images, never the raw uploads they were derived
// from), and public comments. It is sent to the model over HTTP. Private
// uploads, private checks and any other private detection data are never
// touched. Nothing that carries message content - prompts, comment bodies, post
// text, image bytes or model output - is ever logged; only ids, counts, sizes,
// durations and outcomes are.
package grok

import "strings"

// mention is the trigger token residents use to address the bot. Match is
// case-insensitive and only treats it as a mention when it stands alone as its
// own token.
const mention = "@help"

// MentionsBot reports whether body contains @help as its own token:
// case-insensitive, not preceded by a letter, digit, underscore or '@' (so
// "foo@help" does not count), and not followed by a word character (so
// "@helper" does not count).
//
// "Word character" is deliberately ASCII ([A-Za-z0-9_]) so a mention glued to
// non-Latin text - common in the Singapore pilot's Chinese/Malay messages, e.g.
// "@help这是骗局吗" - is still recognised.
func MentionsBot(body string) bool {
	return len(mentionSpans(body)) > 0
}

// StripMentions removes every standalone @help mention from body and collapses
// the surrounding whitespace, returning the remaining question text. The result
// may be empty: a bare "@help" is a valid (context-only) question.
func StripMentions(body string) string {
	spans := mentionSpans(body)
	if len(spans) == 0 {
		return strings.TrimSpace(body)
	}

	var b strings.Builder
	last := 0
	for _, sp := range spans {
		b.WriteString(body[last:sp.start])
		b.WriteByte(' ')
		last = sp.end
	}
	b.WriteString(body[last:])

	// Collapse the runs of whitespace the substitutions can create.
	return strings.Join(strings.Fields(b.String()), " ")
}

// span is a half-open byte range [start, end) within a string.
type span struct{ start, end int }

// mentionSpans returns the byte range of every standalone @help mention in body,
// in ascending order and non-overlapping.
func mentionSpans(body string) []span {
	var spans []span
	for i := 0; i+len(mention) <= len(body); i++ {
		if body[i] != '@' {
			continue
		}
		if !strings.EqualFold(body[i:i+len(mention)], mention) {
			continue
		}
		// Reject when immediately preceded by a word byte or another '@'
		// ("foo@help", "a_help").
		if i > 0 && (isWordByte(body[i-1]) || body[i-1] == '@') {
			continue
		}
		// Reject when immediately followed by a word byte ("@helper", "@help_").
		end := i + len(mention)
		if end < len(body) && isWordByte(body[end]) {
			continue
		}
		spans = append(spans, span{start: i, end: end})
	}
	return spans
}

// isWordByte reports whether c is an ASCII word character. Multi-byte runes
// have a leading byte >= 0x80 and are therefore treated as non-word, which is
// what allows a mention to butt directly against CJK text.
func isWordByte(c byte) bool {
	switch {
	case c >= '0' && c <= '9':
		return true
	case c >= 'A' && c <= 'Z':
		return true
	case c >= 'a' && c <= 'z':
		return true
	case c == '_':
		return true
	default:
		return false
	}
}
