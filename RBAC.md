# Authorization Matrix

| Capability | Super Admin | Shop Owner | Manager | Front Desk | Mechanic |
|---|---:|---:|---:|---:|---:|
| Create shop | Yes | No | No | No | No |
| Manage staff | Platform | Own shop | No | No | No |
| Customers and vehicles | Platform | Yes | Yes | Yes | Assigned context |
| Create job card | Platform | Yes | Yes | Yes | No |
| Assign jobs | Platform | Yes | Yes | No | No |
| Update assigned repair work | No | Yes | Yes | No | Yes |
| Approve pricing | No | Yes | Yes | No | No |
| Inventory changes | No | Yes | Yes | No | No |
| Invoices and payments | No | Yes | Yes | Yes | No |
| Reports | Platform | Yes | Operational | No | No |
| Shop settings | No | Yes | Limited | No | No |

UI visibility and route guards are convenience controls only. Repository authorization, Firestore rules, Storage rules, and trusted backend checks remain authoritative. Every tenant query derives `shopId` from the signed-in user's `users/{uid}` profile, which the rules read with `get()` rather than from a request field.

## Staff accounts without a paid plan

`role`, `shopId`, and `isActive` live on the `users/{uid}` document and the rules read them from there. Firebase custom claims can only be written by the Admin SDK, so relying on them would require Cloud Functions and the Blaze plan. The ID token claims are still read as a fallback so a signed-in device can render its shell offline; the rules stay document-based, so a stale claim cannot widen real access.

- `SUPER_ADMIN` can create workshops through the `adminCreateShop` callable function.
- `SHOP_OWNER` lists staff in their own workshop, changes a staff member's role and active state directly on `users/{uid}`, and creates invitations.
- A new staff member activates their own account with an invitation code, so no client ever holds an Admin credential. The invitation, not the client, fixes the workshop and role.
- A shop owner cannot invite or promote anyone to `SUPER_ADMIN`, and nobody can edit their own privileges, which also prevents locking themselves out.
- Password changes use the client Auth SDK, and owner-initiated resets send a Firebase password reset email. Setting a staff member's password directly would still need a callable function.
- Clients cannot delete staff profiles.
