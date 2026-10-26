-- Session A: document the completed two-session exercise.
-- Run interactively in A -> B -> A -> B order, not as one script.
-- Setup: DEMO-T002 is completed and has no reversal.
-- P3-REV-A and P3-REV-B must not already exist.

-- Check the original deposit and any existing reversals.
SELECT t.reference, t.type, t.amount, t.status,
       a.account_number AS credited_account,
       (SELECT COUNT(*)
        FROM public."transaction" AS r
        WHERE r.original_transaction_id = t.transaction_id) AS reversals
FROM public."transaction" AS t
JOIN public.account AS a ON a.account_id = t.credit_account_id
WHERE t.reference = 'DEMO-T002';

SELECT staff_number, role
FROM public.staff
WHERE staff_number = 'DEMO-S002';

SELECT reference, status
FROM public."transaction"
WHERE reference IN ('P3-REV-A', 'P3-REV-B');

SET application_name = 'p3_session_a';

BEGIN ISOLATION LEVEL READ COMMITTED;

SHOW transaction_isolation;

-- Insert the full reversal using existing identifiers.
INSERT INTO public."transaction"
    (reference, type, amount, occurred_at, status,
     debit_account_id, original_transaction_id, processed_by)
SELECT
    'P3-REV-A', 'reversal', t.amount,
    TIMESTAMPTZ '2026-10-03 14:00:00+01', 'completed',
    t.credit_account_id, t.transaction_id, s.staff_id
FROM public."transaction" AS t
CROSS JOIN public.staff AS s
WHERE t.reference = 'DEMO-T002'
  AND t.status = 'completed'
  AND s.staff_number = 'DEMO-S002'
  AND s.role = 'reversal officer';

-- Save the reversal and its log in the same transaction.
INSERT INTO public.transaction_log
    (transaction_id, logged_at, event, staff_id)
SELECT transaction_id, occurred_at,
       'Deposit reversed (Portfolio 3 Session A)', processed_by
FROM public."transaction"
WHERE reference = 'P3-REV-A';

-- STOP. Switch to B and run its commands until its INSERT waits.
-- Do not commit before B starts waiting.

-- Return to A and confirm B is blocked.
SELECT application_name, wait_event_type,
       pg_blocking_pids(pid) AS blocking_sessions
FROM pg_stat_activity
WHERE application_name = 'p3_session_b';

-- Expected: Lock and a nonempty blocking-session list.
-- Capture the waiting screenshot before continuing.

COMMIT;

-- STOP. Switch to B to inspect its error, roll back and check results.