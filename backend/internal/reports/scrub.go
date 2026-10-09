package reports

import (
	"regexp"
	"strings"
)

// Server-side scrubbing. These are pure functions applied to client-supplied
// redacted_text before it is persisted. The client is expected to have already
// redacted sensitive material during the publish preview, but the server never
// trusts that: it re-scrubs so that emails, phone numbers, long digit runs
// (account/card numbers) and raw link targets can never reach the public feed.
//
// Scrubbing is intentionally conservative and lossy: it favours masking a false
// positive over leaking a real identifier.

var (
	// emailPattern matches typical email addresses.
	emailPattern = regexp.MustCompile(`[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}`)

	// urlPattern matches http/https URLs (with optional path/query). It is
	// neutralized to host-only so the feed never carries a clickable untrusted
	// target.
	urlPattern = regexp.MustCompile(`(?i)\bhttps?://[^\s<>()]+`)

	// wwwPattern matches bare "www." hosts without a scheme.
	wwwPattern = regexp.MustCompile(`(?i)\bwww\.[A-Za-z0-9.\-]+(?:/[^\s<>()]*)?`)

	// phonePattern matches phone-like sequences: an optional +, then groups of
	// digits separated by spaces, hyphens or parentheses, with at least 8 total
	// digits. Kept deliberately broad to catch international formats.
	phonePattern = regexp.MustCompile(`\+?\d[\d\s().\-]{6,}\d`)

	// longDigitPattern matches unbroken runs of 7 or more digits, e.g. account
	// or card numbers that survived phone masking.
	longDigitPattern = regexp.MustCompile(`\d{7,}`)
)

// Redaction placeholders. These are stable tokens the client can render.
const (
	maskEmail  = "[redacted-email]"
	maskPhone  = "[redacted-phone]"
	maskDigits = "[redacted-number]"
)

// Scrub applies all masking passes to s and returns the sanitized text. It is
// pure and safe to call repeatedly (idempotent on already-scrubbed text).
//
// Order matters: emails first (they contain "@" and dots that other passes
// would fragment), then URLs to host-only, then phone numbers, then any
// remaining long digit runs.
func Scrub(s string) string {
	if s == "" {
		return s
	}
	s = emailPattern.ReplaceAllString(s, maskEmail)
	s = neutralizeURLs(s)
	s = maskPhones(s)
	s = longDigitPattern.ReplaceAllString(s, maskDigits)
	return s
}

// neutralizeURLs reduces any http/https URL or bare www host to its host only,
// stripping scheme, path, query and fragment so the value is not a clickable
// link. "https://evil.example.com/login?token=abc" becomes "evil.example.com".
func neutralizeURLs(s string) string {
	s = urlPattern.ReplaceAllStringFunc(s, func(m string) string {
		return hostOnly(m)
	})
	s = wwwPattern.ReplaceAllStringFunc(s, func(m string) string {
		return hostOnly(m)
	})
	return s
}

// hostOnly extracts the host portion of a URL-like token.
func hostOnly(raw string) string {
	u := raw
	// Strip scheme.
	if i := strings.Index(u, "://"); i >= 0 {
		u = u[i+3:]
	}
	// Strip credentials.
	if i := strings.Index(u, "@"); i >= 0 {
		u = u[i+1:]
	}
	// Cut at first path/query/fragment separator.
	if i := strings.IndexAny(u, "/?#"); i >= 0 {
		u = u[:i]
	}
	// Drop a trailing port.
	if i := strings.LastIndex(u, ":"); i >= 0 {
		if _, err := parsePort(u[i+1:]); err == nil {
			u = u[:i]
		}
	}
	u = strings.Trim(u, ".")
	if u == "" {
		return "[redacted-link]"
	}
	return u
}

// parsePort reports whether p is a plausible numeric port.
func parsePort(p string) (bool, error) {
	if p == "" {
		return false, errEmptyPort
	}
	for _, c := range p {
		if c < '0' || c > '9' {
			return false, errEmptyPort
		}
	}
	return true, nil
}

var errEmptyPort = &scrubError{"not a port"}

type scrubError struct{ msg string }

func (e *scrubError) Error() string { return e.msg }

// maskPhones replaces phone-like sequences with a placeholder, but only when the
// matched run actually contains enough digits to be a phone number. This avoids
// masking ordinary short numbers embedded in prose.
func maskPhones(s string) string {
	return phonePattern.ReplaceAllStringFunc(s, func(m string) string {
		if countDigits(m) < 8 {
			return m
		}
		// Preserve surrounding whitespace boundaries that the greedy pattern may
		// have swallowed at the edges.
		lead, trail := edgeSpace(m)
		return lead + maskPhone + trail
	})
}

// countDigits returns the number of ASCII digits in s.
func countDigits(s string) int {
	n := 0
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n++
		}
	}
	return n
}

// edgeSpace returns any leading and trailing whitespace of s so a replacement
// can keep the original spacing.
func edgeSpace(s string) (lead, trail string) {
	trimmed := strings.TrimLeft(s, " \t")
	lead = s[:len(s)-len(trimmed)]
	trimmed2 := strings.TrimRight(trimmed, " \t")
	trail = trimmed[len(trimmed2):]
	return lead, trail
}
