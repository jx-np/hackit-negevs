package checks

import (
	"bytes"
	"context"
	"errors"
	"io"
	"sync"
	"testing"

	"scamshield/internal/pii"
	"scamshield/internal/storage"
)

// fakeRepo embeds Repository so a test only has to implement the methods its
// code path actually calls. Any un-stubbed method would nil-panic, which is a
// useful signal that a test exercises more than it intended.
type fakeRepo struct {
	Repository

	mu sync.Mutex

	upload    Upload
	uploadErr error

	check    Check
	checkErr error

	createdUpload     *CreateUploadParams
	markedProcessing  int64
	createCheckParams *CreateCheckParams
	linkedUpload      int64
	linkedCheck       int64
	completeCalled    bool
	completedCheck    int64
	completedText     *string
	completedAssess   *Assessment
	failCalled        bool
	failedCheck       int64
}

func (f *fakeRepo) GetUploadByID(_ context.Context, _ int64) (Upload, error) {
	return f.upload, f.uploadErr
}

func (f *fakeRepo) GetCheckByID(_ context.Context, _ int64) (Check, error) {
	return f.check, f.checkErr
}

func (f *fakeRepo) CreateUpload(_ context.Context, p CreateUploadParams) (Upload, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.createdUpload = &p
	return Upload{
		ID:          42,
		OwnerUserID: p.OwnerUserID,
		StorageKey:  p.StorageKey,
		MediaType:   p.MediaType,
		ByteSize:    p.ByteSize,
		Status:      UploadStatusUploaded,
	}, nil
}

func (f *fakeRepo) MarkUploadProcessing(_ context.Context, id int64) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.markedProcessing = id
	return nil
}

func (f *fakeRepo) CreateCheck(_ context.Context, p CreateCheckParams) (Check, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.createCheckParams = &p
	if f.checkErr != nil {
		return Check{}, f.checkErr
	}
	if f.check.ID != 0 {
		return f.check, nil
	}
	return Check{ID: 7, OwnerUserID: p.OwnerUserID, Status: p.Status, Locale: p.Locale}, nil
}

func (f *fakeRepo) LinkUploadToCheck(_ context.Context, uploadID, checkID int64) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.linkedUpload, f.linkedCheck = uploadID, checkID
	return nil
}

func (f *fakeRepo) CompleteUploadRedaction(_ context.Context, _ int64, _ *string, _ string) error {
	return nil
}

func (f *fakeRepo) FailUpload(_ context.Context, _ int64) error { return nil }

func (f *fakeRepo) CompleteCheckFromUpload(_ context.Context, checkID int64, extractedText *string, a *Assessment) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.completeCalled = true
	f.completedCheck = checkID
	f.completedText = extractedText
	f.completedAssess = a
	return nil
}

func (f *fakeRepo) FailCheck(_ context.Context, checkID int64) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.failCalled = true
	f.failedCheck = checkID
	return nil
}

// fakeStore is an in-memory storage.Store.
type fakeStore struct {
	mu   sync.Mutex
	data []byte
}

func (s *fakeStore) Put(_ context.Context, prefix, _ string, body io.Reader) (string, error) {
	b, err := io.ReadAll(body)
	if err != nil {
		return "", err
	}
	s.mu.Lock()
	s.data = b
	s.mu.Unlock()
	return prefix + "/key", nil
}

func (s *fakeStore) Get(_ context.Context, _ string) (storage.Object, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return storage.Object{Body: io.NopCloser(bytes.NewReader(s.data)), Size: int64(len(s.data))}, nil
}

func (s *fakeStore) Delete(_ context.Context, _ string) error { return nil }

// fakeRedactor returns a fixed redaction result.
type fakeRedactor struct {
	text string
	err  error
}

func (r *fakeRedactor) Redact(_ context.Context, in pii.Input) (pii.Result, error) {
	if r.err != nil {
		return pii.Result{}, r.err
	}
	return pii.Result{
		RedactedText:           r.text,
		RedactedImage:          []byte("redacted"),
		RedactedImageMediaType: in.MediaType,
	}, nil
}

// fakeClassifier returns a fixed assessment or error.
type fakeClassifier struct {
	assessment Assessment
	err        error
}

func (c *fakeClassifier) Classify(_ context.Context, _, _ string) (Assessment, error) {
	return c.assessment, c.err
}

func strptr(s string) *string { return &s }

func int64ptr(v int64) *int64 { return &v }

func TestCreateUploadCheckRejectsNonReadyUpload(t *testing.T) {
	ready := strptr("redacted/key")

	cases := []struct {
		name   string
		upload Upload
	}{
		{"still processing", Upload{ID: 1, OwnerUserID: 5, Status: UploadStatusProcessing, RedactedStorageKey: ready}},
		{"uploaded", Upload{ID: 1, OwnerUserID: 5, Status: UploadStatusUploaded, RedactedStorageKey: ready}},
		{"failed", Upload{ID: 1, OwnerUserID: 5, Status: UploadStatusFailed, RedactedStorageKey: ready}},
		{"ready but no redacted key", Upload{ID: 1, OwnerUserID: 5, Status: UploadStatusReady}},
		{"ready but empty redacted key", Upload{ID: 1, OwnerUserID: 5, Status: UploadStatusReady, RedactedStorageKey: strptr("")}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			repo := &fakeRepo{upload: tc.upload}
			svc := NewService(repo, nil, nil, nil, nil)

			_, err := svc.CreateUploadCheck(context.Background(), CreateUploadInput{OwnerUserID: 5, UploadID: 1})
			if !errors.Is(err, ErrUploadNotReady) {
				t.Fatalf("expected ErrUploadNotReady, got %v", err)
			}
			if repo.createCheckParams != nil {
				t.Fatal("expected no check to be created for a non-ready upload")
			}
		})
	}
}

func TestCreateUploadCheckStartsProcessingCheckForReadyUpload(t *testing.T) {
	repo := &fakeRepo{
		upload: Upload{ID: 11, OwnerUserID: 5, Status: UploadStatusReady, RedactedStorageKey: strptr("redacted/key")},
	}
	svc := NewService(repo, nil, nil, nil, nil)

	res, err := svc.CreateUploadCheck(context.Background(), CreateUploadInput{OwnerUserID: 5, UploadID: 11, Locale: "en-SG"})
	if err != nil {
		t.Fatalf("CreateUploadCheck: %v", err)
	}
	if res.Check.Status != StatusProcessing {
		t.Fatalf("expected a processing check, got %q", res.Check.Status)
	}
	if repo.linkedUpload != 11 {
		t.Fatalf("expected upload 11 to be linked, got %d", repo.linkedUpload)
	}
}

func TestProcessClassifyCheckNoTextCompletesWithoutVerdict(t *testing.T) {
	cases := []struct {
		name string
		text *string
	}{
		{"nil text", nil},
		{"whitespace text", strptr("   \n\t ")},
		{"empty text", strptr("")},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			repo := &fakeRepo{upload: Upload{ID: 3, CheckID: int64ptr(9), ExtractedText: tc.text}}
			svc := NewService(repo, nil, nil, nil, nil)

			if err := svc.ProcessClassifyCheck(context.Background(), 9, 3); err != nil {
				t.Fatalf("ProcessClassifyCheck: %v", err)
			}
			if !repo.completeCalled {
				t.Fatal("expected the check to be completed")
			}
			if repo.completedCheck != 9 {
				t.Fatalf("completed the wrong check: %d", repo.completedCheck)
			}
			if repo.completedText != nil || repo.completedAssess != nil {
				t.Fatalf("expected no verdict/assessment, got text=%v assess=%v", repo.completedText, repo.completedAssess)
			}
			if repo.failCalled {
				t.Fatal("check must not fail merely because there was no text")
			}
		})
	}
}

func TestProcessClassifyCheckPersistsAssessment(t *testing.T) {
	assess := Assessment{Verdict: VerdictSuspicious, Uncertainty: "low"}
	repo := &fakeRepo{
		upload: Upload{ID: 3, CheckID: int64ptr(9), ExtractedText: strptr("Send your OTP")},
		check:  Check{ID: 9, Locale: "en-SG"},
	}
	svc := NewService(repo, nil, nil, nil, &fakeClassifier{assessment: assess})

	if err := svc.ProcessClassifyCheck(context.Background(), 9, 3); err != nil {
		t.Fatalf("ProcessClassifyCheck: %v", err)
	}
	if !repo.completeCalled || repo.failCalled {
		t.Fatalf("expected completion only, got complete=%v fail=%v", repo.completeCalled, repo.failCalled)
	}
	if repo.completedAssess == nil || repo.completedAssess.Verdict != VerdictSuspicious {
		t.Fatalf("assessment not persisted: %+v", repo.completedAssess)
	}
}

func TestProcessClassifyCheckFailsOnClassifierError(t *testing.T) {
	repo := &fakeRepo{
		upload: Upload{ID: 3, CheckID: int64ptr(9), ExtractedText: strptr("Send your OTP")},
		check:  Check{ID: 9, Locale: "en-SG"},
	}
	svc := NewService(repo, nil, nil, nil, &fakeClassifier{err: errors.New("clef down")})

	if err := svc.ProcessClassifyCheck(context.Background(), 9, 3); err == nil {
		t.Fatal("expected an error when classification fails")
	}
	if !repo.failCalled || repo.failedCheck != 9 {
		t.Fatalf("expected check 9 to be failed, got fail=%v check=%d", repo.failCalled, repo.failedCheck)
	}
	if repo.completeCalled {
		t.Fatal("check must not be completed on classifier failure")
	}
}

func TestCreateUploadAndRedactReturnsProcessingUpload(t *testing.T) {
	repo := &fakeRepo{}
	store := &fakeStore{}
	svc := NewService(repo, nil, store, &fakeRedactor{text: "cleaned"}, &fakeClassifier{})
	svc.processDelay = 0 // do not wait inside the background worker

	u, err := svc.CreateUploadAndRedact(context.Background(), CreateUploadBlobInput{
		OwnerUserID: 5,
		MediaType:   MediaTypePNG,
		Body:        bytes.NewReader([]byte("raw image bytes")),
	}, "en-SG")
	if err != nil {
		t.Fatalf("CreateUploadAndRedact: %v", err)
	}
	if u.Status != UploadStatusProcessing {
		t.Fatalf("expected a processing upload, got %q", u.Status)
	}
	if repo.markedProcessing != u.ID {
		t.Fatalf("expected upload %d marked processing, got %d", u.ID, repo.markedProcessing)
	}
	if repo.createdUpload == nil {
		t.Fatal("expected an upload to be created")
	}
	if repo.createdUpload.StorageKey == "" {
		t.Fatal("expected a storage key to be assigned")
	}
}
