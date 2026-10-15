-- M6b: portfolio across municipalities, groups, rules and lease risk.

-- ---------------------------------------------------------------------------
-- Where a lease is.

-- name: LeaseLocationFromListing :one
SELECT u.id AS unit_id, coalesce(a.admin_path::text, '')::text AS admin_path,
  ST_Y(a.location::geometry)::float8 AS lat, ST_X(a.location::geometry)::float8 AS lng
FROM listings li
JOIN units u ON u.id = li.unit_id
JOIN properties p ON p.id = u.property_id
JOIN addresses a ON a.id = p.address_id
WHERE li.id = $1;

-- name: LeaseLocationFromRuian :one
SELECT coalesce((SELECT u.path::text FROM admin_units u WHERE ST_Covers(u.geom, r.location::geometry)
    ORDER BY u.level DESC, ST_Area(u.geom) LIMIT 1), '')::text AS admin_path,
  ST_Y(r.location::geometry)::float8 AS lat, ST_X(r.location::geometry)::float8 AS lng
FROM ruian_places r WHERE r.id = $1;

-- name: MunicipalityInText :one
-- The municipality named in a free-text address ("Dejvická 12, Praha 6"):
-- the longest municipality name found as a whole word. Both sides are
-- reduced to words separated by single spaces, so names from the data are
-- compared literally (no regular expression built from data).
SELECT path::text AS admin_path, ST_Y(centroid)::float8 AS lat, ST_X(centroid)::float8 AS lng
FROM admin_units
WHERE level = 2 AND search ~ '[a-z0-9]'
  AND (' ' || regexp_replace(lower(unaccent(sqlc.arg(address)::text)), '[^a-z0-9]+', ' ', 'g') || ' ')
      LIKE ('% ' || btrim(regexp_replace(search, '[^a-z0-9]+', ' ', 'g')) || ' %')
ORDER BY length(search) DESC LIMIT 1;

-- name: SetLeaseLocation :exec
UPDATE leases SET unit_id = sqlc.narg(unit_id), admin_path = nullif(sqlc.arg(admin_path)::text, '')::ltree,
  lat = sqlc.narg(lat), lng = sqlc.narg(lng)
WHERE id = sqlc.arg(id);

-- name: SetLeaseTerms :exec
UPDATE leases SET terms = $2 WHERE id = $1;

-- ---------------------------------------------------------------------------
-- Groups.

-- name: ListPortfolioGroups :many
SELECT g.*,
  (SELECT count(*) FROM portfolio_group_items i WHERE i.group_id = g.id AND i.property_id IS NOT NULL)::int AS properties,
  (SELECT count(*) FROM portfolio_group_items i WHERE i.group_id = g.id AND i.lease_id IS NOT NULL)::int AS leases
FROM portfolio_groups g WHERE g.org_id = $1 ORDER BY g.name;

-- name: CreatePortfolioGroup :one
INSERT INTO portfolio_groups (org_id, name, color) VALUES ($1, $2, $3) RETURNING *;

-- name: UpdatePortfolioGroup :one
UPDATE portfolio_groups SET name = $3, color = $4 WHERE id = $1 AND org_id = $2 RETURNING *;

-- name: DeletePortfolioGroup :execrows
DELETE FROM portfolio_groups WHERE id = $1 AND org_id = $2;

-- name: ClearGroupItems :exec
DELETE FROM portfolio_group_items WHERE group_id = $1;

-- name: AddGroupProperty :exec
INSERT INTO portfolio_group_items (group_id, org_id, property_id)
SELECT g.id, g.org_id, p.id FROM portfolio_groups g JOIN properties p ON p.org_id = g.org_id
WHERE g.id = sqlc.arg(group_id) AND p.id = sqlc.arg(property_id)
ON CONFLICT DO NOTHING;

-- name: AddGroupLease :exec
INSERT INTO portfolio_group_items (group_id, org_id, lease_id)
SELECT g.id, g.org_id, l.id FROM portfolio_groups g JOIN leases l ON l.org_id = g.org_id
WHERE g.id = sqlc.arg(group_id) AND l.id = sqlc.arg(lease_id)
ON CONFLICT DO NOTHING;

-- name: GroupItems :many
SELECT group_id, property_id, lease_id FROM portfolio_group_items WHERE org_id = $1;

-- name: ListOrgProperties :many
SELECT p.id, p.name, a.label AS address FROM properties p JOIN addresses a ON a.id = p.address_id
WHERE p.org_id = $1 AND p.deleted_at IS NULL ORDER BY p.name;

-- name: LeaseGroupIDs :many
-- Groups of a lease: tagged directly or through its unit's property.
SELECT DISTINCT i.group_id FROM portfolio_group_items i
LEFT JOIN units u ON u.id = sqlc.narg(unit_id)
WHERE i.lease_id = sqlc.arg(lease_id) OR (i.property_id IS NOT NULL AND i.property_id = u.property_id);

-- ---------------------------------------------------------------------------
-- Rules.

-- name: ListPortfolioRules :many
SELECT r.id, r.org_id, r.scope, coalesce(r.admin_path::text, '')::text AS admin_path, r.group_id, r.rules, r.updated_at,
  coalesce(u.name, g.name, '')::text AS scope_name
FROM portfolio_rules r
LEFT JOIN admin_units u ON u.path = r.admin_path
LEFT JOIN portfolio_groups g ON g.id = r.group_id
WHERE r.org_id = $1 ORDER BY r.scope, scope_name;

-- name: UpsertMunicipalityRule :one
INSERT INTO portfolio_rules (org_id, scope, admin_path, rules)
VALUES (sqlc.arg(org_id), 'municipality', sqlc.arg(admin_path)::text::ltree, sqlc.arg(rules))
ON CONFLICT (org_id, admin_path) WHERE scope = 'municipality' DO UPDATE SET rules = EXCLUDED.rules
RETURNING id;

-- name: UpsertGroupRule :one
INSERT INTO portfolio_rules (org_id, scope, group_id, rules)
SELECT g.org_id, 'group', g.id, sqlc.arg(rules) FROM portfolio_groups g
WHERE g.id = sqlc.arg(group_id) AND g.org_id = sqlc.arg(org_id)
ON CONFLICT (org_id, group_id) WHERE scope = 'group' DO UPDATE SET rules = EXCLUDED.rules
RETURNING id;

-- name: DeletePortfolioRule :execrows
DELETE FROM portfolio_rules WHERE id = $1 AND org_id = $2;

-- name: RulesForLease :many
-- Candidate rules for a place and groups: municipality rules whose unit
-- contains the place, then group rules (applied in this order).
SELECT r.scope, r.rules FROM portfolio_rules r
WHERE r.org_id = sqlc.arg(org_id) AND (
  (r.scope = 'municipality' AND sqlc.arg(admin_path)::text <> '' AND sqlc.arg(admin_path)::text::ltree <@ r.admin_path)
  OR (r.scope = 'group' AND r.group_id = ANY(sqlc.arg(group_ids)::uuid[])))
ORDER BY CASE r.scope WHEN 'municipality' THEN 0 ELSE 1 END, nlevel(r.admin_path) NULLS LAST, r.updated_at;

-- name: ListMunicipalities :many
SELECT path::text AS path, name FROM admin_units WHERE level = 2 ORDER BY name;

-- ---------------------------------------------------------------------------
-- Risk settings and scores.

-- name: GetRiskSettings :one
SELECT weights FROM risk_settings WHERE org_id = $1;

-- name: UpsertRiskSettings :exec
INSERT INTO risk_settings (org_id, weights) VALUES ($1, $2)
ON CONFLICT (org_id) DO UPDATE SET weights = EXCLUDED.weights;

-- name: RiskPartyStats :many
-- Per tenant party: overdue amounts (rent, services, one-off items due
-- before the date: an item due today is not overdue until tomorrow), the
-- oldest unpaid due date and passport facts.
SELECT p.id AS party_id, p.role, p.user_id,
  coalesce(sum(s.amount - s.paid_amount) FILTER (WHERE o.kind <> 'deposit' AND o.due_on < sqlc.arg(as_of)::date AND o.status = 'open'), 0)::bigint AS overdue,
  coalesce(sum(s.amount - s.paid_amount) FILTER (WHERE o.kind = 'deposit' AND o.due_on < sqlc.arg(as_of)::date AND o.status = 'open'), 0)::bigint AS deposit_unpaid,
  coalesce(sum(s.paid_amount) FILTER (WHERE o.kind = 'deposit'), 0)::bigint AS deposit_paid,
  min(o.due_on) FILTER (WHERE o.kind <> 'deposit' AND o.due_on < sqlc.arg(as_of)::date AND s.paid_amount < s.amount AND o.status = 'open')::date AS oldest_unpaid,
  coalesce(u.verification_level, '')::text AS verification,
  (tp.income_uploaded_at IS NOT NULL)::boolean AS income_proof,
  coalesce(tp.isir_status, 'unchecked')::text AS isir_status
FROM lease_parties p
LEFT JOIN obligation_splits s ON s.party_id = p.id
LEFT JOIN payment_obligations o ON o.id = s.obligation_id
LEFT JOIN users u ON u.id = p.user_id
LEFT JOIN tenant_passports tp ON tp.user_id = p.user_id
WHERE p.lease_id = sqlc.arg(lease_id) AND p.role IN ('tenant', 'co_tenant', 'subtenant')
GROUP BY p.id, p.role, p.user_id, p.position, u.verification_level, tp.income_uploaded_at, tp.isir_status
ORDER BY p.position;

-- name: CountLeaseEventsSince :one
SELECT count(*)::int FROM lease_events WHERE lease_id = $1 AND kind = $2 AND created_at >= $3;

-- name: MarketStats :one
-- Local market from our own search data: median asking rent and the mean
-- age of listings still published in the municipality.
SELECT coalesce(percentile_cont(0.5) WITHIN GROUP (ORDER BY s.rent_amount), 0)::bigint AS median_rent,
  count(*)::int AS listings,
  coalesce(avg(EXTRACT(EPOCH FROM (now() - s.published_at)) / 86400), 0)::float8 AS avg_age_days
FROM listing_search s WHERE s.admin_path <@ sqlc.arg(path)::text::ltree AND s.currency = sqlc.arg(currency);

-- name: UpsertLeaseRisk :exec
INSERT INTO lease_risk (lease_id, org_id, score, band, factors, model_version, computed_at)
VALUES ($1, $2, $3, $4, $5, $6, now())
ON CONFLICT (lease_id) DO UPDATE SET score = EXCLUDED.score, band = EXCLUDED.band, factors = EXCLUDED.factors,
  model_version = EXCLUDED.model_version, computed_at = now();

-- name: UpsertLeaseRiskHistory :exec
INSERT INTO lease_risk_history (lease_id, org_id, period, score, band, monthly)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (lease_id, period) DO UPDATE SET score = EXCLUDED.score, band = EXCLUDED.band, monthly = EXCLUDED.monthly;

-- name: GetLeaseRisk :one
SELECT * FROM lease_risk WHERE lease_id = $1;

-- name: RiskLeaseIDs :many
-- Leases whose risk is tracked (system context, daily recompute).
SELECT id FROM leases WHERE state IN ('signed', 'active', 'notice_given') ORDER BY id;

-- name: ClearLeaseRisk :exec
DELETE FROM lease_risk WHERE lease_id = $1;

-- ---------------------------------------------------------------------------
-- Rent roll and dashboard.

-- name: RentRollLeases :many
SELECT l.id, l.code, l.state, l.template, l.property_address, l.unit_label, l.unit_id, l.listing_id,
  l.starts_on, l.ends_on, l.notice_on, l.rent_amount, l.services_amount, l.deposit_amount, l.due_day, l.currency,
  l.lat, l.lng, coalesce(l.admin_path::text, '')::text AS admin_path,
  coalesce(mu.path::text, '')::text AS municipality_path, coalesce(mu.name, '')::text AS municipality,
  coalesce(rg.path::text, '')::text AS region_path, coalesce(rg.name, '')::text AS region,
  coalesce((SELECT string_agg(p.name, ', ' ORDER BY p.position) FROM lease_parties p
    WHERE p.lease_id = l.id AND p.role IN ('tenant', 'co_tenant', 'subtenant')), '')::text AS tenant_names,
  coalesce((SELECT sum(e.amount) FROM ledger_entries e WHERE e.lease_id = l.id AND e.account = 'receivable'
    AND e.amount > 0 AND e.booked_on <= sqlc.arg(as_of)::date), 0)::bigint AS billed,
  coalesce(-(SELECT sum(e.amount) FROM ledger_entries e WHERE e.lease_id = l.id AND e.account = 'receivable'
    AND e.amount < 0 AND e.booked_on <= sqlc.arg(as_of)::date), 0)::bigint AS paid,
  coalesce((SELECT sum(s.paid_amount) FROM obligation_splits s JOIN payment_obligations o ON o.id = s.obligation_id
    WHERE o.lease_id = l.id AND o.kind = 'deposit'), 0)::bigint AS deposit_paid,
  coalesce((SELECT max(ev.created_at) FROM lease_events ev WHERE ev.lease_id = l.id AND ev.kind = 'payment_escalated'),
    'epoch'::timestamptz)::timestamptz AS last_escalation,
  coalesce(rk.score, -1)::int AS risk_score, coalesce(rk.band, '')::text AS risk_band,
  coalesce((SELECT array_agg(DISTINCT gi.group_id) FROM portfolio_group_items gi LEFT JOIN units gu ON gu.id = l.unit_id
    WHERE gi.lease_id = l.id OR (gi.property_id IS NOT NULL AND gi.property_id = gu.property_id)), '{}')::uuid[] AS group_ids
FROM leases l
LEFT JOIN admin_units mu ON nlevel(l.admin_path) >= 3 AND mu.path = subpath(l.admin_path, 0, 3)
LEFT JOIN admin_units rg ON nlevel(l.admin_path) >= 2 AND rg.path = subpath(l.admin_path, 0, 2)
LEFT JOIN lease_risk rk ON rk.lease_id = l.id
WHERE l.org_id = sqlc.arg(org_id) AND l.state IN ('signed', 'active', 'notice_given')
ORDER BY mu.name NULLS LAST, l.property_address, l.code;

-- name: RentRollVacantUnits :many
-- Units without a running lease (apartments split into rooms count by room).
SELECT u.id, u.kind, u.label, p.id AS property_id, p.name AS property_name, a.label AS address,
  ST_Y(a.location::geometry)::float8 AS lat, ST_X(a.location::geometry)::float8 AS lng,
  coalesce(a.admin_path::text, '')::text AS admin_path,
  coalesce(mu.path::text, '')::text AS municipality_path, coalesce(mu.name, '')::text AS municipality,
  coalesce(rg.path::text, '')::text AS region_path, coalesce(rg.name, '')::text AS region,
  coalesce((SELECT li.rent_amount FROM listings li WHERE li.unit_id = u.id AND li.deleted_at IS NULL
    ORDER BY li.updated_at DESC LIMIT 1), 0)::bigint AS asking_rent,
  coalesce((SELECT li.status FROM listings li WHERE li.unit_id = u.id AND li.deleted_at IS NULL
    ORDER BY li.updated_at DESC LIMIT 1), '')::text AS listing_status,
  coalesce((SELECT array_agg(DISTINCT gi.group_id) FROM portfolio_group_items gi WHERE gi.property_id = p.id), '{}')::uuid[] AS group_ids
FROM units u
JOIN properties p ON p.id = u.property_id AND p.deleted_at IS NULL
JOIN addresses a ON a.id = p.address_id
LEFT JOIN admin_units mu ON nlevel(a.admin_path) >= 3 AND mu.path = subpath(a.admin_path, 0, 3)
LEFT JOIN admin_units rg ON nlevel(a.admin_path) >= 2 AND rg.path = subpath(a.admin_path, 0, 2)
WHERE u.org_id = sqlc.arg(org_id) AND u.deleted_at IS NULL AND u.kind IN ('apartment', 'house', 'room', 'commercial')
  AND NOT EXISTS (SELECT 1 FROM units c WHERE c.parent_id = u.id AND c.deleted_at IS NULL)
  AND NOT EXISTS (SELECT 1 FROM leases l WHERE l.unit_id = u.id AND l.state IN ('signed', 'active', 'notice_given'))
ORDER BY mu.name NULLS LAST, a.label, u.label;

-- name: PortfolioMonthly :many
-- Expected (rent and services due) and received amounts per month and
-- municipality, for the trend and this month's income.
SELECT to_char(o.due_on, 'YYYY-MM')::text AS period,
  coalesce(CASE WHEN nlevel(l.admin_path) >= 3 THEN subpath(l.admin_path, 0, 3)::text END, '')::text AS municipality_path,
  sum(o.amount)::bigint AS expected,
  coalesce(sum((SELECT sum(s.paid_amount) FROM obligation_splits s WHERE s.obligation_id = o.id)), 0)::bigint AS received
FROM payment_obligations o JOIN leases l ON l.id = o.lease_id
WHERE l.org_id = sqlc.arg(org_id) AND o.kind IN ('rent', 'services') AND o.status <> 'cancelled'
  AND o.due_on >= sqlc.arg(from_day)::date AND o.due_on <= sqlc.arg(to_day)::date
GROUP BY 1, 2 ORDER BY 1, 2;

-- name: PortfolioRiskTrend :many
SELECT period, (sum(score::bigint * monthly) / nullif(sum(monthly), 0))::int AS weighted, count(*)::int AS leases
FROM lease_risk_history WHERE org_id = $1 AND period >= $2 GROUP BY period ORDER BY period;

-- name: InsertPortfolioSummary :one
INSERT INTO portfolio_summaries (org_id, body, model, input, created_by) VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: LatestPortfolioSummary :one
SELECT * FROM portfolio_summaries WHERE org_id = $1 ORDER BY created_at DESC LIMIT 1;

-- name: StaleRiskLeaseIDs :many
-- Leases whose score is missing, older than a new event, a day old or from
-- an older model (the recompute job runs every minute).
SELECT l.id FROM leases l LEFT JOIN lease_risk r ON r.lease_id = l.id
WHERE l.state IN ('signed', 'active', 'notice_given') AND (r.lease_id IS NULL OR r.model_version <> sqlc.arg(model_version)
  OR r.computed_at < now() - interval '1 day'
  OR EXISTS (SELECT 1 FROM lease_events e WHERE e.lease_id = l.id AND e.created_at > r.computed_at))
ORDER BY l.id LIMIT 500;
