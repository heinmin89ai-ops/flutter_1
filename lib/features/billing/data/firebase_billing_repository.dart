import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/billing_repository.dart';
import '../domain/invoice.dart';

class FirebaseBillingRepository implements BillingRepository {
  FirebaseBillingRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Invoice>> watchInvoices(String shopId) => _firestore.collection('invoices').where('shopId', isEqualTo: shopId).orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Invoice.fromMap(doc.id, _mapTimestamps(doc.data()))).toList());

  @override
  Future<Invoice> createInvoice({required String shopId, required String jobCardId, required String customerId, required String vehicleId, required List<InvoiceItem> items}) async {
    final reference = _firestore.collection('invoices').doc();
    final subtotal = MoneyCalculator.subtotal(items);
    final discount = MoneyCalculator.discount(items);
    final tax = MoneyCalculator.tax(items);
    final total = subtotal - discount + tax;
    try {
      await reference.set(<String, Object?>{
        'shopId': shopId,
        'invoiceNumber': 'INV-${DateTime.now().millisecondsSinceEpoch}',
        'jobCardId': jobCardId.trim(),
        'customerId': customerId.trim(),
        'vehicleId': vehicleId.trim(),
        'items': items.map((item) => item.toMap()).toList(),
        'subtotalMinorUnits': subtotal,
        'discountMinorUnits': discount,
        'taxMinorUnits': tax,
        'totalMinorUnits': total,
        'amountPaidMinorUnits': 0,
        'balanceMinorUnits': total,
        'status': 'ISSUED',
        'createdBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await reference.get();
      return Invoice.fromMap(reference.id, _mapTimestamps(snapshot.data() ?? const <String, dynamic>{}));
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw BillingFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> receivePayment({required String shopId, required String invoiceId, required int amountMinorUnits, required PaymentMethod method, required String reference}) async {
    final invoiceReference = _firestore.collection('invoices').doc(invoiceId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(invoiceReference);
        final invoice = Invoice.fromMap(invoiceId, _mapTimestamps(snapshot.data() ?? const <String, dynamic>{}));
        if (!snapshot.exists || invoice.shopId != shopId) {
          throw const BillingFailure('Invoice was not found in this workshop.', messageKey: 'errBillingPermission');
        }
        if (amountMinorUnits <= 0 || amountMinorUnits > invoice.balanceMinorUnits) {
          throw const BillingFailure('Payment exceeds the invoice balance or invoice is not payable.', messageKey: 'errBillingPaymentExceeds');
        }
        final paid = invoice.amountPaidMinorUnits + amountMinorUnits;
        final balance = invoice.totalMinorUnits - paid;
        transaction.update(invoiceReference, <String, Object?>{
          'amountPaidMinorUnits': paid,
          'balanceMinorUnits': balance,
          'status': balance == 0 ? 'PAID' : 'PARTIALLY_PAID',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(_firestore.collection('payments').doc(), <String, Object?>{
          'shopId': shopId,
          'invoiceId': invoiceId,
          'amountMinorUnits': amountMinorUnits,
          'method': method.name.toUpperCase(),
          'reference': reference.trim(),
          'receivedBy': _uid,
          'receivedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw BillingFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic> _mapTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) return MapEntry(key, value.toDate());
      return MapEntry(key, value);
    });
  }

  ({String messageKey, String message}) _failureForCode(String code) {
    if (code == 'permission-denied') {
      return (messageKey: 'errBillingPermission', message: 'You are not authorized for this billing action.');
    }
    if (code == 'not-found') {
      return (messageKey: 'errBillingPermission', message: 'Invoice was not found in this workshop.');
    }
    return (messageKey: 'errBillingUnavailable', message: 'Billing operation is temporarily unavailable.');
  }
}

class BillingFailure extends LocalizedFailure {
  const BillingFailure(super.message, {super.messageKey = 'errBillingUnavailable'});
}
