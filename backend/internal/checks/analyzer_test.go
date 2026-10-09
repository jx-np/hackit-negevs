package checks

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// signalCodes extracts the set of detected signal codes for easy assertions.
func signalCodes(a Assessment) map[string]bool {
	out := make(map[string]bool, len(a.Signals))
	for _, s := range a.Signals {
		out[s.Code] = true
	}
	return out
}

func TestAnalyze_ClearlySuspiciousPhishing(t *testing.T) {
	text := "URGENT: Your DBS bank account has been suspended. Verify your account now and confirm your OTP to avoid closure."

	a := Analyze(text, "en-SG")

	assert.Equal(t, VerdictSuspicious, a.Verdict, "phishing text should be suspicious")

	codes := signalCodes(a)
	assert.True(t, codes[SignalCredential], "should detect a credential/OTP request")
	assert.True(t, codes[SignalUrgency], "should detect urgency language")

	// Explainability: every signal carries evidence and an explanation.
	require.NotEmpty(t, a.Signals)
	for _, s := range a.Signals {
		assert.NotEmpty(t, s.Code)
		assert.NotEmpty(t, s.EvidenceExcerpt)
		assert.NotEmpty(t, s.Explanation)
	}

	assert.NotEmpty(t, a.RecommendedActions, "suspicious result should recommend actions")
	assert.NotEmpty(t, a.SuggestedTags, "suspicious result should suggest tags")
	assert.NotEmpty(t, a.Limitations, "limitations must always be present")
	assert.NotEmpty(t, a.Uncertainty, "uncertainty must always be present")
}

func TestAnalyze_BenignTextNotSuspicious(t *testing.T) {
	text := "Hi, thanks for lunch today. Let me know when you're free next week. No rush, take care!"

	a := Analyze(text, "en-SG")

	assert.NotEqual(t, VerdictSuspicious, a.Verdict, "a friendly message should not be suspicious")
	assert.Equal(t, VerdictLikelySafe, a.Verdict, "no risk signals present should be likely_safe")
	assert.Empty(t, a.Signals, "benign text should raise no signals")
	assert.NotEmpty(t, a.Limitations, "likely_safe must still carry limitations text")
}

func TestAnalyze_AmbiguousTextUnclear(t *testing.T) {
	// A single low-weight impersonation mention with no credential/money/link
	// request lands in the ambiguous band.
	text := "Hi, this is a message about your recent delivery."

	a := Analyze(text, "en-SG")

	assert.Equal(t, VerdictUnclear, a.Verdict, "a single weak signal should be unclear")
}

func TestAnalyze_Deterministic(t *testing.T) {
	text := "Congratulations! You have won a prize. Transfer a small processing fee via PayNow to claim."

	first := Analyze(text, "en-SG")
	second := Analyze(text, "en-SG")

	assert.Equal(t, first.Verdict, second.Verdict)
	assert.Equal(t, len(first.Signals), len(second.Signals))
	assert.Equal(t, first.SuggestedTags, second.SuggestedTags)
}

func TestAnalyze_LinkSanitizedToHostNeverClickable(t *testing.T) {
	text := "Claim your refund here: http://dbs-secure-login.example.ru/verify?token=abc123"

	a := Analyze(text, "en-SG")

	codes := signalCodes(a)
	require.True(t, codes[SignalSuspiciousLink], "lookalike host should be flagged")

	for _, s := range a.Signals {
		// No signal may echo a clickable scheme back to the client.
		assert.NotContains(t, s.EvidenceExcerpt, "http://")
		assert.NotContains(t, s.EvidenceExcerpt, "https://")
		assert.NotContains(t, s.EvidenceExcerpt, "?token=")
	}
}

func TestAnalyze_ShortenerLinkFlagged(t *testing.T) {
	text := "See this: https://bit.ly/3xYz please respond"

	a := Analyze(text, "en-SG")

	assert.True(t, signalCodes(a)[SignalSuspiciousLink], "URL shortener should be flagged")
}

func TestAnalyze_FriendlyPhishingStillSuspicious(t *testing.T) {
	// Benign markers must not excuse a strong-risk message.
	text := "Good morning! Please kindly confirm your password and OTP to reactivate your bank account. Thank you!"

	a := Analyze(text, "en-SG")

	assert.Equal(t, VerdictSuspicious, a.Verdict, "benign phrasing must not offset credential requests")
}

func TestHostOf(t *testing.T) {
	cases := map[string]string{
		"http://example.com/path?q=1":        "example.com",
		"https://www.DBS.com.sg/login":       "dbs.com.sg",
		"www.tinyurl.com/abc":                "tinyurl.com",
		"http://192.168.0.1/pay":             "192.168.0.1",
		"https://user:pass@evil.test:8443/x": "evil.test",
	}
	for in, want := range cases {
		assert.Equal(t, want, hostOf(in), "hostOf(%q)", in)
	}
}

func TestSanitizeLinksReplacesURLs(t *testing.T) {
	out := sanitizeLinks("go to https://phish.example.com/login now")
	assert.NotContains(t, out, "https://")
	assert.True(t, strings.Contains(out, "phish.example.com"), "host should be preserved as text")
}
