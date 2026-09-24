# Architecture

## System shape

The application uses feature-first clean architecture:

```text
Presentation -> Domain -> Data -> Local/Remote infrastructure
```

Screens read through use cases and repositories. Normal operational screens read local SQLite first. Firebase synchronization is an independent application service and is never called directly by widgets.

## Phase 1 decisions

- Flutter and Dart with Material 3.
- Immutable domain models will be introduced per feature.
- Dependency injection will be explicit at the application composition root.
- Tenant identity and role come from trusted Firebase Auth custom claims after authentication.
- The local database is an operational cache and offline queue, not the permanent source of truth.
- Money will use integer minor units, never binary floating point.
- IDs are generated locally with UUID or ULID-compatible identifiers before synchronization.
- Receipt printing depends on `ReceiptPrinter`; ESC/POS encoding is separate from Bluetooth transport.
- Sync transport is injected through `SyncOperationHandler`; financial writes do not use the generic sync handler.

## Feature boundaries

```text
lib/
  app/                 application composition, routing, theme
  core/                cross-cutting errors, sync, storage, widgets
  features/            feature-first data/domain/presentation modules
```

The initial UI intentionally exposes only the application shell. Business operations will be added phase by phase with their repository, authorization, local persistence, remote adapter, and tests together.

## Source of truth

- SQLite/Drift: immediate UI reads, local writes, cache, and pending mutations.
- Firestore: synchronized business data and cloud source of truth.
- Firebase Storage: photos and generated documents.
- Trusted backend: claims, financial validation, inventory transactions, and privileged operations.
