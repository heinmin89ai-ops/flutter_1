import 'package:flutter_test/flutter_test.dart';

import 'package:workshop_ops/core/printing/esc_pos_receipt_encoder.dart';
import 'package:workshop_ops/core/printing/receipt.dart';

void main() {
  test('encodes a receipt with ESC/POS initialization and cut commands', () {
    final bytes = const EscPosReceiptEncoder().encode(const Receipt(
      shopName: 'Workshop',
      invoiceNumber: 'INV-1',
      lines: [ReceiptLine(label: 'Labor', value: '1000')],
      total: '1000',
      paid: '1000',
      balance: '0',
    ));
    expect(bytes.take(2), [0x1B, 0x40]);
    expect(bytes.sublist(bytes.length - 3), [0x1D, 0x56, 0x00]);
  });
}