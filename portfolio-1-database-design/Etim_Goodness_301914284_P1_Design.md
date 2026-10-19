# Bank / Fintech Platform Database Design

## 1. Entities — what the database keeps records of

Five entities support the agreed operations:

- **Customer:** people who own accounts.
- **Account:** accounts holding naira funds.
- **Staff:** employees recording transactions, approving reversals or auditing records.
- **Transaction:** deposits, withdrawals, transfers and reversals.
- **TransactionLog:** dated records of transaction events and changes.

## 2. Attributes and keys — fields, PostgreSQL types, PKs, FKs, unique fields, and required or optional values

A **primary key (PK)** identifies each record. A **foreign key (FK)** connects it to an existing record. All fields below are required unless marked optional.

| Entity | Fields and PostgreSQL types |
|---|---|
| Customer | `customer_id BIGINT` PK; `customer_number VARCHAR(30)` unique; `full_name TEXT`; `email TEXT` unique |
| Account | `account_id BIGINT` PK; `account_number VARCHAR(30)` unique; `customer_id BIGINT` FK → Customer; `opened_at TIMESTAMPTZ`; `currency CHAR(3)` |
| Staff | `staff_id BIGINT` PK; `staff_number VARCHAR(30)` unique; `full_name TEXT`; `role TEXT` |
| Transaction | `transaction_id BIGINT` PK; `reference VARCHAR(50)` unique; `type TEXT`; `amount NUMERIC(18,2)`; `occurred_at TIMESTAMPTZ`; `status TEXT`; optional `debit_account_id BIGINT` and `credit_account_id BIGINT` FKs → Account; optional, unique `original_transaction_id BIGINT` FK → Transaction; optional `processed_by BIGINT` FK → Staff |
| TransactionLog | `log_id BIGINT` PK; `transaction_id BIGINT` FK → Transaction; `logged_at TIMESTAMPTZ`; `event TEXT`; optional `staff_id BIGINT` FK → Staff |

`TIMESTAMPTZ` stores a date and time with timezone support. `NUMERIC(18,2)` stores exact amounts with two decimal places.

Balances are calculated from completed credits minus completed debits. No balance field is stored, avoiding disagreement between balances and transaction history.

## 3. Relationships — how the tables connect

- One customer owns zero or many accounts; each account belongs to exactly one customer.
- One account appears in zero or many transactions. Each transaction references one or two accounts through its debit and credit fields.
- One staff member processes zero or many transactions; each transaction names zero or one staff member. Reversals require one authorised staff member.
- One transaction has one or many logs; each log belongs to exactly one transaction. Transaction creation also creates its first log.
- One staff member appears in zero or many logs; each log names zero or one staff member.
- One original transaction has zero or one reversal; each reversal references exactly one original transaction.

No linking table is needed because debit and credit accounts have separate, fixed roles.

## 4. Business rules and constraints — match every numbered rule

1. Required, unique customer numbers and emails enforce identification. Emails are stored in lowercase.
2. Required, unique account numbers and the customer FK enforce ownership.
3. Checks require currency `NGN` and amounts above zero. Accounts start at zero because they have no completed transactions.
4. Required, unique references and a status check allow only pending, completed or failed. A database trigger—an automatic check during changes—rejects dates before account opening.
5. Checks require deposits to have only a credit account, withdrawals only a debit account, and transfers two different accounts.
6. A controlled operation locks affected accounts, then calculates available funds before completion. Locks make competing requests wait, preventing double spending.
7. Balance calculations include only completed transactions. Transfer completion and its log are saved together, or cancelled together.
8. Database protections prevent editing or deleting completed transactions and deleting their logs. A reversal operation checks staff authority, the original’s completed status, equal amount, opposite account movements and sufficient funds; a unique original reference prevents repeated reversals.

For example, a completed ₦2,000 transfer reduces one balance and increases the other by ₦2,000.

## 5. Design assumptions

- Staff have one role: operations, reversal officer or auditor; authentication remains excluded.
- Reversals are new transactions, preserving the original history.
- Account ownership, opening dates and transaction account references remain fixed once used.