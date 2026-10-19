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