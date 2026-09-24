# Deployment

## Prerequisites

- Flutter stable matching the CI version
- Node.js 20
- Firebase CLI
- A Firebase project for the selected environment
- FlutterFire configuration generated for Android and iOS

## Development

```bash
flutterfire configure
flutter pub get
firebase emulators:start
flutter run
```

The emulator UI is available at `http://127.0.0.1:4000`.

## Functions and rules

```bash
cd functions
npm ci
npm run build
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

Deploy from a service account or CI identity with least-privilege Firebase roles. Never commit `google-services.json`, `GoogleService-Info.plist`, service account keys, or production secrets.

## Environments

Use separate Firebase projects for development, staging, and production. Run `flutterfire configure` once per environment and keep generated platform configuration outside the wrong environment. Verify the active Firebase project before every deploy.

## Production checklist

- Confirm Firebase Auth claims contain `shopId`, `role`, `permissions`, and `isActive`.
- Deploy and review Firestore and Storage rules.
- Verify all required indexes are deployed.
- Enable App Check and Crashlytics before production rollout.
- Configure Firestore backups/export and retention.
- Run the emulator tests and Flutter test suite in CI.
- Perform a staged rollout with a test workshop account.
- Confirm audit logs and sync failures are observable.
- Verify no production credentials are present in the repository.
