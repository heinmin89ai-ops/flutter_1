import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/billing_repository.dart';
import '../domain/invoice.dart';

class FirebaseBillingRepository implements BillingRepository {
  FirebaseBillingRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions}) : _firestore = firestore ?? FirebaseFirestore.instance, _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Invoice>> watchInvoices(String shopId) => _firestore.collection('invoices').where('shopId', isEqualTo: shopId).orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => Invoice.fromMap(doc.id, doc.data())).toList());

  @override
  Future<Invoice> createInvoice({required String shopId, required String jobCardId, required String customerId, required String vehicleId, required List<InvoiceItem> items}) async {
    try {
      final result = await _functions.httpsCallable('createInvoice').call({'shopId': shopId, 'jobCardId': jobCardId, 'customerId': customerId, 'vehicleId': vehicleId, 'items': items.map((item) => item.toMap()).toList()});
      return Invoice.fromMap('server', Map<String, dynamic>.from(result.data as Map));
    } on FirebaseFunctionsException catch (error) {
      final failure = _failureForCode(error.code);
      throw BillingFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> receivePayment({required String shopId, required String invoiceId, required int amountMinorUnits, required PaymentMethod method, required String reference}) async {
    try {
      await _functions.httpsCallable('receivePayment').call({'shopId': shopId, 'invoiceId': invoiceId, 'amountMinorUnits': amountMinorUnits, 'method': method.name.toUpperCase(), 'reference': reference});
    } on FirebaseFunctionsException catch (error) {
      final failure = _failureForCode(error.code);
      throw BillingFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  ({String messageKey, String message}) _failureForCode(String code) {
    if (code == 'failed-precondition') {
      return (messageKey: 'errBillingPaymentExceeds', message: 'Payment exceeds the invoice balance or invoice is not payable.');
    }
    if (code == 'permission-denied') {
      return (messageKey: 'errBillingPermission', message: 'You are not authorized for this billing action.');
    }
    return (messageKey: 'errBillingUnavailable', message: 'Billing operation is temporarily unavailable.');
  }
}

class BillingFailure extends LocalizedFailure {
  const BillingFailure(super.message, {super.messageKey = 'errBillingUnavailable'});
}
