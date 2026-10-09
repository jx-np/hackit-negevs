package resources

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const uniqueViolationCode = "23505"

// isUniqueViolation reports whether err is a Postgres unique-constraint
// violation, used to translate a duplicate slug into ErrSlugTaken.
func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code == uniqueViolationCode
	}
	return false
}

// Repository is the persistence contract for the resources domain.
type Repository interface {
	// ListGuidance returns active guidance for a scenario ordered by sort_order,
	// with the translation resolved to locale (falling back to fallback), and
	// each guidance's linked active resources resolved to the same locale.
	ListGuidance(ctx context.Context, scenario, locale, fallback string) ([]Guidance, error)
	// ListResources returns active resources filtered by country and, when
	// scenario is non-empty, restricted to resources linked to that scenario's
	// guidance. Translations resolve to locale with fallback.
	ListResources(ctx context.Context, country, scenario, locale, fallback string) ([]Resource, error)

	// CreateResource inserts a resource and its translations in one transaction,
	// returning the new id. Returns ErrSlugTaken on a duplicate slug.
	CreateResource(ctx context.Context, p CreateResourceParams) (int64, error)
	// UpdateResource applies mutable fields and upserts translations. Returns
	// ErrResourceNotFound if the row is absent.
	UpdateResource(ctx context.Context, id int64, p UpdateResourceParams) error
	// ArchiveResource sets active=false. Returns ErrResourceNotFound if absent.
	ArchiveResource(ctx context.Context, id int64) error
	// GetResource returns a single resource with its translation resolved to
	// locale (fallback applied). Returns ErrResourceNotFound if absent.
	GetResource(ctx context.Context, id int64, locale, fallback string) (Resource, error)
}

// PostgresRepository is a pgx-backed Repository.
type PostgresRepository struct {
	pool *pgxpool.Pool
}

// NewPostgresRepository constructs a PostgresRepository.
func NewPostgresRepository(pool *pgxpool.Pool) *PostgresRepository {
	return &PostgresRepository{pool: pool}
}

// resourceTranslationJoinSQL resolves a resource's name/description to a
// requested locale ($locale) with a fallback locale ($fallback). It expects the
// resource table aliased as "res" and joins two translation rows, preferring
// the requested locale via COALESCE. The caller supplies $1=locale, $2=fallback.
const resourceSelectSQL = `
	SELECT
		res.id, res.slug, res.country_code, res.url, res.contact_instructions,
		res.owner_name, res.verified_at, res.active,
		COALESCE(tr.name, trf.name) AS name,
		COALESCE(tr.description, trf.description) AS description
	FROM resources res
	LEFT JOIN resource_translations tr ON tr.resource_id = res.id AND tr.locale = $1
	LEFT JOIN resource_translations trf ON trf.resource_id = res.id AND trf.locale = $2`

// scanResource scans a row produced by resourceSelectSQL.
func scanResource(row pgx.Row) (Resource, error) {
	var r Resource
	err := row.Scan(
		&r.ID, &r.Slug, &r.CountryCode, &r.URL, &r.ContactInstructions,
		&r.OwnerName, &r.VerifiedAt, &r.Active, &r.Name, &r.Description,
	)
	return r, err
}

// GetResource implements Repository.
func (r *PostgresRepository) GetResource(ctx context.Context, id int64, locale, fallback string) (Resource, error) {
	query := resourceSelectSQL + "\n\tWHERE res.id = $3"
	res, err := scanResource(r.pool.QueryRow(ctx, query, locale, fallback, id))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Resource{}, ErrResourceNotFound
		}
		return Resource{}, fmt.Errorf("resources: get resource: %w", err)
	}
	return res, nil
}

// ListGuidance implements Repository.
func (r *PostgresRepository) ListGuidance(ctx context.Context, scenario, locale, fallback string) ([]Guidance, error) {
	const q = `
		SELECT
			g.id, g.scenario, g.urgency, g.sort_order,
			COALESCE(gt.title, gtf.title) AS title,
			COALESCE(gt.body, gtf.body) AS body
		FROM guidance g
		LEFT JOIN guidance_translations gt ON gt.guidance_id = g.id AND gt.locale = $2
		LEFT JOIN guidance_translations gtf ON gtf.guidance_id = g.id AND gtf.locale = $3
		WHERE g.active = true AND g.scenario = $1
		ORDER BY g.sort_order ASC, g.id ASC`
	rows, err := r.pool.Query(ctx, q, scenario, locale, fallback)
	if err != nil {
		return nil, fmt.Errorf("resources: query guidance: %w", err)
	}
	defer rows.Close()

	var (
		out []Guidance
		ids []int64
	)
	for rows.Next() {
		var g Guidance
		var title, body *string
		if err := rows.Scan(&g.ID, &g.Scenario, &g.Urgency, &g.SortOrder, &title, &body); err != nil {
			return nil, fmt.Errorf("resources: scan guidance: %w", err)
		}
		if title != nil {
			g.Title = *title
		}
		if body != nil {
			g.Body = *body
		}
		out = append(out, g)
		ids = append(ids, g.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("resources: iterate guidance: %w", err)
	}
	if len(out) == 0 {
		return out, nil
	}

	byGuidance, err := r.resourcesForGuidance(ctx, ids, locale, fallback)
	if err != nil {
		return nil, err
	}
	for i := range out {
		out[i].Resources = byGuidance[out[i].ID]
	}
	return out, nil
}

// resourcesForGuidance fetches active resources linked to a set of guidance ids
// in a single query, resolves translations to locale/fallback, and groups them
// by guidance id (ordered by the link's sort_order).
func (r *PostgresRepository) resourcesForGuidance(ctx context.Context, guidanceIDs []int64, locale, fallback string) (map[int64][]Resource, error) {
	query := `
		SELECT
			gr.guidance_id,
			res.id, res.slug, res.country_code, res.url, res.contact_instructions,
			res.owner_name, res.verified_at, res.active,
			COALESCE(tr.name, trf.name) AS name,
			COALESCE(tr.description, trf.description) AS description
		FROM guidance_resources gr
		JOIN resources res ON res.id = gr.resource_id AND res.active = true
		LEFT JOIN resource_translations tr ON tr.resource_id = res.id AND tr.locale = $1
		LEFT JOIN resource_translations trf ON trf.resource_id = res.id AND trf.locale = $2
		WHERE gr.guidance_id = ANY($3)
		ORDER BY gr.guidance_id, gr.sort_order ASC, res.id ASC`
	rows, err := r.pool.Query(ctx, query, locale, fallback, guidanceIDs)
	if err != nil {
		return nil, fmt.Errorf("resources: query guidance resources: %w", err)
	}
	defer rows.Close()

	out := make(map[int64][]Resource)
	for rows.Next() {
		var (
			guidanceID int64
			res        Resource
		)
		if err := rows.Scan(
			&guidanceID,
			&res.ID, &res.Slug, &res.CountryCode, &res.URL, &res.ContactInstructions,
			&res.OwnerName, &res.VerifiedAt, &res.Active, &res.Name, &res.Description,
		); err != nil {
			return nil, fmt.Errorf("resources: scan guidance resource: %w", err)
		}
		out[guidanceID] = append(out[guidanceID], res)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("resources: iterate guidance resources: %w", err)
	}
	return out, nil
}

// ListResources implements Repository.
func (r *PostgresRepository) ListResources(ctx context.Context, country, scenario, locale, fallback string) ([]Resource, error) {
	// $1 locale, $2 fallback, $3 country, optional $4 scenario.
	query := resourceSelectSQL + "\n\tWHERE res.active = true AND res.country_code = $3"
	args := []any{locale, fallback, country}
	if scenario != "" {
		args = append(args, scenario)
		query += fmt.Sprintf(`
	AND EXISTS (
		SELECT 1 FROM guidance_resources gr
		JOIN guidance g ON g.id = gr.guidance_id
		WHERE gr.resource_id = res.id AND g.active = true AND g.scenario = $%d
	)`, len(args))
	}
	query += "\n\tORDER BY res.slug ASC"

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("resources: query resources: %w", err)
	}
	defer rows.Close()

	var out []Resource
	for rows.Next() {
		res, err := scanResource(rows)
		if err != nil {
			return nil, fmt.Errorf("resources: scan resource: %w", err)
		}
		out = append(out, res)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("resources: iterate resources: %w", err)
	}
	return out, nil
}

// CreateResource implements Repository.
func (r *PostgresRepository) CreateResource(ctx context.Context, p CreateResourceParams) (int64, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, fmt.Errorf("resources: begin create tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	const ins = `
		INSERT INTO resources (slug, country_code, url, contact_instructions, owner_name, verified_at, active)
		VALUES ($1, $2, $3, $4, $5, $6, true)
		RETURNING id`
	var id int64
	if err := tx.QueryRow(ctx, ins,
		p.Slug, p.CountryCode, p.URL, p.ContactInstructions, p.OwnerName, p.VerifiedAt,
	).Scan(&id); err != nil {
		if isUniqueViolation(err) {
			return 0, ErrSlugTaken
		}
		return 0, fmt.Errorf("resources: insert resource: %w", err)
	}

	if err := upsertTranslations(ctx, tx, id, p.Translations); err != nil {
		return 0, err
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, fmt.Errorf("resources: commit create tx: %w", err)
	}
	return id, nil
}

// UpdateResource implements Repository.
func (r *PostgresRepository) UpdateResource(ctx context.Context, id int64, p UpdateResourceParams) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("resources: begin update tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck // rollback is a no-op after commit

	var (
		sets []string
		args []any
	)
	if p.CountryCode != nil {
		args = append(args, *p.CountryCode)
		sets = append(sets, fmt.Sprintf("country_code = $%d", len(args)))
	}
	if p.URL != nil {
		args = append(args, *p.URL)
		sets = append(sets, fmt.Sprintf("url = $%d", len(args)))
	}
	if p.ContactInstructions != nil {
		args = append(args, *p.ContactInstructions)
		sets = append(sets, fmt.Sprintf("contact_instructions = $%d", len(args)))
	}
	if p.OwnerName != nil {
		args = append(args, *p.OwnerName)
		sets = append(sets, fmt.Sprintf("owner_name = $%d", len(args)))
	}
	if p.VerifiedAt != nil {
		args = append(args, *p.VerifiedAt)
		sets = append(sets, fmt.Sprintf("verified_at = $%d", len(args)))
	}

	if len(sets) > 0 {
		args = append(args, id)
		query := fmt.Sprintf("UPDATE resources SET %s WHERE id = $%d", joinComma(sets), len(args))
		ct, err := tx.Exec(ctx, query, args...)
		if err != nil {
			return fmt.Errorf("resources: update resource: %w", err)
		}
		if ct.RowsAffected() == 0 {
			return ErrResourceNotFound
		}
	} else {
		// No column changes: still verify the row exists before upserting.
		var exists bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM resources WHERE id = $1)`, id).Scan(&exists); err != nil {
			return fmt.Errorf("resources: check resource exists: %w", err)
		}
		if !exists {
			return ErrResourceNotFound
		}
	}

	if err := upsertTranslations(ctx, tx, id, p.Translations); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("resources: commit update tx: %w", err)
	}
	return nil
}

// upsertTranslations inserts or updates resource_translations rows inside tx.
func upsertTranslations(ctx context.Context, tx pgx.Tx, resourceID int64, translations []Translation) error {
	const q = `
		INSERT INTO resource_translations (resource_id, locale, name, description)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (resource_id, locale) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description`
	for _, t := range translations {
		if _, err := tx.Exec(ctx, q, resourceID, t.Locale, t.Name, t.Description); err != nil {
			return fmt.Errorf("resources: upsert translation: %w", err)
		}
	}
	return nil
}

// ArchiveResource implements Repository.
func (r *PostgresRepository) ArchiveResource(ctx context.Context, id int64) error {
	const q = `UPDATE resources SET active = false WHERE id = $1`
	ct, err := r.pool.Exec(ctx, q, id)
	if err != nil {
		return fmt.Errorf("resources: archive resource: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return ErrResourceNotFound
	}
	return nil
}

// joinComma joins parts with ", " (small helper to avoid importing strings just
// for one call site pattern mirrored from the reports repository).
func joinComma(parts []string) string {
	out := ""
	for i, p := range parts {
		if i > 0 {
			out += ", "
		}
		out += p
	}
	return out
}
