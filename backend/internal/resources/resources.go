// Package resources implements the help/taxonomy and resource-catalog domain:
// public reads of guidance (situation-specific plain-language next steps) and
// the vetted official resource catalog, plus admin-only catalog writes.
//
// Guidance and resources are translated per locale with a fallback to the
// system default locale. URLs and contact instructions are returned exactly as
// stored — the API never fabricates official contact details. As elsewhere,
// bigint ids are serialized as strings and timestamps are UTC RFC3339.
package resources

import (
	"errors"
	"strconv"
	"time"
)

// DefaultLocale is used when a requested locale has no translation.
const DefaultLocale = "en-SG"

// DefaultCountry is the default country_code filter for the catalog.
const DefaultCountry = "SG"

// Guidance urgency values. Mirrors the guidance.urgency CHECK constraint.
const (
	UrgencyNormal    = "normal"
	UrgencyUrgent    = "urgent"
	UrgencyEmergency = "emergency"
)

// Domain errors surfaced by the service layer and mapped to HTTP statuses by
// the handler.
var (
	// ErrResourceNotFound is returned when a resource lookup yields no row.
	ErrResourceNotFound = errors.New("resources: resource not found")
	// ErrSlugRequired is returned when a resource slug is empty.
	ErrSlugRequired = errors.New("resources: slug is required")
	// ErrOwnerRequired is returned when a resource owner_name is empty.
	ErrOwnerRequired = errors.New("resources: owner_name is required")
	// ErrContactRequired is returned when neither url nor contact_instructions
	// is provided (violating the resources CHECK constraint).
	ErrContactRequired = errors.New("resources: url or contact_instructions is required")
	// ErrVerifiedAtRequired is returned when verified_at is missing/unparseable.
	ErrVerifiedAtRequired = errors.New("resources: verified_at is required")
	// ErrTranslationsRequired is returned when a resource is created without at
	// least one translation.
	ErrTranslationsRequired = errors.New("resources: at least one translation is required")
	// ErrInvalidTranslation is returned when a translation has an empty locale or
	// name.
	ErrInvalidTranslation = errors.New("resources: translation locale and name are required")
	// ErrSlugTaken is returned when creating a resource with a duplicate slug.
	ErrSlugTaken = errors.New("resources: slug already exists")
)

// Resource is the internal representation of a resources row plus its
// locale-resolved translation.
type Resource struct {
	ID                  int64
	Slug                string
	CountryCode         string
	URL                 *string
	ContactInstructions *string
	OwnerName           string
	VerifiedAt          time.Time
	Active              bool

	// Locale-resolved translation.
	Name        string
	Description *string
}

// Guidance is the internal representation of a guidance row plus its
// locale-resolved translation and linked resources.
type Guidance struct {
	ID        int64
	Scenario  string
	Urgency   string
	SortOrder int

	// Locale-resolved translation.
	Title string
	Body  string

	Resources []Resource
}

// Translation is a locale-specific name/description for a resource.
type Translation struct {
	Locale      string
	Name        string
	Description *string
}

// CreateResourceParams carries the fields to insert a resources row plus its
// translations.
type CreateResourceParams struct {
	Slug                string
	CountryCode         string
	URL                 *string
	ContactInstructions *string
	OwnerName           string
	VerifiedAt          time.Time
	Translations        []Translation
}

// UpdateResourceParams carries the mutable fields of a resource edit. Nil
// pointers leave the corresponding column unchanged. Translations, when
// non-empty, are upserted.
type UpdateResourceParams struct {
	CountryCode         *string
	URL                 *string
	ContactInstructions *string
	OwnerName           *string
	VerifiedAt          *time.Time
	Translations        []Translation
}

// encodeID serializes a bigint PK as an opaque string for JSON output.
func encodeID(id int64) string {
	return strconv.FormatInt(id, 10)
}

// decodeID parses an opaque string ID into a bigint. Returns false when the
// value is not a valid positive integer.
func decodeID(s string) (int64, bool) {
	id, err := strconv.ParseInt(s, 10, 64)
	if err != nil || id <= 0 {
		return 0, false
	}
	return id, true
}
