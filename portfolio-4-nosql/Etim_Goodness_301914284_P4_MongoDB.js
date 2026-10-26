// Portfolio 4: separate fictional fintech event examples.
// This script does not read or change PostgreSQL.
db = db.getSiblingDB("fintech_events");

// Stop rather than insert into a collection containing existing records.
if (db.transaction_events.countDocuments() !== 0) {
  throw new Error("Collection is not empty. Check the existing documents.");
}

// Event IDs identify events, not PostgreSQL transactions.
// Dates are UTC; amounts use exact Decimal128 values.
printjson(db.transaction_events.insertMany([
  {
    _id: "E001",
    event_type: "transaction_recorded",
    occurred_at: ISODate("2026-10-02T08:05:00Z"),
    customer: {
      customer_number: "DEMO-C002",
      full_name: "Ben Cole"
    },
    account: { account_number: "DEMO-A002", currency: "NGN" },
    transaction: {
      reference: "DEMO-T002",
      amount: NumberDecimal("5000.00")
    },
    details: { type: "deposit", status: "completed" }
  },
  {
    _id: "E002",
    event_type: "transaction_reversed",
    occurred_at: ISODate("2026-10-03T13:00:00Z"),
    customer: {
      customer_number: "DEMO-C002",
      full_name: "Ben Cole"
    },
    account: { account_number: "DEMO-A002", currency: "NGN" },
    transaction: {
      reference: "P3-REV-A",
      amount: NumberDecimal("5000.00")
    },
    details: {
      original_reference: "DEMO-T002",
      direction: "debit",
      status: "completed"
    }
  },
  {
    _id: "E003",
    event_type: "transaction_recorded",
    occurred_at: ISODate("2026-10-02T10:00:00Z"),
    customer: {
      customer_number: "DEMO-C002",
      full_name: "Ben Cole"
    },
    account: { account_number: "DEMO-A002", currency: "NGN" },
    transaction: {
      reference: "DEMO-T004",
      amount: NumberDecimal("500.00")
    },
    details: { type: "withdrawal", status: "completed" }
  },
  {
    _id: "E004",
    event_type: "transaction_reversed",
    occurred_at: ISODate("2026-10-02T12:00:00Z"),
    customer: {
      customer_number: "DEMO-C002",
      full_name: "Ben Cole"
    },
    account: { account_number: "DEMO-A002", currency: "NGN" },
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
]));

// Q1: Expected count is 4.
printjson(db.transaction_events.countDocuments());

// Q2: Expected order is E001, E003, E004, E002.
printjson(db.transaction_events.find(
  { "account.account_number": "DEMO-A002" },
  { _id: 1, event_type: 1, occurred_at: 1, transaction: 1 }
).sort({ occurred_at: 1, _id: 1 }).toArray());

// Q3: Expected result is the complete E004 document.
printjson(db.transaction_events.find(
  { event_type: "transaction_reversed", "details.direction": "credit" }
).toArray());

// These sample events are not a complete audit trail or balance ledger.
// No schema validator or SQL synchronisation is configured.