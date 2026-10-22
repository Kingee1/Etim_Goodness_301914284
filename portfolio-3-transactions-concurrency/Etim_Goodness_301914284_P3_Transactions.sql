-- Portfolio 3: commit and rollback demonstration.
-- Run once, starting with DEMO-T005 pending and no P3-ROLLBACK record.
-- Later reruns have different starting data.

-- Check starting records.
SELECT t.reference, t.type, t.amount, t.occurred_at, t.status,
       d.account_number AS debit_account,
       c.account_number AS credit_account
FROM public."transaction" AS t
LEFT JOIN public.account AS d ON d.account_id = t.debit_account_id
LEFT JOIN public.account AS c ON c.account_id = t.credit_account_id
WHERE t.reference IN ('DEMO-T005', 'DEMO-T006')
ORDER BY t.reference;

SELECT reference, type, amount, status
FROM public."transaction"
WHERE reference IN ('P3-COMMIT', 'P3-ROLLBACK');

-- Mark the pending transfer failed and save its log together.
BEGIN;

UPDATE public."transaction"
SET status = 'failed'
WHERE reference = 'DEMO-T005'
  AND status = 'pending'
RETURNING reference, status;

INSERT INTO public.transaction_log
    (transaction_id, logged_at, event, staff_id)
SELECT transaction_id,
       TIMESTAMPTZ '2026-10-03 09:00:00+01',
       'Pending transfer marked failed (Portfolio 3)',
       NULL
FROM public."transaction"
WHERE reference = 'DEMO-T005'
  AND status = 'failed';

COMMIT;

-- Repeating the guarded update affects zero rows.
UPDATE public."transaction"
SET status = 'failed'
WHERE reference = 'DEMO-T005'
  AND status = 'pending';

SELECT reference, status
FROM public."transaction"
WHERE reference = 'DEMO-T005';

-- Insert a valid pending deposit, then trigger a constraint error.
BEGIN;

INSERT INTO public."transaction"
    (reference, type, amount, occurred_at, status, credit_account_id)
VALUES (
    'P3-ROLLBACK', 'deposit', 100.00,
    '2026-10-03 10:00:00+01', 'pending',
    (SELECT account_id FROM public.account
     WHERE account_number = 'DEMO-A001')
);

-- Expected error: transaction_amount_positive.
UPDATE public."transaction"
SET amount = 0
WHERE reference = 'P3-ROLLBACK';

-- Undo the whole second transaction, including its valid insert.
ROLLBACK;

-- Expected: DEMO-T005 remains failed.
SELECT reference, status
FROM public."transaction"
WHERE reference = 'DEMO-T005';

-- Expected: one saved status-change log.
SELECT COUNT(*) AS saved_status_logs
FROM public.transaction_log AS l
JOIN public."transaction" AS t
    ON t.transaction_id = l.transaction_id
WHERE t.reference = 'DEMO-T005'
  AND l.event = 'Pending transfer marked failed (Portfolio 3)';

-- Expected: zero records from the rolled-back insert.
SELECT COUNT(*) AS rolled_back_records
FROM public."transaction"
WHERE reference = 'P3-ROLLBACK';

-- The guarded update prevents this specific repeated status change.
-- It does not enforce every transaction workflow or protect all updates.
-- Run interactively so ROLLBACK can follow the deliberate error.