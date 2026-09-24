# Local Database Migrations

The local operational database is SQLite and is opened by the local stores with an explicit schema version.

## Version 1

Creates:

- `customers`
- `vehicles`
- `sync_queue`

Indexes:

- `vehicles.normalizedLicensePlate`
- `vehicles.shopId`
- `customers.shopId`
- `sync_queue(status, createdAt)`
- `sync_queue(entityType, entityId, operation)` for pending idempotency

Migration rules:

1. Increment the SQLite version before changing a table.
2. Use `onUpgrade` with deterministic `ALTER TABLE` or new-table migration steps.
3. Never drop operational data without an explicit export/recovery plan.
4. Add a migration test before shipping a new version.
5. Keep cloud data authoritative so a local database can be rebuilt after reinstall.