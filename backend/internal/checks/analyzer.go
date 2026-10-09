package checks

import (
	"net"
	"regexp"
	"sort"
	"strings"
)

// signalCode identifies a category of detected warning sign. Codes are stable
// and safe to key client copy or telemetry against.
const (
	SignalUrgency        = "urgency"
	SignalCredential     = "credential_request"
	SignalMoney          = "money_request"
	SignalSuspiciousLink = "suspicious_link"
	SignalPrize          = "prize_lottery"
	SignalImpersonation  = "authority_impersonation"
)

// Suggested tag slugs. These are editable suggestions, not authoritative
// taxonomy entries.
const (
	tagPhishing          = "phishing"
	tagOTPScam           = "otp-scam"
	tagBankImpersonation = "bank-impersonation"
	tagPrizeScam         = "prize-scam"
	tagDeliveryScam      = "delivery-scam"
	tagMoneyRequest      = "money-request"
	tagSuspiciousLink    = "suspicious-link"
)

// Scoring thresholds. A summed weight at or above suspiciousThreshold yields a
// "suspicious" verdict; at or above unclearThreshold yields "unclear"; below
// that with no offsetting risk yields "likely_safe". The gap deliberately
// biases ambiguous input toward "unclear".
const (
	suspiciousThreshold = 5
	unclearThreshold    = 2
)

// Signal weights. Credential and money requests carry the most weight because
// they map most directly to resident harm.
const (
	weightUrgency        = 2
	weightCredential     = 3
	weightMoney          = 3
	weightSuspiciousLink = 3
	weightPrize          = 2
	weightImpersonation  = 1
)

const (
	// maxExcerptRunes bounds how much of the input is echoed back per signal.
	maxExcerptRunes = 80

	limitationsText = "This is automated guidance based on common scam patterns, " +
		"not a guarantee. A \"likely_safe\" result is not a safety guarantee — " +
		"treat any unexpected request for money, credentials, or personal details " +
		"with caution and verify through official channels."
)

// rule pairs a signal code with the phrases that trigger it and the metadata
// used to build a Signal.
type rule struct {
	code        string
	weight      int
	phrases     []string
	explanation string
}

// textRules are matched case-insensitively against the normalized input. Link
// and structural detection are handled separately below.
var textRules = []rule{
	{
		code:   SignalUrgency,
		weight: weightUrgency,
		phrases: []string{
			"urgent", "immediately", "act now", "right now", "within 24 hours",
			"within 24hrs", "account suspended", "account has been suspended",
			"verify now", "last warning", "final notice", "expires today",
			"限时", "立即", "马上",
		},
		explanation: "Creates a false sense of urgency to pressure you into acting before you can think or verify.",
	},
	{
		code:   SignalCredential,
		weight: weightCredential,
		phrases: []string{
			"password", "otp", "one-time", "one time password", "pin", "cvv",
			"login", "log in", "verify your account", "confirm your identity",
			"security code", "authentication code", "singpass", "验证码",
		},
		explanation: "Asks for credentials, one-time codes, or account details. Legitimate organisations never ask for these.",
	},
	{
		code:   SignalMoney,
		weight: weightMoney,
		phrases: []string{
			"transfer", "bank account", "paynow", "gift card", "bitcoin", "crypto",
			"wire", "refund", "processing fee", "admin fee", "pay a fee",
			"deposit", "western union", "汇款", "转账",
		},
		explanation: "Requests money, a transfer, or payment details — a common way scammers extract funds.",
	},
	{
		code:   SignalPrize,
		weight: weightPrize,
		phrases: []string{
			"you have won", "you've won", "congratulations", "claim your prize",
			"lucky winner", "lottery", "you are selected", "free gift", "cash prize",
			"中奖", "恭喜",
		},
		explanation: "Promises a prize or windfall you did not enter for, a classic lure to collect personal or payment details.",
	},
	{
		code:   SignalImpersonation,
		weight: weightImpersonation,
		phrases: []string{
			"bank", "police", "iras", "mom", "cpf", "government", "delivery",
			"customs", "singpost", "ministry", "immigration", "court", "官方",
		},
		explanation: "Claims to be from a bank, government agency, or delivery service to borrow their authority. Verify independently.",
	},
}

// benignMarkers slightly reduce the score. They are weak signals of ordinary,
// non-coercive messages and only matter when no strong risk signal fired.
var benignMarkers = []string{
	"thank you", "thanks", "see you", "let me know", "no rush", "whenever you",
	"how are you", "good morning", "good night", "take care",
}

// urlRegex matches http(s) and bare www URLs so hosts can be extracted and
// sanitized. Matched URLs are never echoed back verbatim.
var urlRegex = regexp.MustCompile(`(?i)\b((?:https?://|www\.)[^\s<>"']+)`)

// shortenerHosts are common URL-shortening services. A shortened link hides the
// true destination, which is a risk factor on its own.
var shortenerHosts = map[string]struct{}{
	"bit.ly": {}, "tinyurl.com": {}, "goo.gl": {}, "t.co": {}, "ow.ly": {},
	"is.gd": {}, "buff.ly": {}, "rebrand.ly": {}, "cutt.ly": {}, "rb.gy": {},
	"shorturl.at": {}, "tiny.cc": {},
}

// Analyze runs the rules-first explainable classifier over text. It is a pure,
// deterministic function with no I/O: identical input yields an identical
// Assessment, which makes it directly unit-testable. locale is accepted for
// future locale-specific tuning and to shape recommended actions.
func Analyze(text, locale string) Assessment {
	lower := strings.ToLower(text)

	var signals []Signal
	detected := map[string]bool{}
	score := 0

	for _, ru := range textRules {
		if matched, phrase := firstMatch(lower, ru.phrases); matched {
			detected[ru.code] = true
			score += ru.weight
			signals = append(signals, Signal{
				Code:            ru.code,
				EvidenceExcerpt: excerptAround(text, phrase),
				Explanation:     ru.explanation,
			})
		}
	}

	// Link analysis: extract hosts, never emit clickable URLs.
	if linkSignal, hit := analyzeLinks(text); hit {
		detected[SignalSuspiciousLink] = true
		score += weightSuspiciousLink
		signals = append(signals, linkSignal)
	}

	// Benign markers only pull the score down when no strong risk signal is
	// present, so a friendly-sounding phishing message is not excused.
	strongRisk := detected[SignalCredential] || detected[SignalMoney] || detected[SignalSuspiciousLink]
	if !strongRisk && containsAny(lower, benignMarkers) {
		score--
	}

	verdict := classify(score)

	return Assessment{
		Verdict:            verdict,
		Signals:            signals,
		Uncertainty:        uncertaintyFor(verdict, len(signals)),
		Limitations:        limitationsText,
		RecommendedActions: recommendedActions(detected, verdict, locale),
		SuggestedTags:      suggestedTags(detected),
	}
}

// classify maps a summed score to a verdict, defaulting to "unclear" in the
// ambiguous middle band.
func classify(score int) string {
	switch {
	case score >= suspiciousThreshold:
		return VerdictSuspicious
	case score >= unclearThreshold:
		return VerdictUnclear
	case score <= 0:
		return VerdictLikelySafe
	default:
		// Exactly one low-weight signal: not enough to be safe, not enough to be
		// suspicious. Bias to unclear.
		return VerdictUnclear
	}
}

func uncertaintyFor(verdict string, signalCount int) string {
	switch verdict {
	case VerdictSuspicious:
		return "Multiple scam patterns were detected. This assessment is based on common patterns and may still miss or over-flag; when in doubt, verify through official channels."
	case VerdictLikelySafe:
		return "No common scam patterns were detected, but automated checks can miss novel or well-crafted scams. Stay cautious with unexpected requests."
	default:
		if signalCount == 0 {
			return "There was not enough signal to reach a confident conclusion. Treat the message with caution."
		}
		return "Some warning signs were detected but they are not conclusive. Verify independently before acting."
	}
}

// firstMatch returns the first phrase (from phrases) that appears in the
// already-lowercased haystack.
func firstMatch(lowerHaystack string, phrases []string) (bool, string) {
	for _, p := range phrases {
		if strings.Contains(lowerHaystack, p) {
			return true, p
		}
	}
	return false, ""
}

func containsAny(lowerHaystack string, phrases []string) bool {
	ok, _ := firstMatch(lowerHaystack, phrases)
	return ok
}

// excerptAround returns a short, sanitized snippet of the original text centered
// on the matched phrase. Any URLs inside the snippet are reduced to their host
// so no clickable link is ever echoed back. The result is length-bounded.
func excerptAround(original, lowerPhrase string) string {
	idx := strings.Index(strings.ToLower(original), lowerPhrase)
	if idx < 0 {
		return truncateRunes(sanitizeLinks(strings.TrimSpace(original)), maxExcerptRunes)
	}

	runes := []rune(original)
	// Convert the byte index to a rune index for safe slicing.
	startRune := len([]rune(original[:idx]))
	phraseRunes := len([]rune(lowerPhrase))

	const pad = 24
	from := startRune - pad
	if from < 0 {
		from = 0
	}
	to := startRune + phraseRunes + pad
	if to > len(runes) {
		to = len(runes)
	}

	snippet := string(runes[from:to])
	if from > 0 {
		snippet = "…" + snippet
	}
	if to < len(runes) {
		snippet = snippet + "…"
	}
	return truncateRunes(sanitizeLinks(strings.TrimSpace(snippet)), maxExcerptRunes)
}

// sanitizeLinks replaces any URL in s with a host-only, non-clickable
// representation like "[link: example.com]".
func sanitizeLinks(s string) string {
	return urlRegex.ReplaceAllStringFunc(s, func(match string) string {
		host := hostOf(match)
		if host == "" {
			return "[link]"
		}
		return "[link: " + host + "]"
	})
}

func truncateRunes(s string, max int) string {
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	return strings.TrimSpace(string(runes[:max])) + "…"
}

// analyzeLinks scans the text for URLs, extracts hosts, and flags shorteners,
// lookalike/punycode hosts, and raw IP hosts. It never returns a clickable URL.
func analyzeLinks(text string) (Signal, bool) {
	matches := urlRegex.FindAllString(text, -1)
	if len(matches) == 0 {
		return Signal{}, false
	}

	var flaggedHosts []string
	var reasons []string
	seen := map[string]bool{}

	for _, m := range matches {
		host := hostOf(m)
		if host == "" || seen[host] {
			continue
		}
		seen[host] = true

		reason := linkRisk(host)
		if reason != "" {
			flaggedHosts = append(flaggedHosts, host)
			reasons = append(reasons, reason)
		}
	}

	if len(flaggedHosts) == 0 {
		return Signal{}, false
	}

	sort.Strings(flaggedHosts)
	explanation := "Contains a link that looks risky: " + strings.Join(dedupe(reasons), "; ") +
		". Do not tap links in unexpected messages; go to the official site directly."

	return Signal{
		Code:            SignalSuspiciousLink,
		EvidenceExcerpt: "[link: " + strings.Join(flaggedHosts, ", ") + "]",
		Explanation:     explanation,
	}, true
}

// linkRisk classifies why a host is risky, or "" if it looks ordinary.
func linkRisk(host string) string {
	h := strings.ToLower(host)

	if net.ParseIP(h) != nil {
		return "uses a raw IP address instead of a domain name"
	}
	if _, ok := shortenerHosts[h]; ok {
		return "uses a URL shortener that hides the true destination"
	}
	if strings.HasPrefix(h, "xn--") || strings.Contains(h, ".xn--") {
		return "uses punycode, which can disguise a lookalike domain"
	}
	if looksLikeLookalike(h) {
		return "resembles a well-known brand but is not the official domain"
	}
	return ""
}

// lookalikeBrands are brand tokens commonly impersonated. A host that embeds one
// of these but is not the brand's real domain is treated as a lookalike.
var lookalikeBrands = map[string][]string{
	"paypal":   {"paypal.com"},
	"dbs":      {"dbs.com.sg", "dbs.com"},
	"ocbc":     {"ocbc.com"},
	"uob":      {"uob.com.sg", "uobgroup.com"},
	"posb":     {"posb.com.sg"},
	"singpost": {"singpost.com"},
	"singpass": {"singpass.gov.sg"},
	"apple":    {"apple.com"},
	"amazon":   {"amazon.com", "amazon.sg"},
}

func looksLikeLookalike(host string) bool {
	for brand, legit := range lookalikeBrands {
		if !strings.Contains(host, brand) {
			continue
		}
		isLegit := false
		for _, d := range legit {
			if host == d || strings.HasSuffix(host, "."+d) {
				isLegit = true
				break
			}
		}
		if !isLegit {
			return true
		}
	}
	return false
}

// hostOf extracts a bare host from a URL-ish token, without pulling in path,
// query, or scheme. It is deliberately forgiving because it operates on
// free-form message text rather than well-formed URLs.
func hostOf(raw string) string {
	s := strings.TrimSpace(raw)
	// Strip scheme.
	if i := strings.Index(s, "://"); i >= 0 {
		s = s[i+3:]
	}
	s = strings.TrimPrefix(s, "www.")
	// Cut at the first path/query/fragment separator.
	if i := strings.IndexAny(s, "/?#"); i >= 0 {
		s = s[:i]
	}
	// Drop userinfo and port.
	if i := strings.LastIndex(s, "@"); i >= 0 {
		s = s[i+1:]
	}
	if i := strings.LastIndex(s, ":"); i >= 0 {
		// Keep IPv6-in-brackets intact; otherwise treat as host:port.
		if !strings.Contains(s, "]") {
			s = s[:i]
		}
	}
	// Trim trailing punctuation that commonly clings to URLs in prose.
	s = strings.TrimRight(s, ".,);]!\"'")
	return strings.ToLower(s)
}

// recommendedActions builds situation-specific next steps keyed to what was
// detected. Actions are Singapore-oriented (ScamShield 1799) per the pilot
// scope; locale is available for future localisation.
func recommendedActions(detected map[string]bool, verdict, locale string) []RecommendedAction {
	var actions []RecommendedAction

	if detected[SignalCredential] {
		actions = append(actions, RecommendedAction{
			Scenario: "shared_credentials",
			Title:    "Do not share passwords, OTPs, PINs, or Singpass details. No genuine bank or agency will ask for them.",
			Urgency:  UrgencyUrgent,
		})
	}
	if detected[SignalMoney] {
		actions = append(actions, RecommendedAction{
			Scenario: "sent_money",
			Title:    "Do not transfer money or pay any fee. If you already have, contact your bank immediately to try to stop the transfer.",
			Urgency:  UrgencyUrgent,
		})
	}
	if detected[SignalSuspiciousLink] {
		actions = append(actions, RecommendedAction{
			Scenario: "clicked_link",
			Title:    "Do not tap the link. Reach the organisation through its official app or website typed in yourself.",
			Urgency:  UrgencyUrgent,
		})
	}
	if detected[SignalImpersonation] {
		actions = append(actions, RecommendedAction{
			Scenario: "just_received",
			Title:    "Verify the sender independently using an official contact number, not one provided in the message.",
			Urgency:  UrgencyNormal,
		})
	}

	// Always offer a report/verify next step for anything not clearly safe.
	if verdict != VerdictLikelySafe {
		actions = append(actions, RecommendedAction{
			Scenario: "just_received",
			Title:    "Check with ScamShield (call 1799) or the official organisation before you act.",
			Urgency:  UrgencyNormal,
		})
	}

	if len(actions) == 0 {
		actions = append(actions, RecommendedAction{
			Scenario: "just_received",
			Title:    "Nothing obvious stood out, but stay cautious with unexpected requests and verify through official channels.",
			Urgency:  UrgencyNormal,
		})
	}
	return actions
}

// suggestedTags produces editable slugs based on detected signals. The result
// is deterministically ordered.
func suggestedTags(detected map[string]bool) []string {
	var tags []string
	add := func(t string) { tags = append(tags, t) }

	if detected[SignalCredential] {
		add(tagPhishing)
		add(tagOTPScam)
	}
	if detected[SignalImpersonation] {
		add(tagBankImpersonation)
		add(tagDeliveryScam)
	}
	if detected[SignalPrize] {
		add(tagPrizeScam)
	}
	if detected[SignalMoney] {
		add(tagMoneyRequest)
	}
	if detected[SignalSuspiciousLink] {
		add(tagSuspiciousLink)
	}
	return dedupe(tags)
}

// dedupe returns the input with duplicates removed, preserving first-seen order.
func dedupe(in []string) []string {
	seen := map[string]bool{}
	out := in[:0:0]
	for _, s := range in {
		if seen[s] {
			continue
		}
		seen[s] = true
		out = append(out, s)
	}
	return out
}
