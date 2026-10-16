package checks

import (
	"context"
	"errors"
	"testing"
	"time"
)

type stubPhoneRepo struct {
	rep PhoneReputation
	err error

	// captured on InsertPhoneReport
	inserted    *PhoneReport
	insertedNow time.Time
	insertErr   error
}

func (s *stubPhoneRepo) GetPhoneReputation(_ context.Context, _ string, _ time.Time) (PhoneReputation, error) {
	return s.rep, s.err
}

func (s *stubPhoneRepo) InsertPhoneReport(_ context.Context, report PhoneReport, now time.Time) error {
	if s.insertErr != nil {
		return s.insertErr
	}
	s.inserted = &report
	s.insertedNow = now
	return nil
}

func TestLookupPhoneTrust_UnknownReturnsDefault(t *testing.T) {
	svc := NewService(nil, &stubPhoneRepo{rep: PhoneReputation{Found: false}}, nil, nil, nil)
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
	if got.Classification != "" {
		t.Errorf("unknown number classification = %q, want empty", got.Classification)
	}
}

func TestLookupPhoneTrust_ReportCountDerivesScore(t *testing.T) {
	// Many reports drive the score to the risky floor.
	risky := NewService(nil, &stubPhoneRepo{rep: PhoneReputation{Found: true, ReportCount: 42}}, nil, nil, nil)
	got, err := risky.LookupPhoneTrust(context.Background(), "12345678")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.TrustScore != TrustScoreMin || got.Rating != RatingHighRisk || got.ReportCount != 42 || !got.Known {
		t.Errorf("risky lookup = %+v", got)
	}

	// A single report dents the default score but stays mid-range.
	one := NewService(nil, &stubPhoneRepo{rep: PhoneReputation{Found: true, ReportCount: 1}}, nil, nil, nil)
	got, _ = one.LookupPhoneTrust(context.Background(), "12345678")
	if got.TrustScore != DefaultTrustScore-15 {
		t.Errorf("single-report score = %d, want %d", got.TrustScore, DefaultTrustScore-15)
	}
}

func TestLookupPhoneTrust_ClassificationSurfaced(t *testing.T) {
	svc := NewService(nil, &stubPhoneRepo{rep: PhoneReputation{Found: true, ReportCount: 3, Classification: "scam"}}, nil, nil, nil)
	got, err := svc.LookupPhoneTrust(context.Background(), "12345678")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Classification != "scam" {
		t.Errorf("classification = %q, want %q", got.Classification, "scam")
	}
}

func TestReportPhoneNumber_Valid(t *testing.T) {
	repo := &stubPhoneRepo{}
	svc := NewService(nil, repo, nil, nil, nil)
	err := svc.ReportPhoneNumber(context.Background(), PhoneReport{
		PhoneNumber:    "+65 1234-5678",
		Reason:         "scam",
		ReporterUserID: 7,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo.inserted == nil {
		t.Fatal("expected a report to be inserted")
	}
	if repo.inserted.PhoneNumber != "+6512345678" {
		t.Errorf("inserted number = %q, want %q", repo.inserted.PhoneNumber, "+6512345678")
	}
	if repo.inserted.Reason != "scam" {
		t.Errorf("inserted reason = %q, want %q", repo.inserted.Reason, "scam")
	}
	if repo.inserted.ReporterUserID != 7 {
		t.Errorf("inserted reporter = %d, want 7", repo.inserted.ReporterUserID)
	}
}

func TestReportPhoneNumber_Validation(t *testing.T) {
	cases := []struct {
		name    string
		in      PhoneReport
		wantErr error
	}{
		{"no digits", PhoneReport{PhoneNumber: "abc", Reason: "scam"}, ErrPhoneNumberRequired},
		{"empty reason", PhoneReport{PhoneNumber: "12345678", Reason: "  "}, ErrReasonRequired},
		{"reason too long", PhoneReport{PhoneNumber: "12345678", Reason: string(make([]byte, maxReasonLength+1))}, ErrReasonTooLong},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			repo := &stubPhoneRepo{}
			svc := NewService(nil, repo, nil, nil, nil)
			err := svc.ReportPhoneNumber(context.Background(), tc.in)
			if !errors.Is(err, tc.wantErr) {
				t.Errorf("err = %v, want %v", err, tc.wantErr)
			}
			if repo.inserted != nil {
				t.Errorf("no report should be inserted on validation failure, got %+v", repo.inserted)
			}
		})
	}
}

func TestReportPhoneNumber_DuplicatePropagates(t *testing.T) {
	// The repository rejects a second report from the same user while their
	// previous one is inside the reputation window; the service must surface
	// that as ErrPhoneReportDuplicate so the handler can answer 409.
	repo := &stubPhoneRepo{insertErr: ErrPhoneReportDuplicate}
	svc := NewService(nil, repo, nil, nil, nil)
	err := svc.ReportPhoneNumber(context.Background(), PhoneReport{
		PhoneNumber:    "+65 1234-5678",
		Reason:         "scam",
		ReporterUserID: 7,
	})
	if !errors.Is(err, ErrPhoneReportDuplicate) {
		t.Fatalf("err = %v, want %v", err, ErrPhoneReportDuplicate)
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
