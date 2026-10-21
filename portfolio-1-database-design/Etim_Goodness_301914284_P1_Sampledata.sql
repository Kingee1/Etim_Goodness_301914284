-- Dates use Nigeria's UTC+01 offset.
BEGIN;

INSERT INTO public.customer (customer_number, full_name, email) VALUES
('DEMO-C001', 'Ada James', 'ada.james@example.com'),
('DEMO-C002', 'Ben Cole', 'ben.cole@example.com');

INSERT INTO public.account (account_number, customer_id, opened_at, currency) VALUES
('DEMO-A001', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C001'), '2026-10-01 09:00:00+01', 'NGN'),
('DEMO-A002', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C002'), '2026-10-01 09:00:00+01', 'NGN'),
('DEMO-A003', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C001'), '2026-10-01 09:00:00+01', 'NGN');

INSERT INTO public.staff (staff_number, full_name, role) VALUES
('DEMO-S001', 'Eno Cole', 'operations'),
('DEMO-S002', 'Lara James', 'reversal officer'),
('DEMO-S003', 'Tobi Green', 'auditor');

-- Deposits supply funds before withdrawals and transfers.
INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, credit_account_id, processed_by)
VALUES
('DEMO-T001', 'deposit', 10000.00, '2026-10-02 09:00:00+01', 'completed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'),
 (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001')),
('DEMO-T002', 'deposit', 5000.00, '2026-10-02 09:05:00+01', 'completed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'),
 (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, processed_by)
VALUES
('DEMO-T003', 'transfer', 2000.00, '2026-10-02 10:00:00+01', 'completed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'),
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'), NULL);

INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, debit_account_id, processed_by)
VALUES
('DEMO-T004', 'withdrawal', 500.00, '2026-10-02 11:00:00+01', 'completed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'),
 (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- Pending and failed records do not affect balances.
INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, debit_account_id, credit_account_id)
VALUES
('DEMO-T005', 'transfer', 100.00, '2026-10-02 12:00:00+01', 'pending',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'),
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002')),
('DEMO-T006', 'withdrawal', 20000.00, '2026-10-02 12:05:00+01', 'failed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL);

-- Reverse the completed withdrawal in full, using a separate record.
INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, credit_account_id,
 original_transaction_id, processed_by)
VALUES
('DEMO-T007', 'reversal', 500.00, '2026-10-02 13:00:00+01', 'completed',
 (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'),
 (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T004'),
 (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- Logs are inserted explicitly; the schema has no automatic log trigger.
INSERT INTO public.transaction_log (transaction_id, logged_at, event, staff_id)
SELECT transaction_id, occurred_at, 'Recorded as ' || status, processed_by
FROM public."transaction"
WHERE reference IN ('DEMO-T001', 'DEMO-T002', 'DEMO-T003', 'DEMO-T004',
                    'DEMO-T005', 'DEMO-T006', 'DEMO-T007');

COMMIT;

-- Expected counts: 2 customers, 3 accounts, 3 staff, 7 transactions, 7 logs.
-- Calculated balances: DEMO-A001 = 8000, DEMO-A002 = 7000, DEMO-A003 = 0.
-- The third account demonstrates an account with no transactions.
-- These inserts do not implement funds checks, locks or reversal approval.