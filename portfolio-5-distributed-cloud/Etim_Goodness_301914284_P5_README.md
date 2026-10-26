# Portfolio 5 Distributed and Cloud Database Exercise

## Current setup

The Bank / Fintech Platform uses PostgreSQL for customers, accounts, transactions and logs. MongoDB 8.0.34 stores four sample transaction events in fintech_events.transaction_events. Both database servers run in the same Codespace. MongoDB uses a local standalone server, not Atlas. No replica set, sharding or failover experiment is configured. Codespaces hosting alone does not provide database copies on separate servers.

This discussion proposes how the MongoDB events could remain available after a server failure.

## Proposed replication

Replication maintains copies of the same data. The proposed MongoDB replica set has three voting, data-holding members:

| Member | Starting role | Location |
| --- | --- | --- |
| A | Primary: accepts event writes | Host 1, failure zone 1 |
| B | Secondary: copies changes | Host 2, failure zone 2 |
| C | Secondary: copies changes | Host 3, failure zone 3 |

Separate hosts and failure zones reduce the risk of losing all copies together. For example, reversal event E004 records the ₦500 credit reversing Ben Cole's withdrawal DEMO-T004. In the proposal, it is written to the primary and copied asynchronously to secondaries. A secondary can briefly contain older event data. [Replication](https://www.mongodb.com/docs/manual/replication/).

## Failure and consistency

If A fails, B and C can elect an eligible secondary as primary if they can communicate and form a majority. Writes pause during the election. Failover is not instantaneous, and no timing is demonstrated here. One reachable member out of three cannot elect a primary. [Elections](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/).

The proposal requests majority write acknowledgement for important events. In this three-member design, acknowledgement requires two voting, data-holding members. This improves protection against losing an acknowledged event after one member fails, but adds waiting and requires a reachable majority. Recent-event queries use the primary; reports using secondaries may lag. [Write concern](https://www.mongodb.com/docs/v8.0/reference/write-concern/).

Balances, sufficient-funds checks and reversal decisions belong to the PostgreSQL transaction workflow, including controls still requiring implementation. The MongoDB sample events are not a complete balance ledger.

## Sharding and cloud deployment

Sharding divides records across groups of servers; replication copies the same records. Four events do not justify sharding. Future shard-key selection requires evidence about account-history queries, write patterns and data distribution. No sharding is implemented. [Sharding](https://www.mongodb.com/docs/manual/sharding/).

A proposed managed cloud deployment requires authentication, encrypted connections, restricted network access and scheduled backups verified through restore tests. Features and costs require checking for the chosen service. Replication does not replace backups because accidental deletions can reach every copy. [Atlas backup options](https://www.mongodb.com/docs/atlas/backup-restore-cluster/).

MongoDB replication does not replicate PostgreSQL or automatically synchronise the databases. PostgreSQL requires its own availability and recovery plan.