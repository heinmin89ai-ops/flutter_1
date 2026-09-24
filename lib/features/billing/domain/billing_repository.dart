import 'invoice.dart';

abstract interface class BillingRepository {
  Stream<List<Invoice>> watchInvoices(String shopId);

  Future<Invoice> createInvoice({required String shopId, required String jobCardId, required String customerId, required String vehicleId, required List<InvoiceItem> items});

  Future<void> receivePayment({required String shopId, required String invoiceId, required int amountMinorUnits, required PaymentMethod method, required String reference});
}
