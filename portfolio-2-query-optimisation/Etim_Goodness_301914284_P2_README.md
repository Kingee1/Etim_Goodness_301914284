# Portfolio 2 Query Processing and Optimisation

## Queries and results

Three queries use the Bank / Fintech Platform records from Portfolio 1:

1. Pending transfers: DEMO-T005 transfers ₦100.00 from Ada James to Ben Cole.
2. Accounts without transactions: DEMO-A003 belongs to Ada James and has no debit or credit transaction records.
3. Transaction counts per account: DEMO-A001 has 4, DEMO-A002 has 5 and DEMO-A003 has 0. These counts include all statuses. A transfer counts once for each account involved.

The third query uses LEFT JOIN to retain the account with zero transactions. All three results match the sample data.

## Index comparison

The experiment uses PostgreSQL 16 in GitHub Codespaces. A separate table, p2_benchmark.transaction_history, contains 100,000 synthetic deposits generated one minute apart. These are benchmark records, including dates beyond the experiment date; Portfolio 1 records remain unchanged.

The unchanged query counts deposits from 09:00 inclusive to 10:00 exclusive on 2 October 2026, using the +01 timezone offset. It returns 60 before and after indexing. A B-tree index named transaction_history_occurred_at_idx indexes occurred_at.

Each phase includes one warm-up followed by three measured runs. The query, data and PostgreSQL settings remain unchanged between phases.

| Measurement | Before index | After index |
| --- | --- | --- |
| Scan type | Seq Scan | Index Only Scan |
| Three execution times (ms) | 12.164, 7.642, 7.526 | 0.070, 0.072, 0.063 |
| Median time (ms) | 7.642 | 0.070 |
| Shared buffer hits, third run | 1344 | 4 |

The indexed scan uses transaction_history_occurred_at_idx and reports zero heap fetches in all three measured runs.

## Performance analysis

Before indexing, PostgreSQL scans 100,000 rows and removes 99,940 that do not match. Afterwards, the index-only scan reads the 60 matching entries without fetching table rows. The measured median execution time falls from 7.642 ms to 0.070 ms, and third-run shared buffer hits fall from 1,344 to 4. Both measured phases use cached data, and Codespaces timings vary, so this small synthetic experiment does not establish production performance. The index also occupies storage and requires maintenance when indexed data changes.

## Files

| File | Contents |
| --- | --- |
| [Queries](Etim_Goodness_301914284_P2_Queries.sql) | Three fintech queries using Portfolio 1 records. |
| [Optimisation](Etim_Goodness_301914284_P2_Optimisation.sql) | Benchmark setup, count checks, execution-plan commands, index and measured results. |
| [Screenshots](screenshots/) | Query results and three measured plans before and after indexing. |

## Reference

[PostgreSQL 16 — Using EXPLAIN](https://www.postgresql.org/docs/16/using-explain.html)