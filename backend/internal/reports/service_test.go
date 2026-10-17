package reports

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"scamshield/internal/classifier"
)

// fakeRepo is a minimal Repository that records the CreateReport params and
// echoes back a report whose category mirrors the inserted category_id.
type fakeRepo struct {
	created CreateReportParams
	cats    map[string]Category
	tags    map[string]Tag
	detail  Report
}

func newFakeRepo() *fakeRepo {
	return &fakeRepo{
		cats: map[string]Category{
			"phishing":      {ID: 1, Slug: "phishing", NameKey: "cat.phishing"},
			"impersonation": {ID: 2, Slug: "impersonation", NameKey: "cat.impersonation"},
			"other":         {ID: 3, Slug: "other", NameKey: "cat.other"},
		},
		tags: map[string]Tag{
			"phishing": {ID: 10, Slug: "phishing", NameKey: "tag.phishing"},
			"otp-scam": {ID: 11, Slug: "otp-scam", NameKey: "tag.otp_scam"},
			"other":    {ID: 12, Slug: "other", NameKey: "tag.other"},
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

func (f *fakeRepo) ResolveTagSlugs(_ context.Context, slugs []string) ([]Tag, []string, error) {
	var found []Tag
	var unknown []string
	for _, s := range slugs {
		if t, ok := f.tags[s]; ok {
			found = append(found, t)
		} else {
			unknown = append(unknown, s)
		}
	}
	return found, unknown, nil
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

func (f *fakeRepo) RedactedImageForUpload(context.Context, int64, int64) (string, string, bool, error) {
	return "", "", false, nil
}

func (f *fakeRepo) ListReportImages(context.Context, int64) ([]ReportImage, error) {
	return nil, nil
}

func (f *fakeRepo) SetReaction(context.Context, int64, int64, int16) (int64, int64, error) {
	return 0, 0, nil
}

func (f *fakeRepo) RemoveReaction(context.Context, int64, int64) (int64, int64, error) {
	return 0, 0, nil
}

func (f *fakeRepo) ReportVisible(context.Context, int64) (bool, error) { return true, nil }

// stubClassifier returns fixed predictions, or an error when err is set.
type stubClassifier struct {
	slug string
	tags []string
	err  error
}

func (s stubClassifier) Classify(context.Context, string, string) (classifier.Result, error) {
	if s.err != nil {
		return classifier.Result{}, s.err
	}
	return classifier.Result{Slug: s.slug, Confidence: 1, Tags: s.tags}, nil
}

func TestCreateAssignsCategoryFromClassifier(t *testing.T) {
	tests := []struct {
		name       string
		classifier stubClassifier
		wantSlug   string
	}{
		{name: "predicted phishing", classifier: stubClassifier{slug: "phishing"}, wantSlug: "phishing"},
		{name: "predicted impersonation", classifier: stubClassifier{slug: "impersonation"}, wantSlug: "impersonation"},
		{name: "unknown slug falls back to other", classifier: stubClassifier{slug: "crypto-rug"}, wantSlug: "other"},
		{name: "classifier failure falls back to other", classifier: stubClassifier{err: errors.New("boom")}, wantSlug: "other"},
		{name: "empty prediction falls back to other", classifier: stubClassifier{}, wantSlug: "other"},
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

			if repo.created.CategoryID == nil {
				t.Fatal("CategoryID = nil, want a resolved category")
			}
			if got := repo.cats[tc.wantSlug].ID; *repo.created.CategoryID != got {
				t.Errorf("CategoryID = %d, want %d", *repo.created.CategoryID, got)
			}
		})
	}
}

func TestCreateWithoutClassifierFallsBackToOther(t *testing.T) {
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
	if repo.created.CategoryID == nil || *repo.created.CategoryID != repo.cats["other"].ID {
		t.Errorf("CategoryID = %v, want the 'other' category (%d)", repo.created.CategoryID, repo.cats["other"].ID)
	}
	want := []int64{repo.tags["other"].ID}
	if !reflect.DeepEqual(repo.created.TagIDs, want) {
		t.Errorf("TagIDs = %v, want %v", repo.created.TagIDs, want)
	}
}

func TestCreateAssignsTagsFromClassifier(t *testing.T) {
	repo := newFakeRepo()
	svc := NewService(repo, stubClassifier{
		slug: "phishing",
		// The unknown slug and the duplicate are silently dropped, not fatal.
		tags: []string{"phishing", "otp-scam", "does-not-exist", "phishing"},
	}, nil)

	if _, err := svc.Create(context.Background(), CreateInput{
		AuthorUserID:       7,
		Title:              "Fake DBS SMS",
		RedactedText:       "Call 91234567 to verify your account.",
		ConfirmPublication: true,
	}); err != nil {
		t.Fatalf("Create: unexpected error: %v", err)
	}
	want := []int64{10, 11}
	if !reflect.DeepEqual(repo.created.TagIDs, want) {
		t.Errorf("TagIDs = %v, want %v", repo.created.TagIDs, want)
	}
}

func TestCreateClassifierFailureFallsBackToOtherTag(t *testing.T) {
	repo := newFakeRepo()
	svc := NewService(repo, stubClassifier{err: errors.New("boom")}, nil)

	if _, err := svc.Create(context.Background(), CreateInput{
		AuthorUserID:       7,
		Title:              "Fake DBS SMS",
		RedactedText:       "body",
		ConfirmPublication: true,
	}); err != nil {
		t.Fatalf("Create: unexpected error: %v", err)
	}
	want := []int64{repo.tags["other"].ID}
	if !reflect.DeepEqual(repo.created.TagIDs, want) {
		t.Errorf("TagIDs = %v, want %v (the 'other' tag)", repo.created.TagIDs, want)
	}
}

func TestCreateUnknownTagsFallBackToOther(t *testing.T) {
	repo := newFakeRepo()
	svc := NewService(repo, stubClassifier{
		slug: "phishing",
		// Every predicted slug is unknown, so nothing resolves and the post
		// falls back to the "other" tag rather than going untagged.
		tags: []string{"does-not-exist", "also-missing"},
	}, nil)

	if _, err := svc.Create(context.Background(), CreateInput{
		AuthorUserID:       7,
		Title:              "Fake DBS SMS",
		RedactedText:       "Call 91234567 to verify your account.",
		ConfirmPublication: true,
	}); err != nil {
		t.Fatalf("Create: unexpected error: %v", err)
	}
	want := []int64{repo.tags["other"].ID}
	if !reflect.DeepEqual(repo.created.TagIDs, want) {
		t.Errorf("TagIDs = %v, want %v (the 'other' tag)", repo.created.TagIDs, want)
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
