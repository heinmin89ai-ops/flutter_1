import 'dart:convert';

import 'receipt.dart';

class EscPosReceiptEncoder {
  const EscPosReceiptEncoder();

  List<int> encode(Receipt receipt) {
    final bytes = <int>[];
    bytes.addAll([0x1B, 0x40]);
    bytes.addAll(_center(receipt.shopName));
    bytes.addAll(_center('INVOICE ${receipt.invoiceNumber}'));
    bytes.addAll(_line());
    for (final line in receipt.lines) {
      bytes.addAll(_leftRight(line.label, line.value));
    }
    bytes.addAll(_line());
    bytes.addAll(_leftRight('TOTAL', receipt.total));
    bytes.addAll(_leftRight('PAID', receipt.paid));
    bytes.addAll(_leftRight('BALANCE', receipt.balance));
    bytes.addAll([0x0A, 0x0A, 0x0A]);
    bytes.addAll([0x1D, 0x56, 0x00]);
    return bytes;
  }

  List<int> _center(String value) => [...utf8.encode(value), 0x0A];
  List<int> _line() => [...utf8.encode('--------------------------------'), 0x0A];
  List<int> _leftRight(String left, String right) {
    final combined = '$left $right';
    return [...utf8.encode(combined.length > 32 ? combined.substring(0, 32) : combined), 0x0A];
  }
}
