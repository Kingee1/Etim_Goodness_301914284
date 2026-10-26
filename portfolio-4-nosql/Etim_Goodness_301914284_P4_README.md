# Portfolio 4 NoSQL and Advanced Data Models

## Document model

The fintech_events database contains one collection, transaction_events. Each document represents a recorded transaction or a reversal event. Shared fields are _id, event_type, occurred_at, customer, account, transaction and details. Customer, account and transaction information is embedded inside each event. Recorded transactions contain type and status details; reversals contain the original reference, debit or credit direction, and status.

Event IDs are separate from transaction references. Dates use BSON date values in UTC, and amounts use Decimal128 for exact decimal values.

Example reversal document:

```javascript
{
  _id: "E004",
  event_type: "transaction_reversed",
  occurred_at: ISODate("2026-10-02T12:00:00Z"),
  customer: {
    customer_number: "DEMO-C002",
    full_name: "Ben Cole"
  },
  account: {
    account_number: "DEMO-A002",
    currency: "NGN"
  },
  transaction: {
    reference: "DEMO-T007",
    amount: NumberDecimal("500.00")
  },
  details: {
    original_reference: "DEMO-T004",
    direction: "credit",
    status: "completed"
  }
}
```

## Implementation and results

MongoDB Community Server 8.0.34 runs locally in GitHub Codespaces. Four fictional event documents are inserted through mongosh, and the insert is acknowledged with IDs E001, E002, E003 and E004. The count query returns 4.

The ordered event-history query for account DEMO-A002 returns E001, E003, E004 and E002. These represent deposit DEMO-T002, withdrawal DEMO-T004, withdrawal reversal DEMO-T007 and deposit reversal P3-REV-A. The nested-field query for transaction_reversed events with details.direction equal to credit returns only E004.

The documents are entered separately using identifiers from the fintech case study. They are not automatically extracted from PostgreSQL, and these MongoDB commands do not change PostgreSQL.

## Why MongoDB fits

Embedding keeps the customer, account, transaction and event-specific details together for event-history queries. Different event types can contain different details without requiring every document to contain every possible field. One document per event allows the history to grow without storing all events inside one expanding account document.

Copied names and identifiers are snapshots; they do not automatically follow PostgreSQL updates. This example has no schema validator, SQL foreign keys or automatic synchronisation. It represents selected sample events, not a complete audit history or a source for calculating account balances. The relational system remains the place for the existing keys and banking controls, including those requiring additional transaction logic.

## Files

| File | Contents |
| --- | --- |
| [MongoDB script](Etim_Goodness_301914284_P4_MongoDB.js) | Database selection, existing-data guard, four documents and three queries. |
| [Setup notes](Etim_Goodness_301914284_P4_Setup.md) | Local installation, connection details and verified version and ping. |
| [Package source](Etim_Goodness_301914284_P4_MongoDBSource.list) | Official MongoDB 8.0 package source for Ubuntu Noble. |
| [Screenshots](screenshots/) | MongoDB connection check and event-query results. |

## References

- [MongoDB — Data modelling best practices](https://www.mongodb.com/docs/manual/data-modeling/best-practices/)
- [MongoDB — insertMany](https://www.mongodb.com/docs/manual/reference/method/db.collection.insertMany/)
- [MongoDB — Query embedded documents](https://www.mongodb.com/docs/manual/tutorial/query-embedded-documents/)