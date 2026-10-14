package search

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// SyntheticOrg names the organization that owns generated listings.
const SyntheticOrg = "Synthetic search data"

// Synthetic makes sure at least n published synthetic listings exist (load
// tests and the M3 performance acceptance). Locations are random points
// inside the smallest administrative units; attributes follow the catalog.
// It never runs against production data (terractl refuses outside dev/test).
func Synthetic(ctx context.Context, pool *pgxpool.Pool, n int) (int, error) {
	var have int
	err := pool.QueryRow(ctx, `SELECT count(*) FROM listing_search s JOIN organizations o ON o.id = s.org_id
		WHERE o.name = $1 AND o.kind = 'company'`, SyntheticOrg).Scan(&have)
	if err != nil || have >= n {
		return 0, err
	}
	missing := n - have
	err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var orgID, unitID string
		err := tx.QueryRow(ctx, `SELECT o.id, u.id FROM organizations o JOIN units u ON u.org_id = o.id
			WHERE o.name = $1 AND o.kind = 'company' LIMIT 1`, SyntheticOrg).Scan(&orgID, &unitID)
		if err == pgx.ErrNoRows {
			if err := tx.QueryRow(ctx, `INSERT INTO organizations (kind, name) VALUES ('company', $1) RETURNING id`, SyntheticOrg).Scan(&orgID); err != nil {
				return err
			}
			var addrID, propID string
			if err := tx.QueryRow(ctx, `INSERT INTO addresses (org_id, house_number, city, postal_code, location, label)
				VALUES ($1, '1', 'Praha', '11000', ST_SetSRID(ST_MakePoint(14.42, 50.08), 4326)::geography, 'Synthetic')
				RETURNING id`, orgID).Scan(&addrID); err != nil {
				return err
			}
			if err := tx.QueryRow(ctx, `INSERT INTO properties (org_id, address_id, kind, name) VALUES ($1, $2, 'other', 'Synthetic')
				RETURNING id`, orgID, addrID).Scan(&propID); err != nil {
				return err
			}
			if err := tx.QueryRow(ctx, `INSERT INTO units (org_id, property_id, kind, label) VALUES ($1, $2, 'apartment', 'Synthetic')
				RETURNING id`, orgID, propID).Scan(&unitID); err != nil {
				return err
			}
		} else if err != nil {
			return err
		}
		// Listings of an earlier interrupted run without an index row.
		if _, err := tx.Exec(ctx, `DELETE FROM listings l WHERE l.org_id = $1
			AND NOT EXISTS (SELECT 1 FROM listing_search s WHERE s.listing_id = l.id)`, orgID); err != nil {
			return err
		}
		_, err = tx.Exec(ctx, syntheticSQL, orgID, unitID, missing)
		return err
	})
	if err != nil {
		return 0, fmt.Errorf("synthetic listings: %w", err)
	}
	if _, err := pool.Exec(ctx, "REFRESH MATERIALIZED VIEW listing_aggregates"); err != nil {
		return missing, err
	}
	_, err = pool.Exec(ctx, "ANALYZE listing_search")
	return missing, err
}

const syntheticSQL = `
WITH units AS (SELECT array_agg(id) AS ids FROM admin_units WHERE level = (SELECT max(level) FROM admin_units)),
ls AS (
  INSERT INTO listings (org_id, unit_id, status, title, description, currency, published_version, published_at)
  SELECT $1, $2, 'published', '{}', '{}', 'CZK', 1, now() - (random() * interval '60 days')
  FROM generate_series(1, $3)
  RETURNING id, published_at
),
rows AS (
  SELECT ls.id, ls.published_at, r.k, r.lay, r.area, r.rent, au.path, au.geom, au.name,
    jsonb_strip_nulls(jsonb_build_object(
      'balcony', CASE WHEN random() < 0.45 THEN true END,
      'elevator', CASE WHEN random() < 0.55 THEN true END,
      'cellar', CASE WHEN random() < 0.4 THEN true END,
      'washing_machine', CASE WHEN random() < 0.6 THEN true END,
      'air_conditioning', CASE WHEN random() < 0.1 THEN true END,
      'furnished', (ARRAY['no','partly','full'])[1 + floor(random() * 3)::int],
      'building_type', (ARRAY['brick','panel','mixed'])[1 + floor(random() * 3)::int],
      'parking', (ARRAY['none','street','spot','garage'])[1 + floor(random() * 4)::int],
      'heating', (ARRAY['district','gas','electric','heat_pump'])[1 + floor(random() * 4)::int],
      'pets', CASE WHEN random() < 0.3 THEN '["dogs","cats"]'::jsonb WHEN random() < 0.5 THEN '["cats"]'::jsonb END,
      'transport', CASE WHEN random() < 0.5 THEN '["metro","tram"]'::jsonb ELSE '["bus"]'::jsonb END,
      'floor', floor(random() * 8)::int,
      'floor_area', r.area,
      'layout', r.lay)) AS attrs
  FROM ls
  CROSS JOIN LATERAL (SELECT
    CASE WHEN random() < 0.8 THEN 'apartment' WHEN random() < 0.7 THEN 'room' ELSE 'house' END AS k,
    (ARRAY['1+kk','1+1','2+kk','2+1','3+kk','3+1','4+kk'])[1 + floor(random() * 7)::int] AS lay,
    round((18 + random() * 110)::numeric, 1) AS area,
    (round((7000 + random() * 38000)::numeric, -2) * 100)::bigint AS rent,
    (SELECT ids[1 + floor(random() * array_length(ids, 1))::int] FROM units WHERE ls.id IS NOT NULL) AS unit_id) r
  JOIN admin_units au ON au.id = r.unit_id
)
INSERT INTO listing_search (listing_id, org_id, version, unit_kind, layout, rent_amount, currency, floor_area, attributes,
  title, location, admin_path, city, city_part, tsv, published_at)
SELECT id, $1, 1, k, CASE WHEN k = 'room' THEN NULL ELSE lay END, rent, 'CZK', area,
  CASE WHEN k = 'room' THEN attrs - 'layout' ELSE attrs END,
  jsonb_build_object('cs', CASE k WHEN 'room' THEN 'Pokoj' WHEN 'house' THEN 'Dům ' || lay ELSE 'Byt ' || lay END || ', ' || name, 'en', ''),
  (ST_Dump(ST_GeneratePoints(geom, 1))).geom::geography, path, 'Praha', name,
  to_tsvector('simple', lower(unaccent(CASE k WHEN 'room' THEN 'pokoj room' WHEN 'house' THEN 'dum house' ELSE 'byt flat' END || ' ' || coalesce(lay, '') || ' ' || name))),
  published_at
FROM rows`
