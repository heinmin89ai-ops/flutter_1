# Synchronization Strategy

1. Write to local SQLite first and enqueue a deterministic mutation.
2. Render the local result immediately with a visible sync state.
3. A connectivity-aware sync engine drains pending mutations in order.
4. Mutations use idempotency keys and retry with exponential backoff.
5. Process restarts resume `PENDING` and recover stale `SYNCING` records.
6. Successful operations become `COMPLETED`; bounded failures become `FAILED` with a user-visible reason.

Operational records use version and server timestamp conflict checks. Financial records are append-only where possible; conflicting edits require an explicit server decision. Inventory uses movement records and transactional server updates rather than stale quantity overwrites.

## Implemented client components

- `SqliteSyncQueue` persists mutations across process termination.
- Queue records use a local UUID and an entity-operation idempotency key.
- `SyncEngine` recovers stale `SYNCING` records, retries failures with exponential backoff, and stops retrying after eight attempts.
- `FirestoreSyncOperationHandler` applies non-financial operational mutations.
- Customer and vehicle registration writes locally before enqueueing Firestore synchronization.
- The app shell displays the engine's real sync state and invokes a retry when the status button is pressed.

Financial records remain server-owned and must use their dedicated callable functions instead of the generic queue handler.

The UI must distinguish `Offline`, `Pending changes`, `Syncing`, and `Sync failed`. Local persistence means the user's work is safely stored on the device; it does not mean cloud synchronization has completed.
