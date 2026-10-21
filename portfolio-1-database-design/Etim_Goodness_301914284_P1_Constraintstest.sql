-- Run after SampleData.sql, in the same database.
-- Run each numbered INSERT separately with autocommit on.
-- Do not wrap these tests in BEGIN/COMMIT.
-- If using psql to run the whole file, ON_ERROR_STOP must be off.
-- Every INSERT below is expected to fail; continue after each error.
-- Missing foreign keys use MAX(id) + 1, not guessed existing IDs.
-- Use this tutorial database without concurrent writers.
-- Failed inserts can consume identity numbers; gaps are normal.

-- 1. Expected: NOT NULL violation on full_name.
INSERT INTO public.customer (customer_number, full_name, email)
VALUES ('TEST-C001', NULL, 'mina.grey@example.com');

-- 2. Expected: UNIQUE violation on customer_number.
INSERT INTO public.customer (customer_number, full_name, email)
VALUES ('DEMO-C001', 'Mina Grey', 'mina.grey@example.com');

-- 3. Expected: UNIQUE violation on email.
INSERT INTO public.customer (customer_number, full_name, email)
VALUES ('TEST-C001', 'Mina Grey', 'ada.james@example.com');

-- 4. Expected: CHECK customer_email_lowercase.
INSERT INTO public.customer (customer_number, full_name, email)
VALUES ('TEST-C001', 'Mina Grey', 'Mina.Grey@example.com');

-- 5. Expected: NOT NULL violation on opened_at.
INSERT INTO public.account (account_number, customer_id, opened_at, currency)
VALUES ('TEST-A001', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C001'), NULL, 'NGN');

-- 6. Expected: UNIQUE violation on account_number.
INSERT INTO public.account (account_number, customer_id, opened_at, currency)
VALUES ('DEMO-A001', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C001'), '2026-10-01 09:00:00+01', 'NGN');

-- 7. Expected: FOREIGN KEY violation on customer_id.
INSERT INTO public.account (account_number, customer_id, opened_at, currency)
VALUES ('TEST-A001', (SELECT COALESCE(MAX(customer_id), 0) + 1 FROM public.customer), '2026-10-01 09:00:00+01', 'NGN');

-- 8. Expected: CHECK account_currency_ngn.
INSERT INTO public.account (account_number, customer_id, opened_at, currency)
VALUES ('TEST-A001', (SELECT customer_id FROM public.customer WHERE customer_number = 'DEMO-C001'), '2026-10-01 09:00:00+01', 'USD');

-- 9. Expected: NOT NULL violation on full_name.
INSERT INTO public.staff (staff_number, full_name, role)
VALUES ('TEST-S001', NULL, 'operations');

-- 10. Expected: UNIQUE violation on staff_number.
INSERT INTO public.staff (staff_number, full_name, role)
VALUES ('DEMO-S001', 'Mina Grey', 'operations');

-- 11. Expected: CHECK staff_role_valid.
INSERT INTO public.staff (staff_number, full_name, role)
VALUES ('TEST-S001', 'Mina Grey', 'manager');

-- 12. Expected: NOT NULL violation on occurred_at.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T012', 'deposit', 100.00, NULL, 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 13. Expected: UNIQUE violation on reference.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('DEMO-T001', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 14. Expected: CHECK transaction_amount_positive (zero).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T014', 'deposit', 0, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 15. Expected: CHECK transaction_amount_positive (negative amount).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T015', 'deposit', -10.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 16. Expected: CHECK transaction_amount_positive (NaN).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T016', 'deposit', 'NaN'::NUMERIC, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 17. Expected: CHECK transaction_status_valid.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T017', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'cancelled', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 18. Expected: FOREIGN KEY violation on credit_account_id.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T018', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT COALESCE(MAX(account_id), 0) + 1 FROM public.account), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 19. Expected: FOREIGN KEY violation on debit_account_id.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T019', 'withdrawal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT COALESCE(MAX(account_id), 0) + 1 FROM public.account), NULL, NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 20. Expected: FOREIGN KEY violation on processed_by.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T020', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT COALESCE(MAX(staff_id), 0) + 1 FROM public.staff));

-- 21. Expected: CHECK transaction_accounts_valid (deposit needs a credit account).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T021', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, NULL, NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 22. Expected: CHECK transaction_accounts_valid (deposit cannot debit).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T022', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'), (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 23. Expected: CHECK transaction_accounts_valid (withdrawal needs a debit account).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T023', 'withdrawal', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, NULL, NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 24. Expected: CHECK transaction_accounts_valid (withdrawal cannot credit).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T024', 'withdrawal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 25. Expected: CHECK transaction_accounts_valid (transfer needs both accounts).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T025', 'transfer', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 26. Expected: CHECK transaction_accounts_valid (transfer accounts must differ).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T026', 'transfer', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 27. Expected: CHECK transaction_accounts_valid (reversal needs an account).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T027', 'reversal', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, NULL, (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- 28. Expected: CHECK transaction_accounts_valid (two reversal accounts must differ).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T028', 'reversal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- 29. Expected: CHECK transaction_reversal_fields_valid (original required).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T029', 'reversal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- 30. Expected: CHECK transaction_reversal_fields_valid (staff required).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T030', 'reversal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), NULL);

-- 31. Expected: CHECK transaction_reversal_fields_valid (deposit cannot reference an original).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T031', 'deposit', 100.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 32. Expected: FOREIGN KEY violation on original_transaction_id.
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T032', 'reversal', 100.00, '2026-10-03 09:00:00+01', 'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), NULL, (SELECT COALESCE(MAX(transaction_id), 0) + 1 FROM public."transaction"), (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- 33. Expected: UNIQUE violation on original_transaction_id (already reversed).
INSERT INTO public."transaction" (reference, type, amount, occurred_at, status, debit_account_id, credit_account_id, original_transaction_id, processed_by)
VALUES ('TEST-T033', 'reversal', 500.00, '2026-10-03 09:00:00+01', 'pending', NULL, (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A002'), (SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T004'), (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002'));

-- 34. Expected: CHECK transaction_not_own_reversal.
-- Reserve an ID from the identity sequence; no ID is guessed.
-- OVERRIDING SYSTEM VALUE permits that reserved ID for this test only.
WITH reserved_id AS (
    SELECT nextval(pg_get_serial_sequence('public."transaction"', 'transaction_id')) AS id
)
INSERT INTO public."transaction"
(transaction_id, reference, type, amount, occurred_at, status,
 debit_account_id, original_transaction_id, processed_by)
OVERRIDING SYSTEM VALUE
SELECT id, 'TEST-SELF', 'reversal', 100.00, '2026-10-03 09:00:00+01',
       'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'), id, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S002')
FROM reserved_id;

-- 35. Expected: CHECK transaction_type_valid.
-- An unknown type also breaks transaction_accounts_valid.
-- This schema cannot test that type check without breaking the shape check.
-- PostgreSQL may report either check; this is one invalid business value.
INSERT INTO public."transaction"
(reference, type, amount, occurred_at, status, credit_account_id)
VALUES ('TEST-TYPE', 'payment', 100.00, '2026-10-03 09:00:00+01',
        'pending', (SELECT account_id FROM public.account WHERE account_number = 'DEMO-A001'));

-- 36. Expected: NOT NULL violation on event.
INSERT INTO public.transaction_log (transaction_id, logged_at, event, staff_id)
VALUES ((SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), '2026-10-03 09:00:00+01', NULL, (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 37. Expected: FOREIGN KEY violation on transaction_id.
INSERT INTO public.transaction_log (transaction_id, logged_at, event, staff_id)
VALUES ((SELECT COALESCE(MAX(transaction_id), 0) + 1 FROM public."transaction"), '2026-10-03 09:00:00+01', 'Test event', (SELECT staff_id FROM public.staff WHERE staff_number = 'DEMO-S001'));

-- 38. Expected: FOREIGN KEY violation on staff_id.
INSERT INTO public.transaction_log (transaction_id, logged_at, event, staff_id)
VALUES ((SELECT transaction_id FROM public."transaction" WHERE reference = 'DEMO-T001'), '2026-10-03 09:00:00+01', 'Test event', (SELECT COALESCE(MAX(staff_id), 0) + 1 FROM public.staff));

-- The tests above cover all declared CHECKs, UNIQUE fields and FKs.
-- One required field per table demonstrates NOT NULL rejection.
-- Identity primary keys supply unique, required record IDs automatically.
-- The reversal uniqueness rule applies to every non-NULL original ID.
-- There is no partial unique index in this schema.
--
-- Table checks do not enforce sufficient funds, opening dates,
-- staff authority, equal reversal amounts or opposite movements.
-- They also do not create logs, lock accounts or protect completed rows.
-- Those operations require later logic; they are not negative INSERT tests here.
--
-- Expected counts if SampleData.sql starts empty and every test fails:
-- customer 2; account 3; staff 3; transaction 7; transaction_log 7.
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM public.customer
UNION ALL
SELECT 'account', COUNT(*) FROM public.account
UNION ALL
SELECT 'staff', COUNT(*) FROM public.staff
UNION ALL
SELECT 'transaction', COUNT(*) FROM public."transaction"
UNION ALL
SELECT 'transaction_log', COUNT(*) FROM public.transaction_log;