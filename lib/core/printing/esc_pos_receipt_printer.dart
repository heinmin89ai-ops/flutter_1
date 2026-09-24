import 'esc_pos_receipt_encoder.dart';
import 'receipt.dart';
import 'receipt_printer.dart';

abstract interface class PrinterTransport {
  Future<List<PrinterDevice>> discover();
  Future<void> connect(PrinterDevice device);
  Future<void> write(List<int> bytes);
  Future<void> disconnect();
}

class EscPosReceiptPrinter implements ReceiptPrinter {
  EscPosReceiptPrinter({required PrinterTransport transport, EscPosReceiptEncoder? encoder}) : _transport = transport, _encoder = encoder ?? const EscPosReceiptEncoder();

  final PrinterTransport _transport;
  final EscPosReceiptEncoder _encoder;
  PrinterDevice? _connectedDevice;

  @override
  Future<List<PrinterDevice>> discover() => _transport.discover();

  @override
  Future<void> connect(PrinterDevice device) async {
    try {
      await _transport.connect(device);
      _connectedDevice = device;
    } catch (_) {
      throw const ReceiptPrinterFailure('Unable to connect to the receipt printer.');
    }
  }

  @override
  Future<void> printReceipt(Receipt receipt) async {
    if (_connectedDevice == null) throw const ReceiptPrinterFailure('Connect a receipt printer first.');
    try {
      await _transport.write(_encoder.encode(receipt));
    } catch (_) {
      throw const ReceiptPrinterFailure('Receipt printing failed.');
    }
  }

  @override
  Future<void> disconnect() async {
    await _transport.disconnect();
    _connectedDevice = null;
  }
}
