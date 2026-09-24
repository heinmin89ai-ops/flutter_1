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

UI visibility and route guards are convenience controls only. Repository authorization, Firestore rules, Storage rules, and trusted backend checks remain authoritative. Every tenant query must derive `shopId` from trusted claims rather than request fields.

## Phase 3 implementation

- `SUPER_ADMIN` can create workshops through the `adminCreateShop` callable function.
- `SHOP_OWNER` can list staff in their own workshop and call `adminCreateStaff` or `adminUpdateStaff`.
- A shop owner cannot assign `SUPER_ADMIN` or `SHOP_OWNER` to staff.
- Role and active-state changes update both Firebase custom claims and the staff profile through the trusted backend.
- Clients cannot write `users` documents directly.
