package reports

import (
	"context"
	"errors"
	"testing"

	"scamshield/internal/classifier"
)

// fakeRepo is a minimal Repository that records the CreateReport params and
// echoes back a report whose category mirrors the inserted category_id.
type fakeRepo struct {
	created CreateReportParams
	cats    map[string]Category
	detail  Report
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{
		cats: map[string]Category{
			"phishing":      {ID: 1, Slug: "phishing", NameKey: "cat.phishing"},
			"impersonation": {ID: 2, Slug: "impersonation", NameKey: "cat.impersonation"},
		},
	}
}

func (f *fakeRepo) ListFeed(context.Context, FeedQuery, *int64) ([]ReportCard, error) {
	return nil, nil
}

func (f *fakeRepo) ListByAuthor(context.Context, int64, int, *Cursor) ([]ReportCard, error) {
	return nil, nil
}

func (f *fakeRepo) GetReportDetail(_ context.Context, _ int64, _ *int64, _ bool) (Report, error) {
	rep := f.detail
	rep.CategoryID = f.created.CategoryID
	if id := f.created.CategoryID; id != nil {
		for _, cat := range f.cats {
			if cat.ID == *id {
				c := cat
				rep.Category = &c
				break
			}
		}
	}
	return rep, nil
}

func (f *fakeRepo) GetCategoryBySlug(_ context.Context, slug string) (Category, error) {
	if c, ok := f.cats[slug]; ok {
		return c, nil
	}
	return Category{}, ErrUnknownCategory
}

func (f *fakeRepo) ListCategories(context.Context) ([]Category, error) { return nil, nil }

func (f *fakeRepo) ListTags(context.Context, string, int) ([]Tag, error) { return nil, nil }

func (f *fakeRepo) ResolveTagSlugs(context.Context, []string) ([]Tag, []string, error) {
	return nil, nil, nil
}

func (f *fakeRepo) CreateReport(_ context.Context, p CreateReportParams) (int64, error) {
	f.created = p
	return 42, nil
}

func (f *fakeRepo) UpdateReport(context.Context, int64, UpdateReportParams) error { return nil }

func (f *fakeRepo) SoftDeleteReport(context.Context, int64) error { return nil }

func (f *fakeRepo) GetReportOwnership(context.Context, int64) (*int64, bool, error) {
	return nil, true, nil
}

func (f *fakeRepo) CheckOwnedBy(context.Context, int64, int64) (bool, error) { return false, nil }

func (f *fakeRepo) RedactedImageKeyForCheck(context.Context, int64, int64) (string, bool, error) {
	return "", false, nil
}

func (f *fakeRepo) GetReportImageKey(context.Context, int64) (string, bool, error) {
	return "", false, nil
}

func (f *fakeRepo) SetReaction(context.Context, int64, int64, int16) (int64, int64, error) {
	return 0, 0, nil
}

func (f *fakeRepo) RemoveReaction(context.Context, int64, int64) (int64, int64, error) {
	return 0, 0, nil
}

func (f *fakeRepo) ReportVisible(context.Context, int64) (bool, error) { return true, nil }

// stubClassifier returns a fixed slug, or an error when slug is empty.
type stubClassifier struct {
	slug string
	err  error
}

func (s stubClassifier) Classify(context.Context, string, string) (classifier.Result, error) {
	if s.err != nil {
		return classifier.Result{}, s.err
	}
	return classifier.Result{Slug: s.slug, Confidence: 1}, nil
}

func TestCreateAssignsCategoryFromClassifier(t *testing.T) {
	tests := []struct {
		name       string
		classifier stubClassifier
		wantSlug   string
	}{
		{name: "predicted phishing", classifier: stubClassifier{slug: "phishing"}, wantSlug: "phishing"},
		{name: "predicted impersonation", classifier: stubClassifier{slug: "impersonation"}, wantSlug: "impersonation"},
		{name: "unknown slug stays unclassified", classifier: stubClassifier{slug: "crypto-rug"}, wantSlug: ""},
		{name: "classifier failure stays unclassified", classifier: stubClassifier{err: errors.New("boom")}, wantSlug: ""},
		{name: "empty prediction stays unclassified", classifier: stubClassifier{}, wantSlug: ""},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			repo := newFakeRepo()
			svc := NewService(repo, tc.classifier, nil)

			_, err := svc.Create(context.Background(), CreateInput{
				AuthorUserID:       7,
				Title:              "Fake DBS SMS",
				RedactedText:       "Call 91234567 to verify your account.",
				ConfirmPublication: true,
			})
			if err != nil {
				t.Fatalf("Create: unexpected error: %v", err)
			}
			if repo.created.Title != "Fake DBS SMS" {
				t.Errorf("inserted Title = %q, want the submitted title", repo.created.Title)
			}

			if tc.wantSlug == "" {
				if repo.created.CategoryID != nil {
					t.Errorf("CategoryID = %v, want nil (unclassified)", *repo.created.CategoryID)
				}
				return
			}
			if repo.created.CategoryID == nil {
				t.Fatal("CategoryID = nil, want the classifier's category")
			}
			if got := repo.cats[tc.wantSlug].ID; *repo.created.CategoryID != got {
				t.Errorf("CategoryID = %d, want %d", *repo.created.CategoryID, got)
			}
		})
	}
}

func TestCreateWithoutClassifierStaysUnclassified(t *testing.T) {
	repo := newFakeRepo()
	svc := NewService(repo, nil, nil)

	if _, err := svc.Create(context.Background(), CreateInput{
		AuthorUserID:       7,
		Title:              "Prize scam",
		RedactedText:       "You won a prize, send a fee to claim.",
		ConfirmPublication: true,
	}); err != nil {
		t.Fatalf("Create: unexpected error: %v", err)
	}
	if repo.created.CategoryID != nil {
		t.Errorf("CategoryID = %v, want nil", *repo.created.CategoryID)
	}
}

func TestCreateRequiresConfirmation(t *testing.T) {
	repo := newFakeRepo()
	svc := NewService(repo, classifier.NewStub(), nil)

	_, err := svc.Create(context.Background(), CreateInput{
		AuthorUserID: 7,
		Title:        "No confirmation",
		RedactedText: "body",
	})
	if !errors.Is(err, ErrConfirmationRequired) {
		t.Fatalf("err = %v, want ErrConfirmationRequired", err)
	}
	if repo.created.Title != "" {
		t.Error("no report should be inserted without confirmation")
	}
}
