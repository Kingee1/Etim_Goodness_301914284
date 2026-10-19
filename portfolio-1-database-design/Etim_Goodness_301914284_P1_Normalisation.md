# Bank / Fintech Platform Normalisation

Normalisation organises information into related tables to reduce repeated details and prevent inconsistent updates. The examples use the same two fictional deposits and three log records throughout. Only selected fields appear; omitted fields are listed at the end.

## Starting record: a repeated list

Each deposit includes account, customer and staff details, plus a list of log events.

| transaction_id | amount | credit_account_id | customer_id | customer_name | email | processed_by | staff_name | Logs |
|---|---:|---:|---:|---|---|---:|---|---|
| 100 | 5000.00 | 10 | 1 | Ada James | ada@example.com | 7 | Eno Cole | 1000: Created; 1001: Completed |
| 101 | 2000.00 | 11 | 1 | Ada James | ada@example.com | 7 | Eno Cole | 1002: Completed |

**Key:** `transaction_id` identifies each deposit.

The first row contains two logs in one cell. Finding or adding an individual log is awkward. Customer and staff details also repeat.

## 1NF: One value per cell

**First normal form (1NF)** removes repeated lists. Each log has its own row, and the deposit details repeat alongside it.

| log_id | transaction_id | amount | credit_account_id | customer_id | customer_name | email | processed_by | staff_name | event |
|---|---:|---:|---:|---:|---|---|---:|---|---|
| 1000 | 100 | 5000.00 | 10 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Created |
| 1001 | 100 | 5000.00 | 10 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Completed |
| 1002 | 101 | 2000.00 | 11 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Completed |

**Key:** `log_id`, assuming each log receives a unique identifier across the platform. `transaction_id` alone cannot identify these rows because transaction 100 has two logs.

The list is removed, but changing a customer’s email still requires updating several rows.

## 2NF: Depend on the whole key

**Second normal form (2NF)** includes 1NF and removes dependencies on only part of a combined key. A combined key uses two or more fields together to identify a row.

Here, the key is the single field `log_id`. There is no combined key and therefore no partial-key dependency. The table is already in 2NF; no fields move at this stage.

| log_id | transaction_id | amount | credit_account_id | customer_id | customer_name | email | processed_by | staff_name | event |
|---|---:|---:|---:|---:|---|---|---:|---|---|
| 1000 | 100 | 5000.00 | 10 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Created |
| 1001 | 100 | 5000.00 | 10 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Completed |
| 1002 | 101 | 2000.00 | 11 | 1 | Ada James | ada@example.com | 7 | Eno Cole | Completed |

**Key:** `log_id`.

Being in 2NF does not remove all repetition. Deposit amounts, customer details and staff names still repeat.

## 3NF: Keep details with the thing they describe

**Third normal form (3NF)** includes 2NF and removes indirect dependencies through non-key fields. A dependency means one value determines another.

In the example:

- `transaction_id` determines `amount`, `credit_account_id` and `processed_by`.
- `credit_account_id` determines `customer_id`.
- `customer_id` determines the customer’s name and email.
- `processed_by` identifies the staff member and determines their name.

These details move into their own tables.

### Customer

**Primary key:** `customer_id`.

| customer_id | full_name | email |
|---|---|---|
| 1 | Ada James | ada@example.com |

Ada’s email appears once, so a correction requires one update.

### Account

**Primary key:** `account_id`.

**Foreign key:** `customer_id` → Customer.

| account_id | customer_id |
|---|---:|
| 10 | 1 |
| 11 | 1 |

Each account records its owner without repeating the customer’s name and email.

### Staff

**Primary key:** `staff_id`.

| staff_id | full_name |
|---|---|
| 7 | Eno Cole |

The staff name appears once, independently of how many transactions the employee processes.

### Transaction

**Primary key:** `transaction_id`.

**Foreign keys shown:** `credit_account_id` → Account; `processed_by` → Staff.

| transaction_id | type | amount | credit_account_id | status | processed_by |
|---|---|---:|---:|---|---:|
| 100 | deposit | 5000.00 | 10 | completed | 7 |
| 101 | deposit | 2000.00 | 11 | completed | 7 |

Each deposit amount appears once, regardless of the number of logs.

### TransactionLog

**Primary key:** `log_id`.

**Foreign key:** `transaction_id` → Transaction.

| log_id | transaction_id | event |
|---|---:|---|
| 1000 | 100 | Created |
| 1001 | 100 | Completed |
| 1002 | 101 | Completed |

Logs retain their own events without repeating transaction, account, customer or staff details.

The IDs preserve the connections. For example, log 1000 links to transaction 100, which credits account 10, which belongs to customer 1.

## Fields omitted from the examples

The complete design retains:

- **Customer:** `customer_number`.
- **Account:** `account_number`, `opened_at`, `currency`.
- **Staff:** `staff_number`, `role`.
- **Transaction:** `reference`, `occurred_at`, `debit_account_id`, `original_transaction_id`.
- **TransactionLog:** `logged_at`, `staff_id`.

The deposit examples have no debit account or original transaction. Each omitted log `staff_id` is 7.

The final design retains the example’s single-field keys; no combined key is replaced. Automatically generating IDs is an identification choice, not proof of 3NF.

Balances remain calculated from completed credits minus completed debits. Normalisation does not enforce sufficient funds, valid dates, atomic transfers, staff authority or reversal restrictions; the agreed constraints and transaction logic remain necessary.