package checks

import (
	"context"
	"regexp"
	"strings"
)

// Phone-number trust scoring. A trust score is an integer in [0, 100] where 0
// means highly likely to be a scam and 100 means highly trustworthy. A number
// with no data in the scam database scores the neutral default below.
const (
	// TrustScoreMin / TrustScoreMax bound the trust score.
	TrustScoreMin = 0
	TrustScoreMax = 100

	// DefaultTrustScore is returned for a number the database has never seen. It
	// is deliberately mid-range (neither trusted nor risky) so an unknown number
	// is not treated as safe.
	DefaultTrustScore = 60
)

// Trust rating buckets derived from the numeric score. These give clients a
// stable label to render without hard-coding thresholds.
const (
	RatingHighRisk = "high_risk" // 0–39
	RatingUnknown  = "unknown"   // 40–69 (includes the default for unseen numbers)
	RatingTrusted  = "trusted"   // 70–100
)

// ErrInvalidPhoneNumber is returned when a phone number cannot be normalized to
// anything usable (e.g. it contains no digits).
var phoneStripPattern = regexp.MustCompile(`[^\d+]`)

// PhoneTrust is the result of a phone-number trust lookup.
type PhoneTrust struct {
	// PhoneNumber is the normalized number the score applies to.
	PhoneNumber string
	// TrustScore is in [0, 100]; higher is more trustworthy.
	TrustScore int
	// Rating is the categorical bucket for TrustScore.
	Rating string
	// ReportCount is how many scam reports back this number (0 when unseen).
	ReportCount int64
	// Known indicates whether the number was found in the scam database. When
	// false, TrustScore is DefaultTrustScore and ReportCount is 0.
	Known bool
}

// PhoneReputation is the raw datum the repository returns for a number. The
// data source (owned by the DB/data team) is not yet wired; the repository
// returns Found=false until then.
type PhoneReputation struct {
	Found       bool
	TrustScore  int
	ReportCount int64
}

// PhoneRepository is the persistence contract for phone-number reputation
// lookups. It is separate from the main checks Repository so the (future)
// phone-number data source can be implemented and injected independently.
type PhoneRepository interface {
	// GetPhoneReputation returns reputation data for a normalized phone number.
	// A number absent from the data source returns Found=false (not an error).
	GetPhoneReputation(ctx context.Context, normalized string) (PhoneReputation, error)
}

// LookupPhoneTrust normalizes the number, queries the reputation source, and
// maps the result to a bounded trust score and rating. Unknown numbers return
// the neutral default score. It never returns an error for an unseen number.
func (s *Service) LookupPhoneTrust(ctx context.Context, rawPhoneNumber string) (PhoneTrust, error) {
	normalized := normalizePhoneNumber(rawPhoneNumber)

	// A number with no usable digits still yields a well-formed neutral result
	// rather than an error, keeping the endpoint simple for clients.
	if normalized == "" {
		return PhoneTrust{
			PhoneNumber: strings.TrimSpace(rawPhoneNumber),
			TrustScore:  DefaultTrustScore,
			Rating:      ratingForScore(DefaultTrustScore),
			ReportCount: 0,
			Known:       false,
		}, nil
	}

	rep, err := s.phones.GetPhoneReputation(ctx, normalized)
	if err != nil {
		return PhoneTrust{}, err
	}

	if !rep.Found {
		return PhoneTrust{
			PhoneNumber: normalized,
			TrustScore:  DefaultTrustScore,
			Rating:      ratingForScore(DefaultTrustScore),
			ReportCount: 0,
			Known:       false,
		}, nil
	}

	score := clampScore(rep.TrustScore)
	return PhoneTrust{
		PhoneNumber: normalized,
		TrustScore:  score,
		Rating:      ratingForScore(score),
		ReportCount: rep.ReportCount,
		Known:       true,
	}, nil
}

// normalizePhoneNumber strips formatting so lookups are consistent. It keeps a
// single leading '+' (country prefix) and digits only; all spaces, hyphens,
// parentheses and other characters are removed.
func normalizePhoneNumber(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}
	hasPlus := strings.HasPrefix(trimmed, "+")
	digits := phoneStripPattern.ReplaceAllString(trimmed, "")
	digits = strings.ReplaceAll(digits, "+", "")
	if digits == "" {
		return ""
	}
	if hasPlus {
		return "+" + digits
	}
	return digits
}

// clampScore constrains a raw score to [TrustScoreMin, TrustScoreMax].
func clampScore(score int) int {
	if score < TrustScoreMin {
		return TrustScoreMin
	}
	if score > TrustScoreMax {
		return TrustScoreMax
	}
	return score
}

// ratingForScore maps a numeric trust score to its categorical bucket.
func ratingForScore(score int) string {
	switch {
	case score < 40:
		return RatingHighRisk
	case score < 70:
		return RatingUnknown
	default:
		return RatingTrusted
	}
}
