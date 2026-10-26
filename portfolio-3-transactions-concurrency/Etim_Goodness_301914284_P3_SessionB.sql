-- Session B: document the completed competing reversal attempt.
-- Start only after A inserts its reversal and log without committing.
-- Do not run this whole file at once.

SET application_name = 'p3_session_b';

BEGIN ISOLATION LEVEL READ COMMITTED;

SHOW transaction_isolation;

-- Expected: 0, because A's reversal is not committed.
SELECT COUNT(*) AS visible_reversals
FROM public."transaction"
WHERE original_transaction_id = (
    SELECT transaction_id
    FROM public."transaction"
    WHERE reference = 'DEMO-T002'
);

-- This INSERT waits for A to finish.
INSERT INTO public."transaction"
    (reference, type, amount, occurred_at, status,
     debit_account_id, original_transaction_id, processed_by)
SELECT
    'P3-REV-B', 'reversal', t.amount,
    TIMESTAMPTZ '2026-10-03 14:01:00+01', 'completed',
    t.credit_account_id, t.transaction_id, s.staff_id
FROM public."transaction" AS t
CROSS JOIN public.staff AS s
WHERE t.reference = 'DEMO-T002'
  AND t.status = 'completed'
  AND s.staff_number = 'DEMO-S002'
  AND s.role = 'reversal officer';

-- STOP while waiting. Switch to A for the lock check and COMMIT.
-- After A commits, expect a duplicate-key error naming:
-- transaction_original_transaction_id_key

-- Run only after the expected error appears.
ROLLBACK;

-- Expected: one reversal, P3-REV-A, for 5000.00.
SELECT original.reference AS original_reference,
       r.reference AS reversal_reference,
       r.amount, r.status,
       a.account_number AS debited_account
FROM public."transaction" AS r
JOIN public."transaction" AS original
    ON original.transaction_id = r.original_transaction_id
JOIN public.account AS a
    ON a.account_id = r.debit_account_id
WHERE original.reference = 'DEMO-T002';

-- Expected: 0.
SELECT COUNT(*) AS rejected_attempt_records
FROM public."transaction"
WHERE reference = 'P3-REV-B';

-- Capture the final-outcome screenshot.
-- Both transactions are now finished.