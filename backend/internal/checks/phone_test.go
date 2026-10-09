package checks

import (
	"context"
	"testing"
)

type stubPhoneRepo struct {
	rep PhoneReputation
	err error
}

func (s stubPhoneRepo) GetPhoneReputation(_ context.Context, _ string) (PhoneReputation, error) {
	return s.rep, s.err
}

func TestLookupPhoneTrust_UnknownReturnsDefault(t *testing.T) {
	svc := NewService(nil, stubPhoneRepo{rep: PhoneReputation{Found: false}})
	got, err := svc.LookupPhoneTrust(context.Background(), "+65 1234 5678")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.TrustScore != DefaultTrustScore {
		t.Errorf("unknown number score = %d, want %d", got.TrustScore, DefaultTrustScore)
	}
	if got.Known {
		t.Errorf("unknown number should have Known=false")
	}
	if got.PhoneNumber != "+6512345678" {
		t.Errorf("normalized number = %q, want %q", got.PhoneNumber, "+6512345678")
	}
	if got.Rating != RatingUnknown {
		t.Errorf("rating = %q, want %q", got.Rating, RatingUnknown)
	}
}

func TestLookupPhoneTrust_KnownRiskyAndTrusted(t *testing.T) {
	risky := NewService(nil, stubPhoneRepo{rep: PhoneReputation{Found: true, TrustScore: 10, ReportCount: 42}})
	got, err := risky.LookupPhoneTrust(context.Background(), "12345678")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.TrustScore != 10 || got.Rating != RatingHighRisk || got.ReportCount != 42 || !got.Known {
		t.Errorf("risky lookup = %+v", got)
	}

	trusted := NewService(nil, stubPhoneRepo{rep: PhoneReputation{Found: true, TrustScore: 95}})
	got, _ = trusted.LookupPhoneTrust(context.Background(), "12345678")
	if got.Rating != RatingTrusted {
		t.Errorf("trusted rating = %q, want %q", got.Rating, RatingTrusted)
	}
}

func TestLookupPhoneTrust_ScoreClamped(t *testing.T) {
	svc := NewService(nil, stubPhoneRepo{rep: PhoneReputation{Found: true, TrustScore: 250}})
	got, _ := svc.LookupPhoneTrust(context.Background(), "12345678")
	if got.TrustScore != TrustScoreMax {
		t.Errorf("clamped score = %d, want %d", got.TrustScore, TrustScoreMax)
	}
}

func TestNormalizePhoneNumber(t *testing.T) {
	cases := map[string]string{
		"+65 1234-5678":  "+6512345678",
		"(65) 1234 5678": "6512345678",
		"  ":             "",
		"abc":            "",
	}
	for in, want := range cases {
		if got := normalizePhoneNumber(in); got != want {
			t.Errorf("normalize(%q) = %q, want %q", in, got, want)
		}
	}
}
