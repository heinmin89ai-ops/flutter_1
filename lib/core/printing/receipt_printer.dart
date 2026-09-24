import 'receipt.dart';

abstract interface class ReceiptPrinter {
  Future<List<PrinterDevice>> discover();
  Future<void> connect(PrinterDevice device);
  Future<void> printReceipt(Receipt receipt);
  Future<void> disconnect();
}

class ReceiptPrinterFailure implements Exception {
  const ReceiptPrinterFailure(this.message);
  final String message;
}
