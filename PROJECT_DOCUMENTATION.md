# Workshop Ops Project Documentation

## 1. Overview

Workshop Ops is an internal Flutter application for multi-tenant car workshop operations. It supports workshop staff across Android phones, Android tablets, iPhones, and iPads.

The application is designed around these priorities:

1. Tenant isolation and security
2. Data integrity
3. Offline-first operations
4. Financial correctness
5. Role-based access
6. Maintainability and testability

There is no customer-facing application in this project.

## 2. Current Implementation Status

Phases 1 through 14 have been scaffolded and implemented incrementally:

- Phase 1: Flutter foundation, Material 3 shell, responsive navigation, theme, app composition.
- Phase 2: Firebase Authentication, session restoration, claims parsing, login, logout, access gate.
- Phase 3: Shops and staff management, server-side claims management, tenant rules.
- Phase 4: Customers and vehicles, local plate search, SQLite cache, UUID identifiers.
- Phase 5: Job cards, state machine, mechanic assignment, server-side transitions.
- Phase 6: Inventory items and transactional stock movements.
- Phase 7: Warranty creation and server-calculated expiry.
- Phase 8: POS and invoice creation with integer minor-unit money.
- Phase 9: Payments, partial payment, balance tracking, append-only payment records.
- Phase 10: Receipt printer abstraction and ESC/POS encoding.
- Phase 11: Offline queue, retry, idempotency, connectivity-triggered sync.
- Phase 12: Server-side operational and financial reports.
- Phase 13: Active-account enforcement, Storage rules, audit logging, security hardening.
- Phase 14: CI, emulator configuration, migration contract, testing and deployment documentation.

Important runtime limitation: Flutter SDK and Firebase CLI were not installed in the original development environment. Dart editor diagnostics and Firebase Functions TypeScript builds were run successfully, but Flutter runtime tests and emulator tests must be run on a configured development machine or CI runner.

## 3. Technology Stack

### Client

- Flutter
- Dart with null safety
- Material 3
- `firebase_auth`
- `firebase_core`
- `cloud_firestore`
- `cloud_functions`
- `sqflite` for the current local operational database
- `path`
- `uuid`
- `connectivity_plus`

### Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions v2
- TypeScript
- Node.js 20 for deployment

### Architecture

```text
Presentation
    -> Domain
        -> Repository interface
            -> Firebase / SQLite / platform adapter
```

Business rules that affect authorization, money, inventory, warranty dates, and payment state are validated by trusted Cloud Functions. Widgets do not call Firestore directly for sensitive operations.

## 4. Project Structure

```text
lib/
  app/
    app.dart
    router/
      app_shell.dart
    theme/
      app_theme.dart
  core/
    printing/
      esc_pos_receipt_encoder.dart
      esc_pos_receipt_printer.dart
      receipt.dart
      receipt_printer.dart
    sync/
      firestore_sync_handler.dart
      sqlite_sync_queue.dart
      sync_engine.dart
      sync_queue_item.dart
      sync_status.dart
  features/
    auth/
    billing/
    customers_vehicles/
    dashboard/
    inventory/
    job_cards/
    reports/
    shops/
    warranty/
  main.dart
functions/
  src/index.ts
  package.json
  tsconfig.json
test/
  app_smoke_test.dart
  auth_user_test.dart
  job_card_state_test.dart
  license_plate_normalizer_test.dart
  money_calculation_test.dart
  receipt_encoder_test.dart
  sync_queue_item_test.dart
  warranty_calculation_test.dart
```

The feature folders use `domain`, `data`, and `presentation` boundaries. The application composition root is `lib/main.dart` and dependencies are passed through `WorkshopOpsApp` and `AuthGate`.

## 5. Authentication and Session

The app starts Firebase, creates the repositories, initializes the local database and sync queue, then renders the application.

Authentication uses Firebase email/password login. Firebase Auth remains responsible for session restoration through `authStateChanges()`.

The client reads these trusted custom claims:

```json
{
  "shopId": "SHOP_001",
  "role": "FRONT_DESK",
  "permissions": ["customers.read"],
  "isActive": true
}
```

The login form never accepts `shopId`, role, or permissions. The account is rejected when:

- The account is inactive.
- The role is missing or invalid.
- A non-super-admin account has no shop assignment.

Role changes require a trusted backend update and a token refresh before the new claims are visible to the client.

## 6. Roles

Supported roles:

- `SUPER_ADMIN`
- `SHOP_OWNER`
- `MANAGER`
- `FRONT_DESK`
- `MECHANIC`

The frontend hides features for usability, but frontend visibility is not security. Firestore rules, Storage rules, repository boundaries, and callable functions are authoritative.

| Capability | Super Admin | Shop Owner | Manager | Front Desk | Mechanic |
|---|---:|---:|---:|---:|---:|
| Create workshop | Yes | No | No | No | No |
| Manage staff | Platform | Own shop | No | No | No |
| Customers and vehicles | Platform | Yes | Yes | Yes | Assigned context |
| Create job card | Platform | Yes | Yes | Yes | No |
| Assign jobs | Platform | Yes | Yes | No | No |
| Repair work | No | Yes | Yes | No | Assigned jobs |
| Inventory | No | Yes | Yes | No | No |
| Billing and payments | No | Yes | Yes | Yes | No |
| Reports | Platform | Yes | Operational | No | No |
| Shop settings | No | Yes | Limited | No | No |

## 7. Firestore Collections

All tenant-owned documents contain `shopId`.

```text
shops/{shopId}
users/{uid}
customers/{customerId}
vehicles/{vehicleId}
jobCards/{jobCardId}
jobCardItems/{itemId}
inventoryItems/{inventoryItemId}
inventoryMovements/{movementId}
warranties/{warrantyId}
invoices/{invoiceId}
payments/{paymentId}
auditLogs/{auditId}
```

### Access model

- `shops`: authenticated tenant reads; owner updates; creation is callable-function-only.
- `users`: authenticated same-tenant reads; direct writes denied.
- `customers` and `vehicles`: same-tenant operational reads and controlled writes.
- `jobCards`: clients may create only `DRAFT`; all later transitions are callable-function-only.
- `inventoryItems`: owner or manager may create; quantity updates are server-only.
- `inventoryMovements`: reads are tenant-scoped; writes are server-only.
- `warranties`: reads are tenant-scoped; creation is server-only.
- `invoices` and `payments`: reads are tenant-scoped; all writes are server-only.
- `auditLogs`: authorized reads; ordinary client writes are denied.

Firestore rules are in [firestore.rules](firestore.rules). Required indexes are in [firestore.indexes.json](firestore.indexes.json).

## 8. Local Database

The project specification preferred Drift, but the current implementation uses `sqflite` to keep the first runnable local adapter small and direct. The repository boundary allows a later Drift replacement without changing presentation code.

Current local tables:

- `customers`
- `vehicles`
- `sync_queue`

Current indexes:

- `vehicles.normalizedLicensePlate`
- `vehicles.shopId`
- `customers.shopId`
- `sync_queue(status, createdAt)`
- pending sync idempotency index over `entityType`, `entityId`, and `operation`

The local database is an operational cache and offline queue. Firestore remains the cloud source of truth. A reinstall may rebuild local data from the cloud.

Migration rules are documented in [DATABASE_MIGRATIONS.md](DATABASE_MIGRATIONS.md).

## 9. Customers and Vehicles

Customers support:

- Individual customers
- Company customers
- Phone, email, address, tax ID, notes
- Multiple vehicles per customer

Vehicles support:

- License plate
- Normalized license plate
- VIN
- Make, model, year, color
- Mileage, fuel type, transmission
- Notes

License plates are normalized by uppercasing and removing non-alphanumeric characters. For example:

```text
ab-123 xy -> AB123XY
```

Registration generates UUIDs locally. Customer and vehicle writes are stored locally first and are then placed on the sync queue.

## 10. Job Cards

Job-card statuses:

```text
DRAFT
OPEN
ASSIGNED
IN_PROGRESS
WAITING_FOR_PARTS
WAITING_FOR_APPROVAL
COMPLETED
READY_FOR_PICKUP
CLOSED
CANCELLED
```

Normal workflow:

```text
DRAFT
  -> OPEN
  -> ASSIGNED
  -> IN_PROGRESS
  -> WAITING_FOR_PARTS or WAITING_FOR_APPROVAL
  -> COMPLETED
  -> READY_FOR_PICKUP
  -> CLOSED
```

Status transitions are implemented in both the Dart domain model and the trusted backend. The backend reads the current status inside a Firestore transaction, validates the target transition, and writes timestamps such as `startedAt`, `completedAt`, and `closedAt`.

Mechanics can only update repair work and transitions for jobs assigned to their UID. Assignment validates same-shop, active, `MECHANIC` role membership.

## 11. Inventory

Inventory prices use integer minor units. Inventory quantity is not treated as a freely editable field.

Supported movement types:

- `STOCK_IN`
- `STOCK_OUT`
- `ADJUSTMENT`
- `RETURN`

`recordInventoryMovement` runs a Firestore transaction that:

1. Validates caller role and tenant.
2. Reads current quantity.
3. Calculates the delta.
4. Rejects negative resulting stock.
5. Updates the item quantity.
6. Appends an immutable movement record.
7. Records the actor and reason.

## 12. Warranty

Warranty creation is restricted to completed job cards and authorized roles. Supported UI durations are 1, 3, 6, and 12 months; the backend accepts a validated range from 1 to 120 months.

The client does not provide the authoritative expiry date. The backend creates the start date and calculates the expiry date from the validated duration.

## 13. POS, Invoices, and Payments

All money uses integer minor units:

```text
subtotalMinorUnits
discountMinorUnits
taxMinorUnits
totalMinorUnits
amountPaidMinorUnits
balanceMinorUnits
```

Invoice item types:

- Labor
- Part
- Service
- Direct sale

Invoice creation validates each item on the server and recalculates subtotal, discount, tax, and total. The client-provided total is not trusted.

Payment methods:

- Cash
- Card
- Bank transfer
- Mobile payment
- Other

`receivePayment` uses a transaction and rejects:

- Non-positive payment amounts
- Invalid methods
- Payments over the balance
- Payments for void or fully paid invoices
- Cross-tenant invoice access

Payment documents are append-only. Corrections should use a future reversal/void function rather than overwriting history.

## 14. Receipt Printing

The business layer depends on `ReceiptPrinter`:

```dart
Future<List<PrinterDevice>> discover();
Future<void> connect(PrinterDevice device);
Future<void> printReceipt(Receipt receipt);
Future<void> disconnect();
```

`EscPosReceiptEncoder` produces printer bytes. `PrinterTransport` is the platform adapter boundary for Bluetooth discovery, connection, and byte writes. Android/iOS Bluetooth implementation can be added without changing billing code.

The encoder includes printer initialization, centered shop/invoice header, receipt lines, totals, and a cut command.

## 15. Offline Synchronization

The client flow is:

```text
UI
 -> local SQLite write
 -> sync_queue insert
 -> immediate local UI update
 -> connectivity-aware SyncEngine
 -> Firestore
```

Queue states:

- `PENDING`
- `SYNCING`
- `FAILED`
- `COMPLETED`

Queue behavior:

- UUID queue ID
- Entity-operation idempotency key
- Ordered pending reads
- Exponential backoff
- Maximum eight retry attempts
- Stale `SYNCING` records become `FAILED` after restart
- Connectivity return triggers sync
- Sync status is visible in the app shell

Generic Firestore sync applies operational customer/vehicle mutations. Financial records, inventory movements, warranty creation, invoices, and payments use dedicated callable functions instead of the generic queue handler.

Conflict policy:

- Operational records: version/timestamp checks are preferred.
- Financial records: append-only records and explicit conflict handling.
- Inventory: movement records and transactions, never stale quantity overwrite.

## 16. Reports

The Reports module calls `getWorkshopReport` with a UTC date range. The backend validates tenant and role, then aggregates:

- Completed jobs
- Invoice count
- Revenue
- Paid amount
- Outstanding balance
- Low-stock item count

Raw cross-tenant collections are not sent to the client. Reports are available to shop owners and managers according to the role matrix.

## 17. Security Hardening

Implemented controls:

- Trusted Auth custom claims
- Active-account enforcement in callable functions
- Active-account enforcement in Firestore and Storage rules
- Tenant checks on every sensitive callable operation
- Direct client writes denied for staff, audit logs, movements, warranties, invoices, and payments
- Storage tenant paths
- Image and PDF content-type checks
- Image size limit of 10 MB
- PDF size limit of 20 MB
- Server-side money, stock, warranty, and payment validation
- Append-only audit events for sensitive operations

Storage paths:

```text
shops/{shopId}/vehicles/{vehicleId}/{fileName}
shops/{shopId}/jobCards/{jobCardId}/{fileName}
shops/{shopId}/documents/{fileName}
```

Storage rules are in [storage.rules](storage.rules).

## 18. Audit Logging

Sensitive callable operations write to `auditLogs` with:

```text
auditId
shopId
actorUid
action
entityType
entityId
before
after
timestamp
```

Current audited actions include:

- Staff updates
- Job status changes
- Mechanic assignment
- Inventory movements
- Warranty creation
- Invoice issuance
- Payment receipt

Ordinary clients cannot write audit logs.

## 19. Navigation

The shell currently exposes:

- Dashboard
- Vehicles
- Job cards
- Inventory
- Billing
- Warranty
- Shops and staff for super admins/shop owners
- Reports for super admins/shop owners/managers

Navigation is responsive:

- Phone: bottom navigation
- Tablet/desktop: navigation rail

The feature screens remain responsible for loading, empty, error, and permission states.

## 20. Testing

Existing focused tests cover:

- Auth role claim parsing
- Job-card transitions
- License-plate normalization
- Money calculations
- Warranty expiry calculation
- ESC/POS command encoding
- Sync queue idempotency key
- Application shell widget rendering

Commands:

```bash
flutter pub get
flutter analyze
flutter test
```

Focused commands:

```bash
flutter test test/job_card_state_test.dart
flutter test test/money_calculation_test.dart
flutter test test/warranty_calculation_test.dart
flutter test test/receipt_encoder_test.dart
flutter test test/sync_queue_item_test.dart
```

Emulator workflow:

```bash
firebase emulators:start
firebase emulators:exec --only auth,firestore,functions,storage "flutter test"
```

Security scenarios to test in the emulator:

- Unauthenticated read/write rejection
- Inactive account rejection
- Cross-shop read/write rejection
- Mechanic financial access rejection
- Negative stock rejection
- Overpayment rejection
- Direct audit-log write rejection
- Storage content-type and size rejection

## 21. CI

GitHub Actions is defined in [.github/workflows/ci.yml](.github/workflows/ci.yml).

Flutter CI runs:

- `flutter pub get`
- Dart formatting check
- `flutter analyze`
- `flutter test --coverage`

Functions CI runs:

- Node.js 20 setup
- `npm ci`
- `npm run build`

## 22. Local Setup

Prerequisites:

- Flutter stable
- Dart SDK from Flutter
- Node.js 20
- Firebase CLI
- A Firebase project
- FlutterFire configuration for each platform/environment

Development:

```bash
flutterfire configure
flutter pub get
firebase emulators:start
flutter run
```

The emulator UI is configured for `http://127.0.0.1:4000`.

## 23. Deployment

Build and deploy backend rules/functions:

```bash
cd functions
npm ci
npm run build
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

Use separate Firebase projects for development, staging, and production. Never commit:

- Service account keys
- Firebase private keys
- Production secrets
- `google-services.json`
- `GoogleService-Info.plist`
- Keystores

Before production rollout:

1. Verify the active Firebase project.
2. Deploy and review rules and indexes.
3. Verify Auth claims for test users.
4. Enable App Check and Crashlytics.
5. Configure Firestore backups/export.
6. Run CI and emulator security tests.
7. Test a staged workshop account.
8. Confirm audit logs and sync failures are observable.
9. Verify no credentials are present in Git.

## 24. Known Gaps

The following areas are deliberately boundaries or future hardening work, not silently claimed as complete:

- Bluetooth `PrinterTransport` still needs platform-specific Android/iOS implementation.
- Photo compression/upload queue and Storage metadata UI are not yet complete.
- Invoice void/reversal workflow needs a dedicated callable function.
- Cloud Functions report queries need emulator/integration coverage and production index verification.
- The current local adapter uses `sqflite`; migrating to Drift would improve typed schema generation and migration tooling.
- Customer/vehicle, job card, invoice, and payment workflows need broader emulator integration tests.
- Flutter and Firebase CLI runtime verification must be run on a configured machine or CI.

## 25. Reference Documents

- [README.md](README.md): quick start and current phase summary
- [ARCHITECTURE.md](ARCHITECTURE.md): architecture decisions
- [DATABASE.md](DATABASE.md): Firestore and local schema proposal
- [DATABASE_MIGRATIONS.md](DATABASE_MIGRATIONS.md): local migration rules
- [RBAC.md](RBAC.md): role matrix and authorization contract
- [SECURITY.md](SECURITY.md): security baseline and hardening
- [SYNC.md](SYNC.md): offline synchronization behavior
- [TESTING.md](TESTING.md): test commands and emulator scenarios
- [DEPLOYMENT.md](DEPLOYMENT.md): environment and deployment checklist
