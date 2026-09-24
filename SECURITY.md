# Security Baseline

- Firebase Auth custom claims are authoritative for `shopId`, role, and permissions.
- The app blocks accounts that are inactive, lack a valid role, or lack a workshop claim (except `SUPER_ADMIN`).
- Login errors are translated into user-safe messages; raw Firebase exceptions are not shown in the UI.
- Clients cannot assign roles, create shops, change claims, or choose another tenant.
- Firestore and Storage rules must require authentication and enforce tenant ownership.
- Financial totals, warranty expiry, inventory changes, and payment state are validated by trusted backend code.
- Audit logs are append-only to ordinary clients.
- Secrets, service-account credentials, and production configuration are excluded from the Flutter app.
- The Phase 2 security implementation must include emulator tests for cross-tenant reads and writes.

## Phase 2 claim contract

Staff tokens must contain:

```json
{
	"shopId": "SHOP_001",
	"role": "FRONT_DESK",
	"permissions": ["customers.read"],
	"isActive": true
}
```

Claims are assigned only by a trusted administrative backend. After a role or workshop change, force a token refresh before the new authorization takes effect.

Inventory stock and warranty expiry are protected business values. Clients cannot write inventory movement records, inventory quantities, or warranty records directly; callable backend functions validate tenant, role, quantities, completed-job state, and dates.

Invoices and payments are also server-owned. Clients can read tenant invoices/payments, but cannot create, edit, void, or delete them directly. Callable functions validate item amounts, prevent negative totals and overpayments, and update payment status transactionally.

Phase 13 hardening adds an `isActive == true` check to trusted callable functions and tenant rules. Sensitive server operations write append-only audit records with actor, action, entity, and before/after context. Storage paths are tenant-scoped and restricted by content type and maximum size.
