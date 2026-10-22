# Portfolio 1 Database Design and Modelling

## Case study
The Bank / Fintech Platform manages customers, accounts, deposits, withdrawals, internal transfers and transaction logs. It records money movements and supports balance checks, transaction reviews and corrections.

## Users
Customers view balances and transaction histories and request transfers or withdrawals. Operations staff register customers, open accounts and record deposits. Authorised staff process reversals, while auditors review balances and transaction logs.

## Main operations
Register customers; open accounts; record deposits; process withdrawals; transfer funds between accounts; reverse incorrect completed transactions; review balances and transaction histories.

## Business rules
1. Each customer has a unique customer number and email address.
2. Each account has a unique account number and belongs to one existing customer. A customer may hold several accounts.
3. All accounts use Nigerian naira and start with a zero balance. Transaction amounts must be positive.
4. Each transaction has a unique reference, date and time, and a status of pending, completed or failed. It cannot be dated before any account involved was opened.
5. Deposits credit one existing account; withdrawals debit one existing account. Internal transfers involve two different existing accounts.
6. A withdrawal or transfer requires sufficient funds. Simultaneous requests must not spend the same available money twice.
7. Only completed transactions affect balances. Both sides of an internal transfer take effect together, or neither does.
8. Completed transactions and their logs cannot be deleted. An authorised reversal must link to the original transaction, reverse its full amount only once and leave no account balance below zero.

## Scope
The system covers one fictional fintech platform, individual customers, accounts owned by one person and internal naira transactions using fictional data. Loans, interest, fees, cards, external payments, foreign exchange and user authentication are excluded.

## Design and implementation files

| File | Contents |
| --- | --- |
| [Design](Etim_Goodness_301914284_P1_Design.md) | Entities, attributes, keys and relationships. |
| [ER diagram](Etim_Goodness_301914284_P1_ERDiagram.md) | The five tables, their fields and relationships. |
| [Normalisation](Etim_Goodness_301914284_P1_Normalisation.md) | Example tables explaining 1NF, 2NF and 3NF. |
| [Schema](Etim_Goodness_301914284_P1_Schema.sql) | Table definitions, primary keys, foreign keys and constraints. |
| [Sample records](Etim_Goodness_301914284_P1_Sampledata.sql) | Fictional customers, accounts, staff, transactions and logs. |
| [Constraint tests](Etim_Goodness_301914284_P1_Constraintstest.sql) | Invalid inserts, expected errors and the final count query. |
| [Screenshots](screenshots/) | Saved commands, table definitions and test results. |

## Implementation

The database runs on PostgreSQL 16 in GitHub Codespaces and is named fintech_portfolio. It contains customer, account, staff, transaction and transaction_log. Each table has an automatically generated primary key. Foreign keys connect accounts to customers, transactions to accounts and staff, and logs to transactions and staff. Reversals reference their original transactions.

Required fields use NOT NULL constraints. Customer numbers, emails, account numbers, staff numbers and transaction references are unique. Checks restrict currency, staff roles, transaction amounts, statuses and account combinations. A unique original transaction reference prevents multiple reversal records for the same transaction. The schema and sample data are committed separately. Invalid inserts are tested individually outside a transaction block, and logs are added explicitly.

## Test results

The observed tests reject missing required values, duplicate identifiers and emails, uppercase emails, invalid currency and staff roles, invalid amounts and statuses, and links to nonexistent records. Account-field checks reject invalid deposit, withdrawal, transfer and reversal combinations. Reversal tests reject missing required links, self-references and a second reversal of the same original transaction. The invalid transaction type is rejected by transaction_accounts_valid; this result does not independently demonstrate transaction_type_valid.

The final counts are 2 customers, 3 accounts, 3 staff, 7 transactions and 7 transaction logs. The rejected inserts add no rows. The sample transactions include two completed deposits, a completed transfer, a completed withdrawal, a pending transfer, a failed withdrawal and a completed reversal. One account has no transactions.

The table definitions alone do not enforce sufficient funds, safe simultaneous spending, transaction dates relative to account opening, staff authority or full and opposite reversal movements. Automatic logging, protection of completed transactions and logs, and restrictions on changing used account details also require additional logic. These workflow rules remain for later implementation and testing.