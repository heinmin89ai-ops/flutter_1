// Runs firestore.rules against the local Firebase emulator and prints, for
// every read path the app uses, whether the backend allows it. Nothing here
// touches the real project, so a rule can be checked in seconds instead of a
// deploy round trip.
//
//   npm --prefix firestore-tests test
//
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const OWNER = 'ajp6fza6SBPzN5hT1NCEUkpqDIp2';
const STAFF = 'staff0000000000000000000000000001';
const OUTSIDER = 'other0000000000000000000000000001';
// The account a freshly activated staff member signs in as. It has no profile
// document yet and no claims beyond its address, exactly like the real thing.
const NEWHIRE = 'brandnew000000000000000000000001';
const FREELONDER = 'freelond000000000000000000000001';
// The two staff roles the job-card state machine treats differently: a mechanic
// may only touch cards assigned to it, front desk only closes picked-up work.
const MECHANIC = 'mechanic000000000000000000000001';
const FRONT_DESK = 'frontdes000000000000000000000001';
const MECH2 = 'mechtwo00000000000000000000000001';
const SLEEPER = 'sleeper0000000000000000000000001';
// The platform account adminCreateShop used to require. Its privileges live in
// its profile document like everyone else's.
const ADMIN = 'platform0000000000000000000000001';
const SHOP = 'L7fYbjcaZAnVCN98MA01';
const OTHER_SHOP = 'Othershop00000000000000000001';

const env = await initializeTestEnvironment({
  projectId: 'test-96eab',
  firestore: {
    rules: readFileSync(path.join(here, '..', 'firestore.rules'), 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

const profile = (uid, email, role, shopId) => ({
  uid,
  email,
  name: role,
  role,
  shopId,
  permissions: [],
  isActive: true,
  createdAt: new Date(),
});

await env.withSecurityRulesDisabled(async (context) => {
  const store = context.firestore();
  await setDoc(doc(store, 'shops', SHOP), {
    shopId: SHOP,
    code: 'MAIN',
    name: 'Main Workshop',
    currency: 'MMK',
    timezone: 'Asia/Yangon',
    isActive: true,
  });
  await setDoc(doc(store, 'shops', OTHER_SHOP), {
    shopId: OTHER_SHOP,
    code: 'OTHER',
    name: 'Other Workshop',
    currency: 'MMK',
    timezone: 'Asia/Yangon',
    isActive: true,
  });
  await setDoc(doc(store, 'users', OWNER), profile(OWNER, 'owner@workshopops.test', 'SHOP_OWNER', SHOP));
  await setDoc(doc(store, 'users', STAFF), profile(STAFF, 'staff@workshopops.test', 'MANAGER', SHOP));
  await setDoc(doc(store, 'users', MECHANIC), profile(MECHANIC, 'mech@workshopops.test', 'MECHANIC', SHOP));
  await setDoc(doc(store, 'users', MECH2), profile(MECH2, 'mech2@workshopops.test', 'MECHANIC', SHOP));
  await setDoc(doc(store, 'users', SLEEPER), { ...profile(SLEEPER, 'sleeper@workshopops.test', 'MECHANIC', SHOP), isActive: false });
  await setDoc(doc(store, 'users', ADMIN), profile(ADMIN, 'admin@workshopops.test', 'SUPER_ADMIN', SHOP));
  await setDoc(doc(store, 'users', FRONT_DESK), profile(FRONT_DESK, 'front@workshopops.test', 'FRONT_DESK', SHOP));
  await setDoc(doc(store, 'users', OUTSIDER), profile(OUTSIDER, 'other@example.test', 'SHOP_OWNER', OTHER_SHOP));
  await setDoc(doc(store, 'vehicles', 'V1'), {
    shopId: SHOP,
    normalizedLicensePlate: 'YGN-1',
    plate: 'YGN-1',
    customerId: 'C1',
  });
  await setDoc(doc(store, 'jobCards', 'J1'), {
    shopId: SHOP,
    jobNumber: 'JC-1',
    status: 'DRAFT',
    createdBy: OWNER,
    customerId: 'C1',
    vehicleId: 'V1',
    assignedMechanicIds: [],
    repairNotes: null,
    diagnosis: null,
  });
  // One card per state the transition matrix cares about, plus an unassigned
  // card and a card that belongs to another workshop.
  const card = (id, status, extra = {}) => ({
    shopId: SHOP,
    jobNumber: `JC-${id}`,
    status,
    createdBy: OWNER,
    customerId: 'C1',
    vehicleId: 'V1',
    assignedMechanicIds: [MECHANIC],
    ...extra,
  });
  await setDoc(doc(store, 'jobCards', 'JO'), card('JO', 'OPEN'));
  await setDoc(doc(store, 'jobCards', 'JU'), card('JU', 'OPEN', { assignedMechanicIds: [] }));
  await setDoc(doc(store, 'jobCards', 'JA'), card('JA', 'ASSIGNED'));
  await setDoc(doc(store, 'jobCards', 'JIP'), card('JIP', 'IN_PROGRESS'));
  await setDoc(doc(store, 'jobCards', 'JWA'), card('JWA', 'WAITING_FOR_APPROVAL'));
  await setDoc(doc(store, 'jobCards', 'JDO'), card('JDO', 'COMPLETED'));
  await setDoc(doc(store, 'jobCards', 'JR'), card('JR', 'READY_FOR_PICKUP'));
  await setDoc(doc(store, 'jobCards', 'JCL'), card('JCL', 'CLOSED'));
  await setDoc(doc(store, 'jobCards', 'JX'), card('JX', 'DRAFT', { shopId: OTHER_SHOP, assignedMechanicIds: [] }));
  await setDoc(doc(store, 'jobCards', 'JN'), card('JN', 'DRAFT', { assignedMechanicIds: [] }));
  await setDoc(doc(store, 'jobCards', 'JZ'), card('JZ', 'ASSIGNED', { assignedMechanicIds: [] }));
  // One OPEN card per assignment test, so a rejected write never leaves a card
  // in a state that changes the outcome of the next row.
  for (const id of ['OA1', 'OA2', 'OA3', 'OA4', 'OA5']) {
    await setDoc(doc(store, 'jobCards', id), card(id, 'OPEN', { assignedMechanicIds: [] }));
  }
  await setDoc(doc(store, 'staffInvitations', 'CODE1'), {
    shopId: SHOP,
    email: 'staff@workshopops.test',
    name: 'MANAGER',
    role: 'MANAGER',
    status: 'PENDING',
    createdBy: OWNER,
  });
  // One invoice per ledger state the payment rules judge, plus a voided one
  // and one that belongs to another workshop.
  const line = { type: 'LABOR', description: 'Labour', quantity: 1, unitPriceMinorUnits: 20000, discountMinorUnits: 0, taxMinorUnits: 0, totalMinorUnits: 20000 };
  const invoice = (id, status, paid, shop = SHOP, extra = {}) => ({
    shopId: shop,
    invoiceNumber: `INV-${id}`,
    jobCardId: 'JA',
    customerId: 'C1',
    vehicleId: 'V1',
    items: [line],
    subtotalMinorUnits: 20000,
    discountMinorUnits: 0,
    taxMinorUnits: 0,
    totalMinorUnits: 20000,
    amountPaidMinorUnits: paid,
    balanceMinorUnits: 20000 - paid,
    status,
    createdBy: OWNER,
    ...extra,
  });
  await setDoc(doc(store, 'invoices', 'IVA'), invoice('IVA', 'ISSUED', 0));
  await setDoc(doc(store, 'invoices', 'IVB'), { ...invoice('IVB', 'PARTIALLY_PAID', 5000), subtotalMinorUnits: 25000, discountMinorUnits: 5000 });
  await setDoc(doc(store, 'invoices', 'IVC'), invoice('IVC', 'PAID', 20000));
  await setDoc(doc(store, 'invoices', 'IVV'), invoice('IVV', 'VOID', 0));
  await setDoc(doc(store, 'invoices', 'IVX'), invoice('IVX', 'ISSUED', 0, OTHER_SHOP));
  // One unpaid invoice per ledger row below, so a rejected write never changes
  // the state the next row is judged against.
  for (const id of ['UA', 'UB', 'UC', 'UD', 'UE', 'UF', 'UG', 'UH', 'UI', 'UJ', 'UK', 'UL', 'UM']) {
    await setDoc(doc(store, 'invoices', id), invoice(id, 'ISSUED', 0));
  }
  await setDoc(doc(store, 'payments', 'P1'), {
    shopId: SHOP,
    invoiceId: 'IVA',
    amountMinorUnits: 5000,
    method: 'CASH',
    reference: 'drawer',
    receivedBy: OWNER,
  });
  await setDoc(doc(store, 'inventoryItems', 'ITEM1'), {
    shopId: SHOP,
    sku: 'OIL-1',
    name: 'Oil filter',
    quantityOnHand: 2,
    minimumStock: 4,
    isActive: true,
  });
  // A warranty is judged against the job card it backs, so the harness keeps
  // one card per state the rule reads plus one in the rival workshop.
  await setDoc(doc(store, 'jobCards', 'JWC'), card('JWC', 'COMPLETED'));
  await setDoc(doc(store, 'jobCards', 'JVQ'), card('JVQ', 'READY_FOR_PICKUP'));
  await setDoc(doc(store, 'jobCards', 'JWI'), card('JWI', 'IN_PROGRESS'));
  await setDoc(doc(store, 'jobCards', 'JWZ'), card('JWZ', 'COMPLETED', { shopId: OTHER_SHOP }));
  // One item per stock movement row, so an allowed movement never changes the
  // shelf figure the next row is judged against.
  for (const id of ['MV01', 'MV02', 'MV03', 'MV04', 'MV05', 'MV06', 'MV07', 'MV08', 'MV09']) {
    await setDoc(doc(store, 'inventoryItems', id), {
      shopId: SHOP,
      inventoryItemId: id,
      sku: `SKU-${id}`,
      name: `Part ${id}`,
      quantityOnHand: 5,
      minimumStock: 2,
      isActive: true,
    });
  }
  await setDoc(doc(store, 'inventoryItems', 'MVO'), {
    shopId: OTHER_SHOP,
    inventoryItemId: 'MVO',
    sku: 'SKU-O',
    name: 'Rival part',
    quantityOnHand: 5,
    minimumStock: 2,
    isActive: true,
  });
  const warranty = (id, shop, jobCardId, extra = {}) => ({
    shopId: shop,
    jobCardId,
    customerId: 'C1',
    vehicleId: 'V1',
    terms: 'Parts and labour',
    durationMonths: 6,
    status: 'ACTIVE',
    createdBy: shop === SHOP ? OWNER : OUTSIDER,
    startDate: new Date('2026-01-10'),
    expiryDate: new Date('2026-07-10'),
    ...extra,
  });
  await setDoc(doc(store, 'warranties', 'W1'), warranty('W1', SHOP, 'JWC'));
  await setDoc(doc(store, 'warranties', 'WX'), warranty('WX', OTHER_SHOP, 'JWZ'));
});

// The owner's account still carries the claims the one-off Admin SDK script
// wrote; new staff accounts have none, so both shapes are exercised.
const owner = env.authenticatedContext(OWNER, { role: 'SHOP_OWNER', shopId: SHOP, isActive: true, email: 'owner@workshopops.test', name: 'Shop Owner' });
const staff = env.authenticatedContext(STAFF, { email: 'staff@workshopops.test' });
const outsider = env.authenticatedContext(OUTSIDER, { role: 'SHOP_OWNER', shopId: OTHER_SHOP, isActive: true, email: 'other@example.test' });
const newhire = env.authenticatedContext(NEWHIRE, { email: 'new@workshopops.test' });
const freelonder = env.authenticatedContext(FREELONDER, { email: 'nobody@example.test' });
const mechanic = env.authenticatedContext(MECHANIC, { email: 'mech@workshopops.test' });
const frontDesk = env.authenticatedContext(FRONT_DESK, { email: 'front@workshopops.test' });
const admin = env.authenticatedContext(ADMIN, { email: 'admin@workshopops.test' });

// An account the one-off Admin SDK script granted SHOP_OWNER, but which never
// got a profile document. Copying its own claims into its own document is the
// self-heal the app relies on; reaching past those claims must stay denied.
const LEGACY = 'legacy000000000000000000000000001';
const legacy = env.authenticatedContext(LEGACY, { role: 'SHOP_OWNER', shopId: SHOP, name: 'Legacy Owner', email: 'legacy@workshopops.test' });
const legacyDb = legacy.firestore();

const results = [];

async function check(who, label, expect, operation) {
  let outcome;
  let detail = '';
  try {
    await operation();
    outcome = 'ALLOW';
  } catch (error) {
    const code = error?.code ?? 'unknown';
    outcome = code === 'permission-denied' ? 'DENY' : `ERROR(${code})`;
    detail = String(error?.message ?? error).replace(/\s+/g, ' ').trim();
  }
  results.push({ who, label, expect, outcome, detail, ok: outcome === expect });
}

const listVehicles = (db) => getDocs(query(collection(db, 'vehicles'), where('shopId', '==', SHOP)));
const toStatus = (db, id, status, extra = {}) =>
  updateDoc(doc(db, 'jobCards', id), { status, updatedAt: new Date(), ...extra });
const toNotes = (db, id, extra = {}) =>
  updateDoc(doc(db, 'jobCards', id), { repairNotes: 'Replaced the gasket', diagnosis: 'Leak', updatedAt: new Date(), ...extra });
const shopDb = { owner: owner.firestore(), staff: staff.firestore(), outsider: outsider.firestore() };
const newhireDb = newhire.firestore();
const freelonderDb = freelonder.firestore();

for (const [who, db] of Object.entries(shopDb)) {
  await check(who, 'get users/<owner profile>', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDoc(doc(db, 'users', OWNER)));
  await check(who, 'get shops/<shop>', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDoc(doc(db, 'shops', SHOP)));
  await check(who, 'get vehicles/V1', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDoc(doc(db, 'vehicles', 'V1')));
  await check(who, 'LIST vehicles where shopId==<shop>', who === 'outsider' ? 'DENY' : 'ALLOW', () => listVehicles(db));
  await check(who, 'LIST users where shopId==<shop>', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'users'), where('shopId', '==', SHOP))));
  await check(who, 'LIST jobCards where shopId==<shop>', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'jobCards'), where('shopId', '==', SHOP))));
  await check(who, 'LIST staffInvitations', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'staffInvitations'), where('shopId', '==', SHOP))));
  await check(who, 'LIST inventoryMovements', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'inventoryMovements'), where('shopId', '==', SHOP))));
  // The Reports screen reads these three in one pass to build its summary.
  await check(who, 'LIST invoices', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'invoices'), where('shopId', '==', SHOP))));
  await check(who, 'LIST inventoryItems', who === 'outsider' ? 'DENY' : 'ALLOW', () => getDocs(query(collection(db, 'inventoryItems'), where('shopId', '==', SHOP))));
}

await check('owner', 'create jobCard DRAFT', 'ALLOW', () =>
  setDoc(doc(shopDb.owner, 'jobCards', 'J2'), { shopId: SHOP, jobNumber: 'JC-2', status: 'DRAFT', createdBy: OWNER }));
await check('legacy', 'bootstrap a role the claims never granted', 'DENY', () =>
  setDoc(doc(legacyDb, 'users', LEGACY), {
    uid: LEGACY,
    email: 'legacy@workshopops.test',
    name: 'Super',
    role: 'SUPER_ADMIN',
    shopId: SHOP,
    permissions: [],
    isActive: true,
  }));
await check('freelonder', 'hand itself a role with no invitation', 'DENY', () =>
  setDoc(doc(freelonderDb, 'users', FREELONDER), {
    uid: FREELONDER,
    email: 'nobody@example.test',
    name: 'Manager',
    role: 'SHOP_OWNER',
    shopId: SHOP,
    permissions: [],
    isActive: true,
  }));
// The status machine transitionJobCard used to enforce server-side, now that
// no callable can be deployed on the free plan. Each row is one write the app
// really makes, judged by the role and the card it is acting on.
const mechDb = mechanic.firestore();
const frontDb = frontDesk.firestore();

await check('owner', 'DRAFT -> OPEN', 'ALLOW', () => toStatus(shopDb.owner, 'J1', 'OPEN'));
await check('mechanic', 'DRAFT -> OPEN', 'DENY', () => toStatus(mechDb, 'J1', 'OPEN'));
await check('owner', 'DRAFT -> COMPLETED (no such move)', 'DENY', () => toStatus(shopDb.owner, 'JN', 'COMPLETED'));
await check('manager', 'OPEN -> ASSIGNED with the mechanic', 'ALLOW', () =>
  toStatus(shopDb.staff, 'JU', 'ASSIGNED', { assignedMechanicIds: [MECHANIC] }));
await check('manager', 'assign a two-person crew (unsupported)', 'DENY', () =>
  toStatus(shopDb.staff, 'OA1', 'ASSIGNED', { assignedMechanicIds: [MECHANIC, MECH2] }));
await check('manager', 'assign a front desk worker', 'DENY', () =>
  toStatus(shopDb.staff, 'OA2', 'ASSIGNED', { assignedMechanicIds: [FRONT_DESK] }));
await check('manager', 'assign a uid that has no account', 'DENY', () =>
  toStatus(shopDb.staff, 'OA3', 'ASSIGNED', { assignedMechanicIds: ['ghost0000000000000000000000000001'] }));
await check('manager', 'assign a deactivated mechanic', 'DENY', () =>
  toStatus(shopDb.staff, 'OA4', 'ASSIGNED', { assignedMechanicIds: [SLEEPER] }));
await check('owner', 'assign a mechanic from the rival shop', 'DENY', () =>
  toStatus(shopDb.owner, 'OA5', 'ASSIGNED', { assignedMechanicIds: [OUTSIDER] }));
await check('mechanic', 'ASSIGNED -> IN_PROGRESS on own card', 'ALLOW', () => toStatus(mechDb, 'JA', 'IN_PROGRESS'));
await check('mechanic', 'ASSIGNED -> IN_PROGRESS, not assigned', 'DENY', () => toStatus(mechDb, 'JZ', 'IN_PROGRESS'));
await check('mechanic', 'IN_PROGRESS -> COMPLETED', 'ALLOW', () => toStatus(mechDb, 'JIP', 'COMPLETED'));
await check('mechanic', 'COMPLETED -> READY_FOR_PICKUP', 'DENY', () => toStatus(mechDb, 'JDO', 'READY_FOR_PICKUP'));
await check('manager', 'WAITING_FOR_APPROVAL -> COMPLETED', 'ALLOW', () => toStatus(shopDb.staff, 'JWA', 'COMPLETED'));
await check('front desk', 'READY_FOR_PICKUP -> CLOSED', 'ALLOW', () => toStatus(frontDb, 'JR', 'CLOSED'));
await check('front desk', 'COMPLETED -> READY_FOR_PICKUP', 'DENY', () => toStatus(frontDb, 'JDO', 'READY_FOR_PICKUP'));
await check('owner', 'cancel an open card', 'ALLOW', () => toStatus(shopDb.owner, 'JN', 'CANCELLED'));
await check('mechanic', 'cancel a card', 'DENY', () => toStatus(mechDb, 'JA', 'CANCELLED'));
await check('owner', 'cancel a closed card', 'DENY', () => toStatus(shopDb.owner, 'JCL', 'CANCELLED'));
await check('outsider', 'transition a card in the other shop', 'ALLOW', () => toStatus(shopDb.outsider, 'JX', 'OPEN'));
await check('outsider', 'transition a card in this shop', 'DENY', () => toStatus(shopDb.outsider, 'JA', 'IN_PROGRESS'));
await check('mechanic', 'write work notes on own card', 'ALLOW', () => toNotes(mechDb, 'JA'));
await check('mechanic', 'write work notes, not assigned', 'DENY', () => toNotes(mechDb, 'JZ'));
await check('front desk', 'write work notes', 'DENY', () => toNotes(frontDb, 'JA'));
await check('manager', 'write work notes', 'ALLOW', () => toNotes(shopDb.staff, 'JA'));
await check('mechanic', 'move status and notes together', 'DENY', () =>
  updateDoc(doc(mechDb, 'jobCards', 'JA'), { status: 'COMPLETED', repairNotes: 'sneak', updatedAt: new Date() }));
await check('mechanic', 're-point the card at another shop', 'DENY', () =>
  updateDoc(doc(mechDb, 'jobCards', 'JA'), { shopId: OTHER_SHOP, status: 'COMPLETED', updatedAt: new Date() }));
await check('mechanic', 'rewrite job number', 'DENY', () =>
  updateDoc(doc(mechDb, 'jobCards', 'JA'), { jobNumber: 'JC-HACK' }));
await check('mechanic', 'assign itself while advancing', 'DENY', () =>
  updateDoc(doc(mechDb, 'jobCards', 'JZ'), { status: 'IN_PROGRESS', assignedMechanicIds: [MECHANIC], updatedAt: new Date() }));
await check('mechanic', 'add a second mechanic while advancing', 'DENY', () =>
  updateDoc(doc(mechDb, 'jobCards', 'JA'), { status: 'IN_PROGRESS', assignedMechanicIds: [MECHANIC, OUTSIDER], updatedAt: new Date() }));
await check('owner', 'edit a vehicle', 'ALLOW', () => updateDoc(doc(shopDb.owner, 'vehicles', 'V1'), { note: 'x' }));
await check('owner', 'create staffInvitation', 'ALLOW', () =>
  setDoc(doc(shopDb.owner, 'staffInvitations', 'CODE2'), { shopId: SHOP, email: 'new@workshopops.test', name: 'Mechanic', role: 'MECHANIC', status: 'PENDING', createdBy: OWNER }));
// The invited address writes its own document, copying the shop, role and name
// the owner put on the invitation -- the exact sequence the Activate screen
// runs through after createUserWithEmailAndPassword.
await check('newhire', 'read the invitation before activating', 'ALLOW', () =>
  getDoc(doc(newhireDb, 'staffInvitations', 'CODE2')));
await check('newhire', 'claim a role the invitation did not grant', 'DENY', () =>
  setDoc(doc(newhireDb, 'users', NEWHIRE), {
    uid: NEWHIRE,
    email: 'new@workshopops.test',
    name: 'Mechanic',
    role: 'SHOP_OWNER',
    shopId: SHOP,
    permissions: [],
    isActive: true,
    invitationId: 'CODE2',
  }));
await check('newhire', 'grant itself extra permissions', 'DENY', () =>
  setDoc(doc(newhireDb, 'users', NEWHIRE), {
    uid: NEWHIRE,
    email: 'new@workshopops.test',
    name: 'Mechanic',
    role: 'MECHANIC',
    shopId: SHOP,
    permissions: ['billing'],
    isActive: true,
    invitationId: 'CODE2',
  }));
await check('newhire', 'create own profile from invitation', 'ALLOW', () =>
  setDoc(doc(newhireDb, 'users', NEWHIRE), {
    uid: NEWHIRE,
    email: 'new@workshopops.test',
    name: 'Mechanic',
    role: 'MECHANIC',
    shopId: SHOP,
    permissions: [],
    isActive: true,
    invitationId: 'CODE2',
  }));
await check('newhire', 'mark its invitation claimed', 'ALLOW', () =>
  updateDoc(doc(newhireDb, 'staffInvitations', 'CODE2'), { status: 'CLAIMED' }));
// The profile write is what makes the account a member, so the very next query
// the app opens after activation has to be served.
await check('newhire', 'LIST vehicles after activation', 'ALLOW', () =>
  getDocs(query(collection(newhireDb, 'vehicles'), where('shopId', '==', SHOP))));
// An account the one-off Admin SDK script granted SHOP_OWNER, but which never
// got a profile document. Copying its own claims into its own document is the
// self-heal the app relies on; reaching past those claims must stay denied.
await check('legacy', 'bootstrap own profile from claims', 'ALLOW', () =>
  setDoc(doc(legacyDb, 'users', LEGACY), {
    uid: LEGACY,
    email: 'legacy@workshopops.test',
    name: 'Legacy Owner',
    role: 'SHOP_OWNER',
    shopId: SHOP,
    permissions: [],
    isActive: true,
  }));
await check('outsider', 'create profile for someone else', 'DENY', () =>
  setDoc(doc(shopDb.outsider, 'users', STAFF), { uid: STAFF, email: 'x@x.test', role: 'SUPER_ADMIN', shopId: SHOP, isActive: true, permissions: [] }));

await check('outsider', 'create profile for someone else', 'DENY', () =>
  setDoc(doc(shopDb.outsider, 'users', STAFF), { uid: STAFF, email: 'x@x.test', role: 'SUPER_ADMIN', shopId: SHOP, isActive: true, permissions: [] }));

// createInvoice and receivePayment used to be Cloud Functions. On the free
// plan nothing can be deployed, so the same money invariants are judged here:
// the ledger arithmetic, who may move it, and what a paid invoice forbids.
const INVOICE = {
  shopId: SHOP,
  jobCardId: 'JA',
  customerId: 'C1',
  vehicleId: 'V1',
  items: [{ type: 'LABOR', description: 'Labour', quantity: 1, unitPriceMinorUnits: 20000, discountMinorUnits: 0, taxMinorUnits: 0, totalMinorUnits: 20000 }],
  subtotalMinorUnits: 20000,
  discountMinorUnits: 0,
  taxMinorUnits: 0,
  totalMinorUnits: 20000,
  amountPaidMinorUnits: 0,
  balanceMinorUnits: 20000,
  status: 'ISSUED',
  createdBy: OWNER,
};
const PAYMENT = {
  shopId: SHOP,
  invoiceId: 'IVA',
  amountMinorUnits: 20000,
  method: 'CASH',
  reference: '',
  receivedBy: OWNER,
};
let invoiceSeq = 0;
const addInvoice = (db, extra = {}) =>
  setDoc(doc(db, 'invoices', `NEW${++invoiceSeq}`), { ...INVOICE, invoiceNumber: `INV-NEW${invoiceSeq}`, ...extra });
const pay = (db, id, paid, balance, status) =>
  updateDoc(doc(db, 'invoices', id), { amountPaidMinorUnits: paid, balanceMinorUnits: balance, status, updatedAt: new Date() });
let paymentSeq = 0;
const addPayment = (db, extra = {}) =>
  setDoc(doc(db, 'payments', `NEWP${++paymentSeq}`), { ...PAYMENT, ...extra });

await check('owner', 'issue an invoice', 'ALLOW', () => addInvoice(shopDb.owner));
await check('front desk', 'issue an invoice', 'ALLOW', () => addInvoice(frontDb, { createdBy: FRONT_DESK }));
await check('outsider', 'issue an invoice in its own shop', 'ALLOW', () =>
  addInvoice(shopDb.outsider, { shopId: OTHER_SHOP, jobCardId: 'JX', createdBy: OUTSIDER }));
await check('mechanic', 'issue an invoice', 'DENY', () => addInvoice(mechDb, { createdBy: MECHANIC }));
await check('outsider', 'issue an invoice into this shop', 'DENY', () => addInvoice(shopDb.outsider, { createdBy: OUTSIDER }));
await check('owner', 'issue an invoice whose totals do not add up', 'DENY', () =>
  addInvoice(shopDb.owner, { subtotalMinorUnits: 21000 }));
await check('owner', 'issue an invoice with a negative total', 'DENY', () =>
  addInvoice(shopDb.owner, { discountMinorUnits: 25000, totalMinorUnits: -5000, balanceMinorUnits: -5000 }));
await check('owner', 'issue an invoice with the balance already short', 'DENY', () =>
  addInvoice(shopDb.owner, { balanceMinorUnits: 19000 }));
await check('owner', 'issue an invoice that arrives paid', 'DENY', () => addInvoice(shopDb.owner, { status: 'PAID' }));
await check('owner', 'issue an invoice with nothing on it', 'DENY', () => addInvoice(shopDb.owner, { items: [] }));
await check('owner', 'issue an invoice against the rival shop card', 'DENY', () =>
  addInvoice(shopDb.owner, { jobCardId: 'JX' }));
await check('owner', 'issue an invoice against a card that does not exist', 'DENY', () =>
  addInvoice(shopDb.owner, { jobCardId: 'NOPE' }));
await check('owner', 'issue an invoice signed as somebody else', 'DENY', () =>
  addInvoice(shopDb.owner, { createdBy: STAFF }));

await check('owner', 'part-pay an issued invoice', 'ALLOW', () => pay(shopDb.owner, 'UA', 5000, 15000, 'PARTIALLY_PAID'));
await check('manager', 'settle an invoice in full', 'ALLOW', () => pay(shopDb.staff, 'UB', 20000, 0, 'PAID'));
await check('front desk', 'part-pay an invoice', 'ALLOW', () => pay(frontDb, 'UC', 1000, 19000, 'PARTIALLY_PAID'));
await check('owner', 'pay more than the total', 'DENY', () => pay(shopDb.owner, 'UD', 20001, -1, 'PAID'));
await check('owner', 'pay but leave the status issued', 'DENY', () => pay(shopDb.owner, 'UE', 5000, 15000, 'ISSUED'));
await check('owner', 'pay with a balance that does not match', 'DENY', () => pay(shopDb.owner, 'UF', 5000, 16000, 'PARTIALLY_PAID'));
await check('owner', 'pay part and call it paid', 'DENY', () => pay(shopDb.owner, 'UG', 5000, 15000, 'PAID'));
await check('owner', 'record a negative payment', 'DENY', () => pay(shopDb.owner, 'UH', -5000, 25000, 'PARTIALLY_PAID'));
await check('owner', 'take money back out of a partially paid invoice', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'invoices', 'IVB'), { amountPaidMinorUnits: 1000, balanceMinorUnits: 19000, status: 'PARTIALLY_PAID', updatedAt: new Date() }));
await check('owner', 'edit a paid invoice', 'DENY', () => pay(shopDb.owner, 'IVC', 21000, -1000, 'PAID'));
await check('owner', 'edit a voided invoice', 'DENY', () => pay(shopDb.owner, 'IVV', 5000, 15000, 'PARTIALLY_PAID'));
await check('manager', 'void an invoice by editing it', 'DENY', () => pay(shopDb.staff, 'UI', 0, 0, 'VOID'));
await check('owner', 'wipe the total to clear a debt', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'invoices', 'UJ'), { totalMinorUnits: 0, balanceMinorUnits: 0, status: 'PAID', amountPaidMinorUnits: 20000, updatedAt: new Date() }));
await check('owner', 'rewrite the lines of an issued invoice', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'invoices', 'UK'), { items: [{ type: 'LABOR', description: 'Nothing', quantity: 1, unitPriceMinorUnits: 1, discountMinorUnits: 0, taxMinorUnits: 0, totalMinorUnits: 1 }], updatedAt: new Date() }));
await check('owner', 'move an invoice to another shop', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'invoices', 'UL'), { shopId: OTHER_SHOP, amountPaidMinorUnits: 5000, balanceMinorUnits: 15000, status: 'PARTIALLY_PAID', updatedAt: new Date() }));
await check('mechanic', 'part-pay an invoice', 'DENY', () => pay(mechDb, 'UM', 5000, 15000, 'PARTIALLY_PAID'));
await check('outsider', 'part-pay an invoice in this shop', 'DENY', () => pay(shopDb.outsider, 'UA', 5000, 15000, 'PARTIALLY_PAID'));
await check('owner', 'delete an invoice', 'DENY', () => deleteDoc(doc(shopDb.owner, 'invoices', 'IVA')));

await check('owner', 'record a payment up to the balance', 'ALLOW', () => addPayment(shopDb.owner, { amountMinorUnits: 20000 }));
await check('front desk', 'record a card payment', 'ALLOW', () => addPayment(frontDb, { amountMinorUnits: 100, method: 'CARD', reference: 'terminal-9', receivedBy: FRONT_DESK }));
await check('owner', 'record a payment beyond the balance', 'DENY', () => addPayment(shopDb.owner, { amountMinorUnits: 20001 }));
await check('owner', 'record a zero payment', 'DENY', () => addPayment(shopDb.owner, { amountMinorUnits: 0 }));
await check('owner', 'record a negative payment', 'DENY', () => addPayment(shopDb.owner, { amountMinorUnits: -5000 }));
await check('mechanic', 'record a payment', 'DENY', () => addPayment(mechDb, { receivedBy: MECHANIC }));
await check('outsider', 'record a payment into this shop', 'DENY', () => addPayment(shopDb.outsider, { receivedBy: OUTSIDER }));
await check('owner', 'record a payment against the rival shop invoice', 'DENY', () => addPayment(shopDb.owner, { invoiceId: 'IVX' }));
await check('owner', 'record a payment against an invoice that does not exist', 'DENY', () => addPayment(shopDb.owner, { invoiceId: 'NOPE' }));
await check('owner', 'record a payment against a voided invoice', 'DENY', () => addPayment(shopDb.owner, { invoiceId: 'IVV' }));
await check('owner', 'record a payment with an unknown method', 'DENY', () => addPayment(shopDb.owner, { method: 'CRYPTO' }));
await check('owner', 'record a payment received by someone else', 'DENY', () => addPayment(shopDb.owner, { receivedBy: STAFF }));
await check('owner', 'edit a recorded payment', 'DENY', () => updateDoc(doc(shopDb.owner, 'payments', 'P1'), { amountMinorUnits: 1 }));
await check('owner', 'delete a recorded payment', 'DENY', () => deleteDoc(doc(shopDb.owner, 'payments', 'P1')));
// The app writes the invoice and its payment as one transaction; rules judge
// each document on its own, so the pair has to stand up together.
await check('owner', 'settle an invoice and its payment in one batch', 'ALLOW', async () => {
  const batch = writeBatch(shopDb.owner);
  batch.update(doc(shopDb.owner, 'invoices', 'IVA'), { amountPaidMinorUnits: 20000, balanceMinorUnits: 0, status: 'PAID', updatedAt: new Date() });
  batch.set(doc(shopDb.owner, 'payments', 'P2'), { ...PAYMENT, amountMinorUnits: 20000 });
  await batch.commit();
});

// recordInventoryMovement, createWarranty and adminCreateShop used to be Cloud
// Functions. Nothing can be deployed on the free plan, so their invariants are
// judged here instead: who may touch stock, that the shelf never goes
// negative, that a warranty backs this workshop's own finished work, and that
// only the platform account opens a workshop.
const adminDb = admin.firestore();

const MOVE = {
  shopId: SHOP,
  inventoryItemId: 'MV01',
  type: 'STOCK_IN',
  quantity: 3,
  delta: 3,
  reason: 'Supplier delivery',
  actorUid: OWNER,
};
let movementSeq = 0;
const addMovement = (db, extra = {}) =>
  setDoc(doc(db, 'inventoryMovements', `NEWM${++movementSeq}`), { ...MOVE, ...extra });

await check('owner', 'LIST inventoryMovements in this shop', 'ALLOW', () =>
  getDocs(query(collection(shopDb.owner, 'inventoryMovements'), where('shopId', '==', SHOP))));await check('outsider', 'LIST inventoryMovements in this shop', 'DENY', () =>
  getDocs(query(collection(shopDb.outsider, 'inventoryMovements'), where('shopId', '==', SHOP))));await check('owner', 'stock 3 in', 'ALLOW', () => addMovement(shopDb.owner, { inventoryItemId: 'MV01' }));
await check('manager', 'stock 2 out', 'ALLOW', () =>
  addMovement(shopDb.staff, { inventoryItemId: 'MV02', type: 'STOCK_OUT', quantity: 2, delta: -2, actorUid: STAFF }));
await check('owner', 'stock the whole shelf out', 'ALLOW', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MV03', type: 'STOCK_OUT', quantity: 5, delta: -5 }));
await check('owner', 'stock out more than is on the shelf', 'DENY', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MV04', type: 'STOCK_OUT', quantity: 6, delta: -6 }));
await check('owner', 'count the shelf down to 1 as an adjustment', 'ALLOW', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MV05', type: 'ADJUSTMENT', quantity: 1, delta: -4, reason: 'Stock count' }));
await check('owner', 'adjustment whose delta does not reach the count', 'DENY', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MV06', type: 'ADJUSTMENT', quantity: 1, delta: -1 }));
await check('manager', 'return 4 to stock', 'ALLOW', () =>
  addMovement(shopDb.staff, { inventoryItemId: 'MV07', type: 'RETURN', quantity: 4, delta: 4, actorUid: STAFF }));
await check('owner', 'stock in with the delta signed the wrong way', 'DENY', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MV08', quantity: 3, delta: -3 }));
await check('owner', 'record a movement of nothing', 'DENY', () => addMovement(shopDb.owner, { quantity: 0, delta: 0 }));
await check('owner', 'record a fractional quantity', 'DENY', () => addMovement(shopDb.owner, { quantity: 2.5, delta: 2.5 }));
await check('owner', 'record a movement with no reason', 'DENY', () => addMovement(shopDb.owner, { reason: '' }));
await check('owner', 'record an unknown movement type', 'DENY', () => addMovement(shopDb.owner, { type: 'SCRAP' }));
await check('mechanic', 'record a movement', 'DENY', () => addMovement(mechDb, { actorUid: MECHANIC }));
await check('front desk', 'record a movement', 'DENY', () => addMovement(frontDb, { actorUid: FRONT_DESK }));
await check('outsider', 'record a movement into this shop', 'DENY', () => addMovement(shopDb.outsider, { actorUid: OUTSIDER }));
await check('owner', 'record a movement on the rival shop part', 'DENY', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'MVO' }));
await check('owner', 'record a movement on a part that does not exist', 'DENY', () =>
  addMovement(shopDb.owner, { inventoryItemId: 'NOPE' }));
await check('owner', 'record a movement signed as somebody else', 'DENY', () =>
  addMovement(shopDb.owner, { actorUid: STAFF }));
await check('owner', 'edit a recorded movement', 'DENY', () => updateDoc(doc(shopDb.owner, 'inventoryMovements', 'NEWM1'), { quantity: 1 }));
await check('owner', 'delete a recorded movement', 'DENY', () => deleteDoc(doc(shopDb.owner, 'inventoryMovements', 'NEWM1')));
// The app writes the shelf figure and its ledger entry as one transaction;
// rules judge each document alone, so the pair has to stand up together.
await check('manager', 'move the shelf and write the ledger in one batch', 'ALLOW', async () => {
  const batch = writeBatch(shopDb.staff);
  batch.update(doc(shopDb.staff, 'inventoryItems', 'MV09'), { quantityOnHand: 2, updatedAt: new Date() });
  batch.set(doc(shopDb.staff, 'inventoryMovements', 'NEWM-BATCH'), {
    ...MOVE,
    inventoryItemId: 'MV09',
    type: 'STOCK_OUT',
    quantity: 3,
    delta: -3,
    actorUid: STAFF,
  });
  await batch.commit();
});

const NEWITEM = {
  shopId: SHOP,
  sku: 'BRK-1',
  name: 'Brake pads',
  category: 'Brakes',
  unit: 'set',
  quantityOnHand: 0,
  minimumStock: 2,
  costPriceMinorUnits: 18000,
  sellingPriceMinorUnits: 26000,
  isActive: true,
};
let itemSeq = 0;
const addItem = (db, extra = {}) => {
  const id = `NEWI${++itemSeq}`;
  return setDoc(doc(db, 'inventoryItems', id), { ...NEWITEM, inventoryItemId: id, ...extra });
};

await check('owner', 'add a part to stock', 'ALLOW', () => addItem(shopDb.owner));
await check('manager', 'add a part with opening stock on it', 'DENY', () =>
  addItem(shopDb.staff, { quantityOnHand: 10, inventoryItemId: 'NEWI2' }));
await check('owner', 'add a part with no sku', 'DENY', () => addItem(shopDb.owner, { sku: '' }));
await check('owner', 'add a part with no name', 'DENY', () => addItem(shopDb.owner, { name: '' }));
await check('owner', 'add a part whose id field disagrees', 'DENY', () => addItem(shopDb.owner, { inventoryItemId: 'somewhere-else' }));
await check('mechanic', 'add a part to stock', 'DENY', () => addItem(mechDb));
await check('outsider', 'add a part into this shop', 'DENY', () => addItem(shopDb.outsider));
await check('manager', 'correct the shelf figure', 'ALLOW', () =>
  updateDoc(doc(shopDb.staff, 'inventoryItems', 'ITEM1'), { quantityOnHand: 7, updatedAt: new Date() }));
await check('owner', 'rename a part', 'DENY', () => updateDoc(doc(shopDb.owner, 'inventoryItems', 'ITEM1'), { name: 'Changed' }));
await check('owner', 'set the shelf figure negative', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'inventoryItems', 'MV01'), { quantityOnHand: -1, updatedAt: new Date() }));
await check('owner', 'move a part to the rival shop', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'inventoryItems', 'MV02'), { shopId: OTHER_SHOP, quantityOnHand: 4, updatedAt: new Date() }));
await check('mechanic', 'correct the shelf figure', 'DENY', () =>
  updateDoc(doc(mechDb, 'inventoryItems', 'MV03'), { quantityOnHand: 9, updatedAt: new Date() }));
await check('owner', 'delete a part', 'DENY', () => deleteDoc(doc(shopDb.owner, 'inventoryItems', 'MV04')));

const WARRANTY = {
  shopId: SHOP,
  jobCardId: 'JWC',
  customerId: 'C1',
  vehicleId: 'V1',
  terms: 'Parts and labour on the engine rebuild',
  durationMonths: 6,
  status: 'ACTIVE',
  createdBy: OWNER,
  startDate: new Date('2026-09-29'),
  expiryDate: new Date('2027-03-29'),
};
let warrantySeq = 0;
const addWarranty = (db, extra = {}) =>
  setDoc(doc(db, 'warranties', `NEWW${++warrantySeq}`), { ...WARRANTY, ...extra });

await check('owner', 'LIST warranties in this shop', 'ALLOW', () =>
  getDocs(query(collection(shopDb.owner, 'warranties'), where('shopId', '==', SHOP))));await check('outsider', 'LIST warranties in this shop', 'DENY', () =>
  getDocs(query(collection(shopDb.outsider, 'warranties'), where('shopId', '==', SHOP))));await check('owner', 'warrant a completed job', 'ALLOW', () => addWarranty(shopDb.owner));
await check('manager', 'warrant a job waiting for pickup', 'ALLOW', () =>
  addWarranty(shopDb.staff, { jobCardId: 'JVQ', createdBy: STAFF }));
await check('owner', 'warrant a job still in progress', 'DENY', () =>
  addWarranty(shopDb.owner, { jobCardId: 'JWI' }));
await check('owner', 'warrant the rival shop job', 'DENY', () =>
  addWarranty(shopDb.owner, { jobCardId: 'JWZ' }));
await check('owner', 'warrant a job that does not exist', 'DENY', () =>
  addWarranty(shopDb.owner, { jobCardId: 'NOPE' }));
await check('owner', 'warrant for no months', 'DENY', () => addWarranty(shopDb.owner, { durationMonths: 0, expiryDate: new Date('2026-09-29') }));
await check('owner', 'warrant for more than ten years', 'DENY', () => addWarranty(shopDb.owner, { durationMonths: 121 }));
await check('owner', 'warrant with no terms written', 'DENY', () => addWarranty(shopDb.owner, { terms: '' }));
await check('owner', 'warrant with no vehicle', 'DENY', () => addWarranty(shopDb.owner, { vehicleId: '' }));
await check('owner', 'warrant that arrives voided', 'DENY', () => addWarranty(shopDb.owner, { status: 'VOIDED' }));
await check('owner', 'warrant with an expiry before its start', 'DENY', () =>
  addWarranty(shopDb.owner, { expiryDate: new Date('2026-03-29') }));
await check('owner', 'warrant signed as somebody else', 'DENY', () => addWarranty(shopDb.owner, { createdBy: STAFF }));
await check('front desk', 'warrant a job', 'DENY', () => addWarranty(frontDb, { createdBy: FRONT_DESK }));
await check('mechanic', 'warrant a job', 'DENY', () => addWarranty(mechDb, { createdBy: MECHANIC }));
await check('outsider', 'warrant into this shop', 'DENY', () => addWarranty(shopDb.outsider, { createdBy: OUTSIDER }));
await check('owner', 'extend a warranty', 'DENY', () =>
  updateDoc(doc(shopDb.owner, 'warranties', 'W1'), { durationMonths: 12 }));
await check('owner', 'delete a warranty', 'DENY', () => deleteDoc(doc(shopDb.owner, 'warranties', 'W1')));

const SHOPDOC = {
  name: 'Riverside Motors',
  code: 'RVS',
  currency: 'MMK',
  timezone: 'Asia/Yangon',
  isActive: true,
  enabledModules: ['billing', 'warranty'],
};
let shopSeq = 0;
const addShop = (db, extra = {}) => {
  const id = `NEWS${++shopSeq}`;
  return setDoc(doc(db, 'shops', id), { ...SHOPDOC, shopId: id, ...extra });
};

await check('platform admin', 'LIST every workshop', 'ALLOW', () =>
  getDocs(query(collection(adminDb, 'shops'), orderBy('name'))));await check('owner', 'LIST every workshop', 'DENY', () =>
  getDocs(query(collection(shopDb.owner, 'shops'), orderBy('name'))));await check('platform admin', 'open a workshop', 'ALLOW', () => addShop(adminDb));
await check('owner', 'open a workshop', 'DENY', () => addShop(shopDb.owner));
await check('manager', 'open a workshop', 'DENY', () => addShop(shopDb.staff));
await check('platform admin', 'open a workshop whose id field disagrees', 'DENY', () =>
  addShop(adminDb, { shopId: 'some-other-id' }));
await check('platform admin', 'open a workshop with no name', 'DENY', () => addShop(adminDb, { name: '' }));
await check('platform admin', 'open a workshop with no code', 'DENY', () => addShop(adminDb, { code: '' }));
await check('platform admin', 'open a workshop already closed down', 'DENY', () => addShop(adminDb, { isActive: false }));
await check('platform admin', 'open a workshop with no modules listed', 'DENY', () => addShop(adminDb, { enabledModules: 'billing' }));
await check('platform admin', 'delete a workshop', 'DENY', () => deleteDoc(doc(adminDb, 'shops', SHOP)));
await check('owner', 'edit its own workshop', 'ALLOW', () => updateDoc(doc(shopDb.owner, 'shops', SHOP), { phone: '+95 9 1234', updatedAt: new Date() }));
await check('owner', 'shut its own workshop down', 'DENY', () => updateDoc(doc(shopDb.owner, 'shops', SHOP), { isActive: false }));
await check('owner', 'edit the rival workshop', 'DENY', () => updateDoc(doc(shopDb.owner, 'shops', OTHER_SHOP), { name: 'Hijacked' }));
await check('mechanic', 'edit the workshop', 'DENY', () => updateDoc(doc(mechDb, 'shops', SHOP), { name: 'Changed by mechanic' }));

const width = (row) => `${row.who.padEnd(15)}${row.label.padEnd(52)}${row.expect.padEnd(7)}${row.outcome.padEnd(10)}${row.ok ? 'ok' : 'MISMATCH'}`;
console.log('WHO            OPERATION                                               EXPECT   RESULT');
for (const row of results) console.log(width(row));
const mismatches = results.filter((row) => !row.ok);
for (const row of mismatches) console.log(`\n${row.who} | ${row.label}\n  ${row.detail}`);
console.log(`\n${results.length - mismatches.length}/${results.length} match expectations.`);

await env.cleanup();
if (mismatches.length) process.exitCode = 1;
