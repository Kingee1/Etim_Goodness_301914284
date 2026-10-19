# Bank / Fintech Platform ER Diagram

```mermaid
erDiagram
    direction LR

    Customer {
        BIGINT customer_id PK
        VARCHAR(30) customer_number UK
        TEXT full_name
        TEXT email UK
    }

    Account {
        BIGINT account_id PK
        VARCHAR(30) account_number UK
        BIGINT customer_id FK
        TIMESTAMPTZ opened_at
        CHAR(3) currency
    }

    Staff {
        BIGINT staff_id PK
        VARCHAR(30) staff_number UK
        TEXT full_name
        TEXT role
    }

    Transaction {
        BIGINT transaction_id PK
        VARCHAR(50) reference UK
        TEXT type
        NUMERIC(18,2) amount
        TIMESTAMPTZ occurred_at
        TEXT status
        BIGINT debit_account_id FK "Optional"
        BIGINT credit_account_id FK "Optional"
        BIGINT original_transaction_id FK, UK "Optional"
        BIGINT processed_by FK "Optional"
    }

    TransactionLog {
        BIGINT log_id PK
        BIGINT transaction_id FK
        TIMESTAMPTZ logged_at
        TEXT event
        BIGINT staff_id FK "Optional"
    }

    Customer ||..o{ Account : owns
    Account o|..o{ Transaction : debit_account_id
    Account o|..o{ Transaction : credit_account_id
    Staff o|..o{ Transaction : processes
    Transaction ||..|{ TransactionLog : has
    Staff o|..o{ TransactionLog : records
    Transaction o|..o| Transaction : "original to reversal"
```

## Keys and relationship symbols

- **PK — Primary key:** uniquely identifies each record and cannot be empty.
- **FK — Foreign key:** connects a record to an existing record in another table, or the same table.
- **UK — Unique key:** prevents duplicate values. The optional `original_transaction_id` permits empty values, but each supplied value appears only once.
- **`||` — Exactly one.**
- **`o|` — Zero or one.**
- **`o{` — Zero or many.**
- **`|{` — One or many.**
- **`..` — Non-identifying relationship:** the foreign key does not form part of the related record’s primary key.

For example, a customer may own no accounts or several accounts, but each account belongs to exactly one customer.

## Optional fields

The optional fields are:

- **Transaction:** `debit_account_id`, `credit_account_id`, `original_transaction_id` and `processed_by`.
- **TransactionLog:** `staff_id`.

All other fields are required. The two account relationships are individually optional, but every transaction involves one or two accounts according to its type.

The self-relationship allows ordinary transactions to have no original transaction. Every reversal requires exactly one original transaction, which has at most one reversal.

## Additional constraints and transaction logic

Additional checks enforce lowercase emails, `NGN` currency, positive amounts, permitted transaction types, statuses and staff roles, and dates no earlier than account opening.

Checks also enforce the correct debit and credit fields and different accounts for transfers. Account locks and balance checks prevent simultaneous requests from spending the same funds.

Balances are calculated from completed transactions, so a new account starts at zero without a stored balance field.

Transfer completion and logging occur together or neither takes effect. Each transaction receives its first log when created. Completed transactions cannot be edited or deleted, and their logs cannot be deleted.

Reversal logic requires authorised staff, a completed original transaction, the full original amount, opposite account movements and no negative balance. The unique original reference prevents multiple reversals.

Account ownership, opening dates and transaction account references remain fixed once used.