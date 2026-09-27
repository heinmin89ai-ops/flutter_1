# Database Proposal

## Firestore top-level collections

Tenant-owned collections use a stable document ID and include `shopId`:

- `shops/{shopId}`
- `users/{uid}`
- `staffInvitations/{code}`
- `customers/{customerId}`
- `vehicles/{vehicleId}`
- `jobCards/{jobCardId}`
- `jobCardItems/{itemId}`
- `inventoryItems/{inventoryItemId}`
- `inventoryMovements/{movementId}`
- `warranties/{warrantyId}`
- `invoices/{invoiceId}`
- `payments/{paymentId}`
- `auditLogs/{auditId}`

The backend derives sensitive totals, stock changes, warranty expiry, and claims. Client payloads are treated as requests, not authority.

## Phase 3 access rules

`shops/{shopId}`, `customers/{customerId}`, and `vehicles/{vehicleId}` are read through the signed-in staff profile. Shop settings updates preserve the existing tenant and active state. A workshop owner writes staff role and active state directly on `users/{uid}`; new staff create their own profile by claiming a `staffInvitations/{code}` document.

Phase 4 adds a local SQLite database with indexed `vehicles.normalizedLicensePlate`, `vehicles.shopId`, and `customers.shopId`. Firestore uses a composite index for vehicle synchronization by `shopId` and normalized plate.

Job cards are queried by `shopId` and `updatedAt` descending. Clients may create only `DRAFT` records; all later status changes and repair-work updates go through trusted callable functions.

Mechanic assignment is also server-side: the target user must belong to the same shop, have the `MECHANIC` role, and be active. Direct job-card updates are denied.

Inventory quantities are maintained on `inventoryItems` only by the `recordInventoryMovement` transaction. Each movement is append-only in `inventoryMovements` with actor, reason, delta, and type. Warranty records are created only by `createWarranty`; expiry is calculated from the server start date and validated duration.

Invoices store all monetary values as integer minor units: `subtotalMinorUnits`, `discountMinorUnits`, `taxMinorUnits`, `totalMinorUnits`, `amountPaidMinorUnits`, and `balanceMinorUnits`. `createInvoice` recalculates item totals server-side. Payments are append-only in `payments`; `receivePayment` transactionally updates invoice balance and status.

Reports use server-side date-range queries over completed jobs, invoices, payments, and inventory. Required composite indexes are declared in `firestore.indexes.json`; report results do not expose raw cross-tenant collections to the client.

## Local Drift schema proposal

Tables will be added incrementally with versioned migrations:

- `users`
- `shops`
- `customers`
- `vehicles` with an index on `normalizedLicensePlate`
- `job_cards` with indexes on `status`, `vehicleId`, and `updatedAt`
- `job_card_items`
- `inventory_items`
- `invoices`
- `payments`
- `sync_queue`
- `attachments`

Every table is scoped by `shopId` except local device metadata. Offline-created records receive IDs locally and carry `updatedAt`, `version`, and sync metadata.
