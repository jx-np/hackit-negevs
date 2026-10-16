package classifier

import (
	"context"
	"testing"
)

func TestStubAlwaysReturnsPhishing(t *testing.T) {
	c := NewStub()
	res, err := c.Classify(context.Background(), "Your DBS account is locked, call now", "en-SG")
	if err != nil {
		t.Fatalf("Classify: unexpected error: %v", err)
	}
	if !res.Classified() {
		t.Fatal("Classified() = false, want true")
	}
	if res.Slug != DefaultSlug {
		t.Errorf("Slug = %q, want %q", res.Slug, DefaultSlug)
	}
	if res.Confidence != 1 {
		t.Errorf("Confidence = %v, want 1", res.Confidence)
	}
	if len(res.Tags) != 1 || res.Tags[0] != "phishing" {
		t.Errorf("Tags = %v, want %v", res.Tags, DefaultTags)
	}
}

func TestStubHonoursOverriddenSlug(t *testing.T) {
	c := &Stub{Slug: "impersonation", Confidence: 0.5, Tags: []string{"bank-impersonation"}}
	res, err := c.Classify(context.Background(), "", "zh-SG")
	if err != nil {
		t.Fatalf("Classify: unexpected error: %v", err)
	}
	if res.Slug != "impersonation" {
		t.Errorf("Slug = %q, want %q", res.Slug, "impersonation")
	}
	if res.Confidence != 0.5 {
		t.Errorf("Confidence = %v, want 0.5", res.Confidence)
	}
	if len(res.Tags) != 1 || res.Tags[0] != "bank-impersonation" {
		t.Errorf("Tags = %v, want [bank-impersonation]", res.Tags)
	}
}

func TestStubFallsBackToDefaultSlugWhenEmpty(t *testing.T) {
	c := &Stub{}
	res, err := c.Classify(context.Background(), "anything", "en-SG")
	if err != nil {
		t.Fatalf("Classify: unexpected error: %v", err)
	}
	if res.Slug != DefaultSlug {
		t.Errorf("Slug = %q, want %q", res.Slug, DefaultSlug)
	}
	if len(res.Tags) != 1 || res.Tags[0] != "phishing" {
		t.Errorf("Tags = %v, want %v", res.Tags, DefaultTags)
	}
}

func TestStubTagsAreCopied(t *testing.T) {
	c := NewStub()
	res, _ := c.Classify(context.Background(), "anything", "en-SG")
	res.Tags[0] = "mutated"
	if DefaultTags[0] != "phishing" {
		t.Errorf("DefaultTags mutated through returned slice: %v", DefaultTags)
	}
}

func TestResultClassified(t *testing.T) {
	if (Result{}).Classified() {
		t.Error("empty result reported as classified")
	}
	if !(Result{Slug: "phishing"}).Classified() {
		t.Error("result with slug reported as unclassified")
	}
}
