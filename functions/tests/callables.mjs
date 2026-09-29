// Exercises every callable in functions/src/index.ts against the local
// Firebase emulator suite (firestore + auth + functions). Nothing here needs
// a billing plan: `firebase emulators:exec` boots the same runtime the cloud
// would use, and the script drives it over the emulator's HTTP endpoints.
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const portOf = (host, fallback) => (host ?? '').split(':').pop() || fallback;
const PROJECT = process.env.GCLOUD_PROJECT ?? 'test-96eab';
const FIRESTORE_PORT = portOf(process.env.FIRESTORE_EMULATOR_HOST, '8080');
const AUTH_PORT = portOf(process.env.FIREBASE_AUTH_EMULATOR_HOST, '9099');
const FUNCTIONS_PORT = portOf(process.env.FUNCTIONS_EMULATOR_HOST, '5001');

process.env.FIREBASE_AUTH_EMULATOR_HOST ??= `127.0.0.1:${AUTH_PORT}`;
process.env.FIRESTORE_EMULATOR_HOST ??= `127.0.0.1:${FIRESTORE_PORT}`;
initializeApp({ projectId: PROJECT });

const db = getFirestore();
const auth = getAuth();
const SHOP = 'SHOP1';
const OTHER = 'SHOP2';
const PASSWORD = 'emulator-password';

const results = [];

function record(name, expected, actual, detail) {
  const pass = expected === actual;
  results.push({ name, expected, actual, pass, detail });
  const mark = pass ? 'PASS' : 'FAIL';
  console.log(`${mark.padEnd(5)} ${name.padEnd(46)} expected=${expected.padEnd(22)} got=${actual}`);
  if (!pass && detail) console.log(`      ${detail}`);
}

async function signIn(email) {
  const body = JSON.stringify({ email, password: PASSWORD, returnSecureToken: true });
  let res = await fetch(`http://127.0.0.1:${AUTH_PORT}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  if (!res.ok) {
    res = await fetch(`http://127.0.0.1:${AUTH_PORT}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
    });
  }
  const json = await res.json();
  if (!json.idToken) throw new Error(`sign-in failed for ${email}: ${JSON.stringify(json)}`);
  return json.idToken;
}

async function call(name, token, data) {
  const res = await fetch(`http://127.0.0.1:${FUNCTIONS_PORT}/${PROJECT}/us-central1/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ data }),
  });
  const json = await res.json().catch(() => ({}));
  if (res.ok) return { ok: true, data: json.result };
  const code = json?.error?.status ?? `http-${res.status}`;
  return { ok: false, code, message: json?.error?.message ?? JSON.stringify(json) };
}

const outcome = (r) => (r.ok ? 'ALLOW' : r.code);

async function makeUser(email, claims) {
  const existing = await auth.getUserByEmail(email).catch(() => null);
  const user = existing ?? (await auth.createUser({ email, password: PASSWORD, displayName: email.split('@')[0] }));
  await auth.setCustomUserClaims(user.uid, claims);
  return user.uid;
}

async function seed() {
  await db.collection('shops').doc(SHOP).set({
    shopId: SHOP, name: 'Main Workshop', code: 'MAIN', currency: 'USD', timezone: 'UTC',
    isActive: true, enabledModules: [],
  });
  await db.collection('shops').doc(OTHER).set({
    shopId: OTHER, name: 'Rival Workshop', code: 'RIVAL', currency: 'USD', timezone: 'UTC',
    isActive: true, enabledModules: [],
  });

  const tokens = {};
  const people = {
    owner: { email: 'owner@workshopops.test', role: 'SHOP_OWNER', isActive: true },
    manager: { email: 'manager@workshopops.test', role: 'MANAGER', isActive: true },
    mechanic: { email: 'mechanic@workshopops.test', role: 'MECHANIC', isActive: true },
    front: { email: 'front@workshopops.test', role: 'FRONT_DESK', isActive: true },
    super: { email: 'super@workshopops.test', role: 'SUPER_ADMIN', isActive: true },
    outsider: { email: 'outsider@workshopops.test', role: 'SHOP_OWNER', isActive: true, shopId: OTHER },
    inactive: { email: 'inactive@workshopops.test', role: 'MECHANIC', isActive: false },
  };
  for (const [key, spec] of Object.entries(people)) {
    const claims = { shopId: spec.shopId ?? SHOP, role: spec.role, permissions: [], isActive: spec.isActive };
    const uid = await makeUser(spec.email, claims);
    await db.collection('users').doc(uid).set({
      uid, email: spec.email, name: key, ...claims,
      createdAt: new Date(), updatedAt: new Date(),
    });
    tokens[key] = { uid, token: await signIn(spec.email) };
  }

  // The client-side staff flow puts authority on the users/{uid} document and
  // cannot set ID-token claims without a paid plan. These callables read
  // request.auth.token.role, so such a member is rejected even though the
  // deployed firestore.rules accept the same member's writes.
  const claimlessEmail = 'claimless@workshopops.test';
  const claimlessUid = await makeUser(claimlessEmail, {});
  await db.collection('users').doc(claimlessUid).set({
    uid: claimlessUid, email: claimlessEmail, name: 'claimless',
    shopId: SHOP, role: 'MECHANIC', isActive: true, permissions: [],
    createdAt: new Date(), updatedAt: new Date(),
  });
  tokens.claimless = { uid: claimlessUid, token: await signIn(claimlessEmail) };

  const jobCard = (id, status, extra = {}) => ({
    jobCardId: id, shopId: SHOP, status, customerId: 'CUST1', vehicleId: 'VEH1',
    title: `Repair ${id}`, assignedMechanicIds: [], createdBy: tokens.owner.uid,
    createdAt: new Date(), ...extra,
  });
  await db.collection('jobCards').doc('JC_OPEN').set(jobCard('JC_OPEN', 'OPEN', { openedAt: new Date() }));
  await db.collection('jobCards').doc('JC_ASSIGNED').set(jobCard('JC_ASSIGNED', 'ASSIGNED', { assignedMechanicIds: [tokens.mechanic.uid] }));
  await db.collection('jobCards').doc('JC_PROGRESS').set(jobCard('JC_PROGRESS', 'IN_PROGRESS', { assignedMechanicIds: [tokens.mechanic.uid] }));
  await db.collection('jobCards').doc('JC_DONE').set(jobCard('JC_DONE', 'COMPLETED', { completedAt: new Date() }));
  await db.collection('jobCards').doc('JC_READY').set(jobCard('JC_READY', 'READY_FOR_PICKUP', { completedAt: new Date() }));
  await db.collection('jobCards').doc('JC_OTHER').set({ ...jobCard('JC_OTHER', 'OPEN'), shopId: OTHER });
  await db.collection('jobCards').doc('JC_NEW').set(jobCard('JC_NEW', 'DRAFT'));
  await db.collection('jobCards').doc('JC_BAD').set(jobCard('JC_BAD', 'DRAFT'));
  await db.collection('inventoryItems').doc('ITEM1').set({
    inventoryItemId: 'ITEM1', shopId: SHOP, name: 'Oil filter', sku: 'OF-1', unit: 'PCS',
    quantityOnHand: 5, minimumStock: 3, unitCostMinorUnits: 800, active: true,
  });
  await db.collection('customers').doc('CUST1').set({ customerId: 'CUST1', shopId: SHOP, name: 'Ko Win', phone: '09' });
  await db.collection('vehicles').doc('VEH1').set({ vehicleId: 'VEH1', shopId: SHOP, normalizedLicensePlate: 'BY1234', brand: 'Toyota' });
  return tokens;
}

const INVOICE_ITEMS = [
  { type: 'LABOUR', description: 'Engine service', quantity: 2, unitPriceMinorUnits: 15000, discountMinorUnits: 1000, taxMinorUnits: 500 },
  { type: 'PART', description: 'Oil filter', quantity: 1, unitPriceMinorUnits: 8000 },
];
const INVOICE_TOTAL = INVOICE_ITEMS.reduce(
  (sum, i) => sum + i.quantity * i.unitPriceMinorUnits - (i.discountMinorUnits ?? 0) + (i.taxMinorUnits ?? 0),
  0,
);

async function run(t) {
  // --- adminCreateShop ---------------------------------------------------
  let r = await call('adminCreateShop', t.super.token, { name: 'North Branch', code: 'north' });
  const createdShopId = r.ok ? r.data.shopId : null;
  record('super creates a workshop', 'ALLOW', outcome(r), r.message);
  r = await call('adminCreateShop', t.owner.token, { name: 'Sneaky', code: 'SNEAK' });
  record('shop owner creates a workshop', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('adminCreateShop', t.super.token, { name: 'North Branch', code: 'NORTH' });
  record('duplicate workshop code rejected', 'ALREADY_EXISTS', outcome(r), r.message);

  // --- adminCreateStaff / adminUpdateStaff -------------------------------
  r = await call('adminCreateStaff', t.owner.token, { shopId: SHOP, email: 'newtech@workshopops.test', name: 'New Tech', role: 'mechanic' });
  const createdStaffUid = r.ok ? r.data.uid : null;
  record('owner creates staff account', 'ALLOW', outcome(r), r.message);
  r = await call('adminCreateStaff', t.owner.token, { shopId: SHOP, email: 'boss@workshopops.test', name: 'Boss', role: 'SHOP_OWNER' });
  record('owner cannot create another owner', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('adminUpdateStaff', t.owner.token, { shopId: SHOP, uid: createdStaffUid, role: 'MANAGER', isActive: false });
  record('owner edits staff role/active', 'ALLOW', outcome(r), r.message);

  // --- transitionJobCard -------------------------------------------------
  r = await call('transitionJobCard', t.owner.token, { shopId: SHOP, jobCardId: 'JC_NEW', targetStatus: 'OPEN' });
  record('DRAFT -> OPEN by owner', 'ALLOW', outcome(r), r.message);
  r = await call('transitionJobCard', t.front.token, { shopId: SHOP, jobCardId: 'JC_BAD', targetStatus: 'CLOSED' });
  record('DRAFT -> CLOSED is illegal', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('transitionJobCard', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_ASSIGNED', targetStatus: 'IN_PROGRESS' });
  record('assigned mechanic starts work', 'ALLOW', outcome(r), r.message);
  r = await call('transitionJobCard', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_PROGRESS', targetStatus: 'COMPLETED' });
  record('mechanic completes in-progress job', 'ALLOW', outcome(r), r.message);
  r = await call('transitionJobCard', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_DONE', targetStatus: 'READY_FOR_PICKUP' });
  record('mechanic cannot mark ready', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('transitionJobCard', t.front.token, { shopId: SHOP, jobCardId: 'JC_READY', targetStatus: 'CLOSED' });
  record('front desk closes picked-up job', 'ALLOW', outcome(r), r.message);
  r = await call('transitionJobCard', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_BAD', targetStatus: 'IN_PROGRESS' });
  record('unassigned mechanic blocked', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('transitionJobCard', t.outsider.token, { shopId: SHOP, jobCardId: 'JC_OTHER', targetStatus: 'OPEN' });
  record('other tenant cannot touch this shop', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('transitionJobCard', t.inactive.token, { shopId: SHOP, jobCardId: 'JC_BAD', targetStatus: 'OPEN' });
  record('inactive account blocked', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('transitionJobCard', t.claimless.token, { shopId: SHOP, jobCardId: 'JC_ASSIGNED', targetStatus: 'IN_PROGRESS' });
  record('KNOWN GAP: claimless member rejected', 'PERMISSION_DENIED', outcome(r), r.message);

  // --- assignJobCard -----------------------------------------------------
  r = await call('assignJobCard', t.owner.token, { shopId: SHOP, jobCardId: 'JC_OPEN', mechanicUid: t.mechanic.uid });
  record('owner assigns open job to mechanic', 'ALLOW', outcome(r), r.message);
  r = await call('assignJobCard', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_OPEN', mechanicUid: t.mechanic.uid });
  record('mechanic cannot assign', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('assignJobCard', t.owner.token, { shopId: SHOP, jobCardId: 'JC_OPEN', mechanicUid: t.front.uid });
  record('non-mechanic target rejected', 'FAILED_PRECONDITION', outcome(r), r.message);
  r = await call('assignJobCard', t.owner.token, { shopId: SHOP, jobCardId: 'JC_DONE', mechanicUid: t.mechanic.uid });
  record('only OPEN cards are assignable', 'FAILED_PRECONDITION', outcome(r), r.message);

  // --- updateJobCardWork -------------------------------------------------
  r = await call('updateJobCardWork', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_ASSIGNED', notes: 'Replaced gasket', diagnosis: 'Head gasket leak' });
  record('mechanic writes notes + diagnosis', 'ALLOW', outcome(r), r.message);
  r = await call('updateJobCardWork', t.front.token, { shopId: SHOP, jobCardId: 'JC_ASSIGNED', notes: 'nope' });
  record('front desk cannot write work notes', 'PERMISSION_DENIED', outcome(r), r.message);

  // --- recordInventoryMovement -------------------------------------------
  r = await call('recordInventoryMovement', t.manager.token, { shopId: SHOP, inventoryItemId: 'ITEM1', type: 'stock_in', quantity: 10, reason: 'Purchase' });
  record('stock in 5 -> 15', 'ALLOW', outcome(r), r.message);
  if (r.ok) record('  quantity after stock-in = 15', '15', String(r.data.quantityOnHand));
  r = await call('recordInventoryMovement', t.manager.token, { shopId: SHOP, inventoryItemId: 'ITEM1', type: 'STOCK_OUT', quantity: 20, reason: 'Issue' });
  record('oversell blocked (negative stock)', 'FAILED_PRECONDITION', outcome(r), r.message);
  r = await call('recordInventoryMovement', t.manager.token, { shopId: SHOP, inventoryItemId: 'ITEM1', type: 'ADJUSTMENT', quantity: 7, reason: 'Count' });
  record('adjustment sets absolute count', 'ALLOW', outcome(r), r.message);
  if (r.ok) record('  quantity after adjustment = 7', '7', String(r.data.quantityOnHand));
  r = await call('recordInventoryMovement', t.mechanic.token, { shopId: SHOP, inventoryItemId: 'ITEM1', type: 'STOCK_IN', quantity: 1, reason: 'x' });
  record('mechanic cannot move stock', 'PERMISSION_DENIED', outcome(r), r.message);

  // --- createWarranty ----------------------------------------------------
  r = await call('createWarranty', t.owner.token, { shopId: SHOP, jobCardId: 'JC_DONE', vehicleId: 'VEH1', customerId: 'CUST1', durationMonths: 6, terms: 'Parts and labour' });
  record('warranty on completed job', 'ALLOW', outcome(r), r.message);
  r = await call('createWarranty', t.owner.token, { shopId: SHOP, jobCardId: 'JC_OPEN', vehicleId: 'VEH1', customerId: 'CUST1', durationMonths: 6, terms: 'x' });
  record('warranty needs completed job', 'FAILED_PRECONDITION', outcome(r), r.message);
  r = await call('createWarranty', t.owner.token, { shopId: SHOP, jobCardId: 'JC_DONE', vehicleId: 'VEH1', customerId: 'CUST1', durationMonths: 999, terms: 'x' });
  record('absurd warranty length rejected', 'INVALID_ARGUMENT', outcome(r), r.message);

  // --- createInvoice / receivePayment ------------------------------------
  r = await call('createInvoice', t.front.token, { shopId: SHOP, jobCardId: 'JC_DONE', customerId: 'CUST1', vehicleId: 'VEH1', items: INVOICE_ITEMS });
  const invoiceId = r.ok ? r.data.invoiceId : null;
  record('front desk issues invoice', 'ALLOW', outcome(r), r.message);
  if (r.ok) {
    record('  invoice total in minor units', String(INVOICE_TOTAL), String(r.data.totalMinorUnits));
    record('  invoice starts unpaid', String(INVOICE_TOTAL), String(r.data.balanceMinorUnits));
  }
  r = await call('createInvoice', t.mechanic.token, { shopId: SHOP, jobCardId: 'JC_DONE', customerId: 'CUST1', vehicleId: 'VEH1', items: INVOICE_ITEMS });
  record('mechanic cannot invoice', 'PERMISSION_DENIED', outcome(r), r.message);
  r = await call('createInvoice', t.owner.token, { shopId: SHOP, jobCardId: 'JC_DONE', customerId: 'CUST1', vehicleId: 'VEH1', items: [] });
  record('empty invoice rejected', 'INVALID_ARGUMENT', outcome(r), r.message);

  r = await call('receivePayment', t.front.token, { shopId: SHOP, invoiceId, amountMinorUnits: 10000, method: 'cash', reference: 'RR-1' });
  record('partial payment recorded', 'ALLOW', outcome(r), r.message);
  r = await call('receivePayment', t.front.token, { shopId: SHOP, invoiceId, amountMinorUnits: 99999999, method: 'CASH' });
  record('overpayment blocked', 'FAILED_PRECONDITION', outcome(r), r.message);
  r = await call('receivePayment', t.manager.token, { shopId: SHOP, invoiceId, amountMinorUnits: INVOICE_TOTAL - 10000, method: 'BANK_TRANSFER' });
  record('settles the remaining balance', 'ALLOW', outcome(r), r.message);
  const invoice = await db.collection('invoices').doc(invoiceId).get();
  record('  invoice flips to PAID', 'PAID', invoice.data()?.status);
  record('  balance closes at zero', '0', String(invoice.data()?.balanceMinorUnits));

  // --- getWorkshopReport -------------------------------------------------
  r = await call('getWorkshopReport', t.owner.token, {
    shopId: SHOP,
    from: new Date(Date.now() - 30 * 864e5).toISOString(),
    to: new Date(Date.now() + 864e5).toISOString(),
  });
  record('owner pulls 30-day report', 'ALLOW', outcome(r), r.message);
  if (r.ok) {
    record('  revenue counts the issued invoice', String(INVOICE_TOTAL), String(r.data.revenueMinorUnits));
    record('  paid equals the two receipts', String(INVOICE_TOTAL), String(r.data.paidMinorUnits));
    record('  jobs completed during the run', '2', String(r.data.completedJobs));
  }
  r = await call('getWorkshopReport', t.mechanic.token, { shopId: SHOP, from: '2026-01-01', to: '2026-12-31' });
  record('mechanic cannot read reports', 'PERMISSION_DENIED', outcome(r), r.message);

  if (createdShopId) await db.collection('shops').doc(createdShopId).delete();
}

const tokens = await seed();
try {
  await run(tokens);
} catch (error) {
  console.log(`ERROR ${error?.stack ?? error}`);
  process.exitCode = 1;
}

const failed = results.filter((x) => !x.pass);
console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
for (const f of failed) console.log(`FAILED: ${f.name} (expected ${f.expected}, got ${f.actual}) ${f.detail ?? ''}`);
if (failed.length) process.exitCode = 1;
