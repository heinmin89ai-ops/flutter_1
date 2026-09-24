import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

const db = getFirestore();
const auth = getAuth();

type Role = 'SUPER_ADMIN' | 'SHOP_OWNER' | 'MANAGER' | 'FRONT_DESK' | 'MECHANIC';

interface CallableContext {
  auth?: {
    uid: string;
    token: Record<string, unknown>;
  };
}

function requireAuth(request: CallableContext): { uid: string; token: Record<string, unknown> } {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication is required.');
  if (request.auth.token.isActive !== true) throw new HttpsError('permission-denied', 'This account is inactive.');
  return request.auth;
}

function requireRole(request: CallableContext, roles: Role[]): { uid: string; token: Record<string, unknown> } {
  const authContext = requireAuth(request);
  const role = authContext.token.role;
  if (typeof role !== 'string' || !roles.includes(role as Role)) {
    throw new HttpsError('permission-denied', 'You are not authorized for this operation.');
  }
  return authContext;
}

function requireText(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function requireInteger(value: unknown, field: string, minimum = 0): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < minimum) {
    throw new HttpsError('invalid-argument', `${field} must be a valid integer.`);
  }
  return value;
}

function requireRoleValue(value: unknown): Role {
  const role = requireText(value, 'role').toUpperCase();
  const allowed: Role[] = ['SUPER_ADMIN', 'SHOP_OWNER', 'MANAGER', 'FRONT_DESK', 'MECHANIC'];
  if (!allowed.includes(role as Role)) throw new HttpsError('invalid-argument', 'Invalid role.');
  return role as Role;
}

function requireShopId(token: Record<string, unknown>): string {
  const shopId = token.shopId;
  if (typeof shopId !== 'string' || shopId.length === 0) {
    throw new HttpsError('permission-denied', 'No workshop is assigned to this account.');
  }
  return shopId;
}

function assertOwnerTargetRole(role: Role): void {
  if (role === 'SUPER_ADMIN' || role === 'SHOP_OWNER') {
    throw new HttpsError('permission-denied', 'Shop owners cannot assign platform or owner roles.');
  }
}

async function writeAudit(shopId: string, actorUid: string, action: string, entityType: string, entityId: string, before: unknown, after: unknown): Promise<void> {
  await db.collection('auditLogs').add({
    shopId,
    actorUid,
    action,
    entityType,
    entityId,
    before: before ?? null,
    after: after ?? null,
    timestamp: FieldValue.serverTimestamp(),
  });
}

type JobStatus = 'DRAFT' | 'OPEN' | 'ASSIGNED' | 'IN_PROGRESS' | 'WAITING_FOR_PARTS' | 'WAITING_FOR_APPROVAL' | 'COMPLETED' | 'READY_FOR_PICKUP' | 'CLOSED' | 'CANCELLED';
type InventoryMovement = 'STOCK_IN' | 'STOCK_OUT' | 'ADJUSTMENT' | 'RETURN';
type PaymentMethod = 'CASH' | 'CARD' | 'BANK_TRANSFER' | 'MOBILE_PAYMENT' | 'OTHER';

function requireJobStatus(value: unknown): JobStatus {
  const status = requireText(value, 'targetStatus').toUpperCase();
  const allowed: JobStatus[] = ['DRAFT', 'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'WAITING_FOR_PARTS', 'WAITING_FOR_APPROVAL', 'COMPLETED', 'READY_FOR_PICKUP', 'CLOSED', 'CANCELLED'];
  if (!allowed.includes(status as JobStatus)) throw new HttpsError('invalid-argument', 'Invalid job-card status.');
  return status as JobStatus;
}

function canTransition(current: JobStatus, target: JobStatus, role: Role): boolean {
  if (target === 'CANCELLED') return role !== 'MECHANIC' && current !== 'CLOSED';
  if (current === 'DRAFT' && target === 'OPEN') return role !== 'MECHANIC';
  if (current === 'OPEN' && target === 'ASSIGNED') return role === 'MANAGER' || role === 'SHOP_OWNER';
  if (current === 'ASSIGNED' && target === 'IN_PROGRESS') return role === 'MECHANIC' || role === 'MANAGER' || role === 'SHOP_OWNER';
  if (current === 'IN_PROGRESS' && ['WAITING_FOR_PARTS', 'WAITING_FOR_APPROVAL', 'COMPLETED'].includes(target)) return true;
  if (current === 'WAITING_FOR_PARTS' && target === 'IN_PROGRESS') return role === 'MECHANIC' || role === 'MANAGER' || role === 'SHOP_OWNER';
  if (current === 'WAITING_FOR_APPROVAL' && target === 'COMPLETED') return role === 'MANAGER' || role === 'SHOP_OWNER';
  if (current === 'COMPLETED' && target === 'READY_FOR_PICKUP') return role === 'MANAGER' || role === 'SHOP_OWNER';
  if (current === 'READY_FOR_PICKUP' && target === 'CLOSED') return role === 'FRONT_DESK' || role === 'MANAGER' || role === 'SHOP_OWNER';
  return false;
}

export const adminCreateShop = onCall(async (request) => {
  requireRole(request, ['SUPER_ADMIN']);
  const name = requireText(request.data?.name, 'name');
  const code = requireText(request.data?.code, 'code').toUpperCase();
  const existing = await db.collection('shops').where('code', '==', code).limit(1).get();
  if (!existing.empty) throw new HttpsError('already-exists', 'Workshop code is already in use.');

  const shopRef = db.collection('shops').doc();
  const shop = {
    shopId: shopRef.id,
    name,
    code,
    currency: 'USD',
    timezone: 'UTC',
    isActive: true,
    enabledModules: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  await shopRef.set(shop);
  return {
    shopId: shopRef.id,
    name,
    code,
    currency: 'USD',
    timezone: 'UTC',
    isActive: true,
    enabledModules: [],
  };
});

export const adminCreateStaff = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER']);
  const shopId = requireShopId(caller.token);
  const requestedShopId = requireText(request.data?.shopId, 'shopId');
  if (requestedShopId !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');

  const email = requireText(request.data?.email, 'email').toLowerCase();
  const name = requireText(request.data?.name, 'name');
  const role = requireRoleValue(request.data?.role);
  assertOwnerTargetRole(role);

  try {
    const user = await auth.createUser({ email, displayName: name, emailVerified: false });
    const claims = { shopId, role, permissions: [], isActive: true };
    await auth.setCustomUserClaims(user.uid, claims);
    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      email,
      name,
      ...claims,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { uid: user.uid };
  } catch (error) {
    if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'A staff account with this email already exists.');
    }
    throw error;
  }
});

export const adminUpdateStaff = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER']);
  const shopId = requireShopId(caller.token);
  const requestedShopId = requireText(request.data?.shopId, 'shopId');
  if (requestedShopId !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');

  const uid = requireText(request.data?.uid, 'uid');
  const role = requireRoleValue(request.data?.role);
  const isActive = request.data?.isActive;
  if (typeof isActive !== 'boolean') throw new HttpsError('invalid-argument', 'isActive is required.');
  assertOwnerTargetRole(role);

  const staffRef = db.collection('users').doc(uid);
  const staffSnapshot = await staffRef.get();
  if (!staffSnapshot.exists || staffSnapshot.data()?.shopId !== shopId) {
    throw new HttpsError('not-found', 'Staff account was not found in this workshop.');
  }

  await auth.setCustomUserClaims(uid, { shopId, role, permissions: [], isActive });
  await staffRef.update({ role, isActive, updatedAt: FieldValue.serverTimestamp() });
  await writeAudit(shopId, caller.uid, 'STAFF_UPDATED', 'user', uid, null, { role, isActive });
  return { uid, role, isActive };
});

export const transitionJobCard = onCall(async (request) => {
  const caller = requireAuth(request);
  const role = caller.token.role;
  if (typeof role !== 'string' || !['SHOP_OWNER', 'MANAGER', 'FRONT_DESK', 'MECHANIC'].includes(role)) {
    throw new HttpsError('permission-denied', 'You are not authorized to transition job cards.');
  }
  const shopId = requireShopId(caller.token);
  const requestedShopId = requireText(request.data?.shopId, 'shopId');
  if (requestedShopId !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const jobCardId = requireText(request.data?.jobCardId, 'jobCardId');
  const target = requireJobStatus(request.data?.targetStatus);
  const reference = db.collection('jobCards').doc(jobCardId);

  let result: Record<string, unknown> = {};
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const data = snapshot.data();
    if (!snapshot.exists || data?.shopId !== shopId) throw new HttpsError('not-found', 'Job card was not found in this workshop.');
    const current = data.status as JobStatus;
    if (!canTransition(current, target, role as Role)) throw new HttpsError('permission-denied', 'This status transition is not allowed.');
    const assignedMechanics = Array.isArray(data.assignedMechanicIds) ? data.assignedMechanicIds : [];
    if (role === 'MECHANIC' && !assignedMechanics.includes(caller.uid)) {
      throw new HttpsError('permission-denied', 'You can only update your assigned job cards.');
    }
    const updates: Record<string, unknown> = { status: target, updatedAt: FieldValue.serverTimestamp() };
    if (target === 'OPEN') updates.openedAt = FieldValue.serverTimestamp();
    if (target === 'IN_PROGRESS') updates.startedAt = FieldValue.serverTimestamp();
    if (target === 'COMPLETED') updates.completedAt = FieldValue.serverTimestamp();
    if (target === 'CLOSED') updates.closedAt = FieldValue.serverTimestamp();
    transaction.update(reference, updates);
    result = { ...data, ...updates, status: target };
  });
  await writeAudit(shopId, caller.uid, 'JOB_STATUS_CHANGED', 'jobCard', jobCardId, null, { status: target });
  delete result.updatedAt;
  delete result.openedAt;
  delete result.startedAt;
  delete result.completedAt;
  delete result.closedAt;
  return result;
});

export const assignJobCard = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const jobCardId = requireText(request.data?.jobCardId, 'jobCardId');
  const mechanicUid = requireText(request.data?.mechanicUid, 'mechanicUid');
  const mechanicSnapshot = await db.collection('users').doc(mechanicUid).get();
  const mechanic = mechanicSnapshot.data();
  if (!mechanicSnapshot.exists || mechanic?.shopId !== shopId || mechanic.role !== 'MECHANIC' || mechanic.isActive !== true) {
    throw new HttpsError('failed-precondition', 'The selected mechanic is not active in this workshop.');
  }
  const jobReference = db.collection('jobCards').doc(jobCardId);
  const jobSnapshot = await jobReference.get();
  if (!jobSnapshot.exists || jobSnapshot.data()?.shopId !== shopId) {
    throw new HttpsError('not-found', 'Job card was not found in this workshop.');
  }
  if (jobSnapshot.data()?.status !== 'OPEN') throw new HttpsError('failed-precondition', 'Only open job cards can be assigned.');
  await jobReference.update({ assignedMechanicIds: [mechanicUid], status: 'ASSIGNED', updatedAt: FieldValue.serverTimestamp() });
  await writeAudit(shopId, caller.uid, 'JOB_MECHANIC_ASSIGNED', 'jobCard', jobCardId, null, { mechanicUid });
  return { jobCardId, mechanicUid, status: 'ASSIGNED' };
});

export const updateJobCardWork = onCall(async (request) => {
  const caller = requireAuth(request);
  const role = caller.token.role;
  if (role !== 'MECHANIC' && role !== 'MANAGER' && role !== 'SHOP_OWNER') {
    throw new HttpsError('permission-denied', 'You are not authorized to update repair work.');
  }
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const jobCardId = requireText(request.data?.jobCardId, 'jobCardId');
  const notes = requireText(request.data?.notes, 'notes');
  const diagnosis = request.data?.diagnosis;
  if (diagnosis != null && typeof diagnosis !== 'string') throw new HttpsError('invalid-argument', 'Invalid diagnosis.');
  const reference = db.collection('jobCards').doc(jobCardId);
  const snapshot = await reference.get();
  const data = snapshot.data();
  if (!snapshot.exists || data?.shopId !== shopId) throw new HttpsError('not-found', 'Job card was not found in this workshop.');
  if (role === 'MECHANIC' && !(Array.isArray(data.assignedMechanicIds) && data.assignedMechanicIds.includes(caller.uid))) {
    throw new HttpsError('permission-denied', 'You can only update your assigned job cards.');
  }
  await reference.update({ repairNotes: notes, diagnosis: diagnosis ?? null, updatedAt: FieldValue.serverTimestamp() });
  return { jobCardId, updated: true };
});

export const recordInventoryMovement = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const inventoryItemId = requireText(request.data?.inventoryItemId, 'inventoryItemId');
  const type = requireText(request.data?.type, 'type').toUpperCase() as InventoryMovement;
  const allowed: InventoryMovement[] = ['STOCK_IN', 'STOCK_OUT', 'ADJUSTMENT', 'RETURN'];
  if (!allowed.includes(type)) throw new HttpsError('invalid-argument', 'Invalid inventory movement.');
  const quantity = request.data?.quantity;
  if (!Number.isInteger(quantity) || quantity <= 0) throw new HttpsError('invalid-argument', 'Quantity must be a positive integer.');
  const reason = requireText(request.data?.reason, 'reason');
  const itemReference = db.collection('inventoryItems').doc(inventoryItemId);
  const movementReference = db.collection('inventoryMovements').doc();
  let resultingQuantity = 0;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(itemReference);
    const data = snapshot.data();
    if (!snapshot.exists || data?.shopId !== shopId) throw new HttpsError('not-found', 'Inventory item was not found.');
    const current = Number(data.quantityOnHand ?? 0);
    const delta = type === 'STOCK_OUT' ? -quantity : type === 'ADJUSTMENT' ? quantity - current : quantity;
    resultingQuantity = current + delta;
    if (resultingQuantity < 0) throw new HttpsError('failed-precondition', 'Stock cannot become negative.');
    transaction.update(itemReference, { quantityOnHand: resultingQuantity, updatedAt: FieldValue.serverTimestamp() });
    transaction.create(movementReference, {
      movementId: movementReference.id,
      shopId,
      inventoryItemId,
      type,
      quantity,
      delta,
      reason,
      actorUid: caller.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  await writeAudit(shopId, caller.uid, 'INVENTORY_MOVEMENT_RECORDED', 'inventoryItem', inventoryItemId, null, { type, quantity, resultingQuantity });
  return { inventoryItemId, quantityOnHand: resultingQuantity };
});

export const createWarranty = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const jobCardId = requireText(request.data?.jobCardId, 'jobCardId');
  const vehicleId = requireText(request.data?.vehicleId, 'vehicleId');
  const customerId = requireText(request.data?.customerId, 'customerId');
  const durationMonths = request.data?.durationMonths;
  if (!Number.isInteger(durationMonths) || durationMonths < 1 || durationMonths > 120) throw new HttpsError('invalid-argument', 'Warranty duration must be 1 to 120 months.');
  const terms = requireText(request.data?.terms, 'terms');
  const jobSnapshot = await db.collection('jobCards').doc(jobCardId).get();
  const job = jobSnapshot.data();
  if (!jobSnapshot.exists || job?.shopId !== shopId || job.status !== 'COMPLETED') throw new HttpsError('failed-precondition', 'Warranty requires a completed job card.');
  const startDate = new Date();
  const expiryDate = new Date(startDate);
  expiryDate.setMonth(expiryDate.getMonth() + durationMonths);
  const warrantyReference = db.collection('warranties').doc();
  const data = {
    warrantyId: warrantyReference.id, shopId, jobCardId, vehicleId, customerId,
    startDate, durationMonths, expiryDate, terms, status: 'ACTIVE', createdBy: caller.uid,
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  };
  await warrantyReference.set(data);
  await writeAudit(shopId, caller.uid, 'WARRANTY_CREATED', 'warranty', warrantyReference.id, null, { jobCardId, durationMonths, expiryDate });
  return { ...data, startDate, expiryDate };
});

export const createInvoice = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER', 'FRONT_DESK']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const jobCardId = requireText(request.data?.jobCardId, 'jobCardId');
  const customerId = requireText(request.data?.customerId, 'customerId');
  const vehicleId = requireText(request.data?.vehicleId, 'vehicleId');
  const rawItems = request.data?.items;
  if (!Array.isArray(rawItems) || rawItems.length === 0) throw new HttpsError('invalid-argument', 'At least one invoice item is required.');
  const jobSnapshot = await db.collection('jobCards').doc(jobCardId).get();
  const job = jobSnapshot.data();
  if (!jobSnapshot.exists || job?.shopId !== shopId) throw new HttpsError('not-found', 'Job card was not found in this workshop.');
  const items = rawItems.map((item: Record<string, unknown>) => {
    const description = requireText(item.description, 'description');
    const quantity = requireInteger(item.quantity, 'quantity', 1);
    const unitPrice = requireInteger(item.unitPriceMinorUnits, 'unitPriceMinorUnits');
    const discount = requireInteger(item.discountMinorUnits ?? 0, 'discountMinorUnits');
    const tax = requireInteger(item.taxMinorUnits ?? 0, 'taxMinorUnits');
    return { type: requireText(item.type, 'type'), description, quantity, unitPriceMinorUnits: unitPrice, discountMinorUnits: discount, taxMinorUnits: tax, totalMinorUnits: quantity * unitPrice - discount + tax };
  });
  const subtotal = items.reduce((sum, item) => sum + item.quantity * item.unitPriceMinorUnits, 0);
  const discount = items.reduce((sum, item) => sum + item.discountMinorUnits, 0);
  const tax = items.reduce((sum, item) => sum + item.taxMinorUnits, 0);
  const total = subtotal - discount + tax;
  if (total < 0) throw new HttpsError('invalid-argument', 'Invoice total cannot be negative.');
  const invoiceReference = db.collection('invoices').doc();
  const invoiceNumber = `INV-${Date.now()}`;
  await invoiceReference.set({ invoiceId: invoiceReference.id, shopId, invoiceNumber, jobCardId, customerId, vehicleId, items, subtotalMinorUnits: subtotal, discountMinorUnits: discount, taxMinorUnits: tax, totalMinorUnits: total, amountPaidMinorUnits: 0, balanceMinorUnits: total, status: 'ISSUED', createdBy: caller.uid, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  await writeAudit(shopId, caller.uid, 'INVOICE_ISSUED', 'invoice', invoiceReference.id, null, { invoiceNumber, totalMinorUnits: total });
  return { invoiceId: invoiceReference.id, invoiceNumber, shopId, jobCardId, customerId, vehicleId, items, subtotalMinorUnits: subtotal, discountMinorUnits: discount, taxMinorUnits: tax, totalMinorUnits: total, amountPaidMinorUnits: 0, balanceMinorUnits: total, status: 'ISSUED' };
});

export const receivePayment = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER', 'FRONT_DESK']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const invoiceId = requireText(request.data?.invoiceId, 'invoiceId');
  const amount = request.data?.amountMinorUnits;
  const method = requireText(request.data?.method, 'method').toUpperCase() as PaymentMethod;
  const reference = typeof request.data?.reference === 'string' ? request.data.reference.trim() : '';
  if (!Number.isInteger(amount) || amount <= 0) throw new HttpsError('invalid-argument', 'Payment amount must be positive.');
  if (!['CASH', 'CARD', 'BANK_TRANSFER', 'MOBILE_PAYMENT', 'OTHER'].includes(method)) throw new HttpsError('invalid-argument', 'Invalid payment method.');
  const invoiceReference = db.collection('invoices').doc(invoiceId);
  const paymentReference = db.collection('payments').doc();
  await db.runTransaction(async (transaction) => {
    const invoiceSnapshot = await transaction.get(invoiceReference);
    const invoice = invoiceSnapshot.data();
    if (!invoiceSnapshot.exists || invoice?.shopId !== shopId) throw new HttpsError('not-found', 'Invoice was not found.');
    if (invoice.status === 'VOID' || Number(invoice.balanceMinorUnits) <= 0 || amount > Number(invoice.balanceMinorUnits)) throw new HttpsError('failed-precondition', 'Payment exceeds the invoice balance.');
    const paid = Number(invoice.amountPaidMinorUnits) + amount;
    const balance = Number(invoice.totalMinorUnits) - paid;
    transaction.update(invoiceReference, { amountPaidMinorUnits: paid, balanceMinorUnits: balance, status: balance === 0 ? 'PAID' : 'PARTIALLY_PAID', updatedAt: FieldValue.serverTimestamp() });
    transaction.create(paymentReference, { paymentId: paymentReference.id, shopId, invoiceId, amountMinorUnits: amount, method, reference, receivedBy: caller.uid, receivedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp() });
  });
  await writeAudit(shopId, caller.uid, 'PAYMENT_RECEIVED', 'invoice', invoiceId, null, { amountMinorUnits: amount, method });
  return { paymentId: paymentReference.id, invoiceId, amountMinorUnits: amount };
});

export const getWorkshopReport = onCall(async (request) => {
  const caller = requireRole(request, ['SHOP_OWNER', 'MANAGER']);
  const shopId = requireShopId(caller.token);
  if (requireText(request.data?.shopId, 'shopId') !== shopId) throw new HttpsError('permission-denied', 'Tenant mismatch.');
  const from = new Date(requireText(request.data?.from, 'from'));
  const to = new Date(requireText(request.data?.to, 'to'));
  if (Number.isNaN(from.valueOf()) || Number.isNaN(to.valueOf()) || from >= to) throw new HttpsError('invalid-argument', 'Invalid report date range.');
  const [jobs, invoices, payments, inventory] = await Promise.all([
    db.collection('jobCards').where('shopId', '==', shopId).where('status', '==', 'COMPLETED').where('completedAt', '>=', from).where('completedAt', '<=', to).get(),
    db.collection('invoices').where('shopId', '==', shopId).where('createdAt', '>=', from).where('createdAt', '<=', to).get(),
    db.collection('payments').where('shopId', '==', shopId).where('receivedAt', '>=', from).where('receivedAt', '<=', to).get(),
    db.collection('inventoryItems').where('shopId', '==', shopId).get(),
  ]);
  const revenueMinorUnits = invoices.docs.reduce((sum, doc) => sum + Number(doc.data().totalMinorUnits ?? 0), 0);
  const paidMinorUnits = payments.docs.reduce((sum, doc) => sum + Number(doc.data().amountMinorUnits ?? 0), 0);
  const outstandingMinorUnits = invoices.docs.reduce((sum, doc) => sum + Number(doc.data().balanceMinorUnits ?? 0), 0);
  const lowStockItems = inventory.docs.filter((doc) => Number(doc.data().quantityOnHand ?? 0) <= Number(doc.data().minimumStock ?? 0)).length;
  return { from: from.toISOString(), to: to.toISOString(), completedJobs: jobs.size, invoiceCount: invoices.size, revenueMinorUnits, paidMinorUnits, outstandingMinorUnits, lowStockItems };
});
