class ReceiptLine {
  const ReceiptLine({required this.label, required this.value});
  final String label;
  final String value;
}

class Receipt {
  const Receipt({required this.shopName, required this.invoiceNumber, required this.lines, required this.total, required this.paid, required this.balance});
  final String shopName;
  final String invoiceNumber;
  final List<ReceiptLine> lines;
  final String total;
  final String paid;
  final String balance;
}

class PrinterDevice {
  const PrinterDevice({required this.id, required this.name});
  final String id;
  final String name;
}
