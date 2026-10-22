-- Portfolio 2: synthetic fintech history benchmark.
-- Setup runs once. Do not rerun against existing benchmark objects.
-- Portfolio 1 tables and records remain unchanged.

CREATE SCHEMA p2_benchmark;

-- Generate 100,000 synthetic deposits, one minute apart.
-- These are performance-test records, including dates beyond today.
-- CREATE TABLE AS does not copy Portfolio 1 keys or constraints.
CREATE TABLE p2_benchmark.transaction_history AS
SELECT
    g::BIGINT AS transaction_id,
    'BENCH-' || g AS reference,
    'deposit'::TEXT AS type,
    100.00::NUMERIC(18,2) AS amount,
    TIMESTAMPTZ '2026-10-01 09:00:00+01'
        + g * INTERVAL '1 minute' AS occurred_at,
    'completed'::TEXT AS status,
    a.account_id AS credit_account_id,
    s.staff_id AS processed_by
FROM generate_series(1, 100000) AS series(g)
CROSS JOIN public.account AS a
CROSS JOIN public.staff AS s
WHERE a.account_number = 'DEMO-A001'
  AND s.staff_number = 'DEMO-S001';

-- Refresh statistics and confirm 100,000 rows.
ANALYZE p2_benchmark.transaction_history;

SELECT COUNT(*) AS test_rows
FROM p2_benchmark.transaction_history;

-- Count deposits within a fixed hour. Expected result: 60.
SELECT COUNT(*) AS deposits_in_hour
FROM p2_benchmark.transaction_history
WHERE occurred_at >= TIMESTAMPTZ '2026-10-02 09:00:00+01'
  AND occurred_at <  TIMESTAMPTZ '2026-10-02 10:00:00+01';

-- BEFORE INDEX: run once for warm-up, then three measured runs.
-- Observed execution times: 12.164, 7.642, 7.526 ms.
-- Median: 7.642 ms. Scan: Seq Scan.
-- Third measured run: top-level shared buffer hits = 1344.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) AS deposits_in_hour
FROM p2_benchmark.transaction_history
WHERE occurred_at >= TIMESTAMPTZ '2026-10-02 09:00:00+01'
  AND occurred_at <  TIMESTAMPTZ '2026-10-02 10:00:00+01';

-- Add one B-tree index on the filtered date-and-time column.
CREATE INDEX transaction_history_occurred_at_idx
    ON p2_benchmark.transaction_history USING btree (occurred_at);

-- AFTER INDEX: run once for warm-up, then three measured runs.
-- Keep the query, data and PostgreSQL settings unchanged.
-- Observed execution times: 0.070, 0.072, 0.063 ms.
-- Median: 0.070 ms. Scan: Index Only Scan.
-- Third measured run: top-level shared buffer hits = 4.
-- Heap fetches: 0 in all three measured runs.
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) AS deposits_in_hour
FROM p2_benchmark.transaction_history
WHERE occurred_at >= TIMESTAMPTZ '2026-10-02 09:00:00+01'
  AND occurred_at <  TIMESTAMPTZ '2026-10-02 10:00:00+01';

-- Confirm the result remains 60 after indexing.
SELECT COUNT(*) AS deposits_in_hour
FROM p2_benchmark.transaction_history
WHERE occurred_at >= TIMESTAMPTZ '2026-10-02 09:00:00+01'
  AND occurred_at <  TIMESTAMPTZ '2026-10-02 10:00:00+01';