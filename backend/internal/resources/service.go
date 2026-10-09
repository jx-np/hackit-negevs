package resources

import (
	"context"
	"strings"
	"time"
)

// Service holds resources/guidance business logic. It is transport-agnostic.
type Service struct {
	repo Repository
}

// NewService constructs a resources Service.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// ListGuidance returns active guidance for a scenario, translated to the
// requested locale with a fallback to DefaultLocale.
func (s *Service) ListGuidance(ctx context.Context, scenario, locale string) ([]Guidance, error) {
	return s.repo.ListGuidance(ctx, strings.TrimSpace(scenario), normalizeLocale(locale), DefaultLocale)
}

// ListResources returns active resources filtered by country (default SG) and
// optionally by scenario, translated to the requested locale with fallback.
func (s *Service) ListResources(ctx context.Context, country, scenario, locale string) ([]Resource, error) {
	return s.repo.ListResources(ctx, normalizeCountry(country), strings.TrimSpace(scenario), normalizeLocale(locale), DefaultLocale)
}

// CreateResourceInput carries an admin resource-create request.
type CreateResourceInput struct {
	Slug                string
	CountryCode         string
	URL                 *string
	ContactInstructions *string
	OwnerName           string
	VerifiedAt          time.Time
	VerifiedAtSet       bool
	Translations        []Translation
}

// CreateResource validates and persists a new catalog resource. It enforces the
// resources CHECK (url or contact_instructions) and requires at least one valid
// translation.
func (s *Service) CreateResource(ctx context.Context, in CreateResourceInput) (Resource, error) {
	slug := strings.TrimSpace(in.Slug)
	if slug == "" {
		return Resource{}, ErrSlugRequired
	}
	owner := strings.TrimSpace(in.OwnerName)
	if owner == "" {
		return Resource{}, ErrOwnerRequired
	}
	url := trimOptional(in.URL)
	contact := trimOptional(in.ContactInstructions)
	if url == nil && contact == nil {
		return Resource{}, ErrContactRequired
	}
	if !in.VerifiedAtSet || in.VerifiedAt.IsZero() {
		return Resource{}, ErrVerifiedAtRequired
	}
	translations, err := cleanTranslations(in.Translations)
	if err != nil {
		return Resource{}, err
	}
	if len(translations) == 0 {
		return Resource{}, ErrTranslationsRequired
	}

	id, err := s.repo.CreateResource(ctx, CreateResourceParams{
		Slug:                slug,
		CountryCode:         normalizeCountry(in.CountryCode),
		URL:                 url,
		ContactInstructions: contact,
		OwnerName:           owner,
		VerifiedAt:          in.VerifiedAt.UTC(),
		Translations:        translations,
	})
	if err != nil {
		return Resource{}, err
	}
	return s.repo.GetResource(ctx, id, DefaultLocale, DefaultLocale)
}

// UpdateResourceInput carries an admin resource-edit request. Nil pointers leave
// a field unchanged; Translations, when present, are upserted.
type UpdateResourceInput struct {
	ID                  int64
	CountryCode         *string
	URL                 *string
	ContactInstructions *string
	OwnerName           *string
	VerifiedAt          *time.Time
	Translations        []Translation
}

// UpdateResource applies mutable fields and upserts translations.
func (s *Service) UpdateResource(ctx context.Context, in UpdateResourceInput) (Resource, error) {
	params := UpdateResourceParams{}

	if in.CountryCode != nil {
		cc := normalizeCountry(*in.CountryCode)
		params.CountryCode = &cc
	}
	// URL and contact_instructions are updated to their provided values; a
	// provided empty string is normalized to NULL. The resources CHECK is
	// enforced by the database on the resulting row.
	if in.URL != nil {
		params.URL = trimOptionalAllowNil(*in.URL)
	}
	if in.ContactInstructions != nil {
		params.ContactInstructions = trimOptionalAllowNil(*in.ContactInstructions)
	}
	if in.OwnerName != nil {
		owner := strings.TrimSpace(*in.OwnerName)
		if owner == "" {
			return Resource{}, ErrOwnerRequired
		}
		params.OwnerName = &owner
	}
	if in.VerifiedAt != nil {
		v := in.VerifiedAt.UTC()
		params.VerifiedAt = &v
	}

	translations, err := cleanTranslations(in.Translations)
	if err != nil {
		return Resource{}, err
	}
	params.Translations = translations

	if err := s.repo.UpdateResource(ctx, in.ID, params); err != nil {
		return Resource{}, err
	}
	return s.repo.GetResource(ctx, in.ID, DefaultLocale, DefaultLocale)
}

// ArchiveResource sets a resource inactive.
func (s *Service) ArchiveResource(ctx context.Context, id int64) error {
	return s.repo.ArchiveResource(ctx, id)
}

// --- helpers ---

// cleanTranslations trims and validates a translation set. Each translation
// must have a non-empty locale and name; description is normalized to nil when
// blank.
func cleanTranslations(in []Translation) ([]Translation, error) {
	if len(in) == 0 {
		return nil, nil
	}
	out := make([]Translation, 0, len(in))
	for _, t := range in {
		locale := strings.TrimSpace(t.Locale)
		name := strings.TrimSpace(t.Name)
		if locale == "" || name == "" {
			return nil, ErrInvalidTranslation
		}
		out = append(out, Translation{
			Locale:      locale,
			Name:        name,
			Description: trimOptional(t.Description),
		})
	}
	return out, nil
}

// trimOptional trims a pointer string, returning nil when nil or blank.
func trimOptional(s *string) *string {
	if s == nil {
		return nil
	}
	t := strings.TrimSpace(*s)
	if t == "" {
		return nil
	}
	return &t
}

// trimOptionalAllowNil trims a value string, returning nil when blank. Used for
// PATCH where an explicit empty string means "clear this column".
func trimOptionalAllowNil(s string) *string {
	t := strings.TrimSpace(s)
	if t == "" {
		return nil
	}
	return &t
}

func normalizeLocale(locale string) string {
	l := strings.TrimSpace(locale)
	if l == "" {
		return DefaultLocale
	}
	return l
}

func normalizeCountry(country string) string {
	c := strings.ToUpper(strings.TrimSpace(country))
	if c == "" {
		return DefaultCountry
	}
	return c
}
