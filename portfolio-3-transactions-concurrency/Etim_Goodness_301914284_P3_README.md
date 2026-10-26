# Portfolio 3 Transactions and Concurrency

## Commit and rollback

In fintech_portfolio, pending transfer DEMO-T005 is changed to failed and a log is added in the same transaction. COMMIT saves both changes. Repeating the guarded update affects zero rows. A second transaction inserts a valid pending deposit, P3-ROLLBACK, before setting its amount to zero triggers transaction_amount_positive. ROLLBACK removes that deposit. Final checks show DEMO-T005 remains failed, its new log exists once and P3-ROLLBACK has zero records.

## Isolation and concurrency control

Two PostgreSQL sessions use READ COMMITTED. Session A inserts a full ₦5,000 reversal of completed deposit DEMO-T002, together with its log, without committing. Session B sees zero reversals and attempts its own reversal of the same deposit. B waits; the activity check shows Lock and a blocking session. After A commits, B receives a transaction_original_transaction_id_key duplicate-key error and rolls back. The final checks show exactly one reversal, P3-REV-A, debiting DEMO-A002, and no P3-REV-B record.

## Conclusion

COMMIT saves changes and ROLLBACK undoes unsaved changes within its transaction. READ COMMITTED hides another session's uncommitted records. The unique constraint on original_transaction_id prevents two reversal records for the same original, even when an earlier count finds none. The guarded status update only prevents repeating that specific update; it does not protect every direct edit. These exercises do not implement automatic sufficient-funds checks or a complete reversal-authorisation workflow. Earlier portfolio outputs describe earlier database states; the separate Portfolio 2 benchmark remains unchanged.

## Files

| File | Contents |
| --- | --- |
| [Transactions](Etim_Goodness_301914284_P3_Transactions.sql) | Commit, guarded repeat update, deliberate error, rollback and final checks. |
| [Session A](Etim_Goodness_301914284_P3_SessionA.sql) | Starting checks, reversal and log, waiting check and commit. |
| [Session B](Etim_Goodness_301914284_P3_SessionB.sql) | Isolation check, competing reversal, rollback and final checks. |
| [Screenshots](screenshots/) | Commit/rollback evidence, waiting sessions and final concurrency outcome. |

## References

- [PostgreSQL 16 — Transactions](https://www.postgresql.org/docs/16/tutorial-transactions.html)
- [PostgreSQL 16 — Transaction Isolation](https://www.postgresql.org/docs/16/transaction-iso.html)
- [PostgreSQL 16 — Index Uniqueness Checks](https://www.postgresql.org/docs/16/index-unique-checks.html)