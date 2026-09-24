# Testing

The project uses unit tests for domain rules, widget tests for the application shell, and Firebase emulator tests for rules and callable functions.

Required commands:

```bash
flutter pub get
flutter analyze
flutter test
```

Run focused tests while iterating:

```bash
flutter test test/job_card_state_test.dart
flutter test test/money_calculation_test.dart
flutter test test/warranty_calculation_test.dart
flutter test test/receipt_encoder_test.dart
flutter test test/sync_queue_item_test.dart
```

Run Firebase rules/functions checks without touching production data:

```bash
firebase emulators:exec --only auth,firestore,functions,storage "flutter test"
```

Before an integration run, create emulator users with claims for each role and test at least:

- unauthenticated access is rejected
- inactive accounts are rejected
- cross-shop reads and writes are rejected
- mechanics cannot access financial administration
- overpayments and negative stock are rejected
- audit log writes are rejected from clients
- Storage content type and size limits are enforced

The current environment does not have the Flutter or Firebase CLI executables installed, so runtime and emulator verification must be performed in CI or on a machine with those tools installed.

The current environment does not have the Flutter executable installed, so these commands must be run after installing Flutter locally.

Phase 10/11/14 focused tests include ESC/POS receipt command encoding, sync queue idempotency data, money calculation, warranty calculation, and job-card transitions. CI also runs formatting, analysis, Flutter tests, and the Functions TypeScript build.
