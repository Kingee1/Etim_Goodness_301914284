BEGIN;

CREATE TABLE public.customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(30) NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    CONSTRAINT customer_email_lowercase CHECK (email = lower(email))
);

CREATE TABLE public.account (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL
        REFERENCES public.customer (customer_id),
    opened_at TIMESTAMPTZ NOT NULL,
    currency CHAR(3) NOT NULL,
    CONSTRAINT account_currency_ngn CHECK (currency = 'NGN')
);

CREATE TABLE public.staff (
    staff_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    staff_number VARCHAR(30) NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL,
    CONSTRAINT staff_role_valid
        CHECK (role IN ('operations', 'reversal officer', 'auditor'))
);

CREATE TABLE public."transaction" (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference VARCHAR(50) NOT NULL UNIQUE,
    type TEXT NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL,
    debit_account_id BIGINT
        REFERENCES public.account (account_id),
    credit_account_id BIGINT
        REFERENCES public.account (account_id),
    original_transaction_id BIGINT UNIQUE
        REFERENCES public."transaction" (transaction_id),
    processed_by BIGINT
        REFERENCES public.staff (staff_id),

    CONSTRAINT transaction_type_valid
        CHECK (type IN ('deposit', 'withdrawal', 'transfer', 'reversal')),

    CONSTRAINT transaction_amount_positive
        CHECK (amount > 0 AND amount <> 'NaN'::NUMERIC),

    CONSTRAINT transaction_status_valid
        CHECK (status IN ('pending', 'completed', 'failed')),

    -- Each type requires the appropriate account fields.
    CONSTRAINT transaction_accounts_valid CHECK (
        (type = 'deposit'
            AND debit_account_id IS NULL
            AND credit_account_id IS NOT NULL)
        OR
        (type = 'withdrawal'
            AND debit_account_id IS NOT NULL
            AND credit_account_id IS NULL)
        OR
        (type = 'transfer'
            AND debit_account_id IS NOT NULL
            AND credit_account_id IS NOT NULL
            AND debit_account_id <> credit_account_id)
        OR
        (type = 'reversal'
            AND (debit_account_id IS NOT NULL
                 OR credit_account_id IS NOT NULL)
            AND (debit_account_id IS NULL
                 OR credit_account_id IS NULL
                 OR debit_account_id <> credit_account_id))
    ),

    -- Only reversals reference an original and require staff.
    CONSTRAINT transaction_reversal_fields_valid CHECK (
        (type = 'reversal'
            AND original_transaction_id IS NOT NULL
            AND processed_by IS NOT NULL)
        OR
        (type <> 'reversal'
            AND original_transaction_id IS NULL)
    ),

    CONSTRAINT transaction_not_own_reversal CHECK (
        original_transaction_id IS NULL
        OR original_transaction_id <> transaction_id
    )
);

CREATE TABLE public.transaction_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL
        REFERENCES public."transaction" (transaction_id),
    logged_at TIMESTAMPTZ NOT NULL,
    event TEXT NOT NULL,
    staff_id BIGINT
        REFERENCES public.staff (staff_id)
);

-- Balances are calculated from completed credits minus completed debits.
-- No completed transactions means an account has a zero balance.
-- UNIQUE original_transaction_id permits many NULLs but only one
-- reversal record per original transaction; no partial index is needed.

-- Later triggers or controlled operations must check account opening
-- dates, create the first log, and protect completed records and logs.
-- They must also keep used ownership, opening dates and account links fixed.
-- Debit operations must lock accounts and recheck funds safely.
-- Transfers and their logs must complete together or roll back together.
-- Reversals must verify staff authority, a completed original,
-- the full amount, opposite account movements and sufficient funds.
-- These rules are not enforced by these table definitions alone.

COMMIT;