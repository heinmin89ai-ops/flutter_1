enum InvoiceItemType { labor, part, service, directSale }
enum InvoiceStatus { draft, issued, partiallyPaid, paid, voided }
enum PaymentMethod { cash, card, bankTransfer, mobilePayment, other }

class InvoiceItem {
  const InvoiceItem({required this.type, required this.description, required this.quantity, required this.unitPriceMinorUnits, required this.discountMinorUnits, required this.taxMinorUnits});

  final InvoiceItemType type;
  final String description;
  final int quantity;
  final int unitPriceMinorUnits;
  final int discountMinorUnits;
  final int taxMinorUnits;

  int get lineTotalMinorUnits => quantity * unitPriceMinorUnits - discountMinorUnits + taxMinorUnits;

  Map<String, Object?> toMap() => {
        'type': type.name.toUpperCase(),
        'description': description,
        'quantity': quantity,
        'unitPriceMinorUnits': unitPriceMinorUnits,
        'discountMinorUnits': discountMinorUnits,
        'taxMinorUnits': taxMinorUnits,
        'totalMinorUnits': lineTotalMinorUnits,
      };
}

class MoneyCalculator {
  const MoneyCalculator._();

  static int subtotal(List<InvoiceItem> items) => items.fold(0, (sum, item) => sum + item.quantity * item.unitPriceMinorUnits);
  static int discount(List<InvoiceItem> items) => items.fold(0, (sum, item) => sum + item.discountMinorUnits);
  static int tax(List<InvoiceItem> items) => items.fold(0, (sum, item) => sum + item.taxMinorUnits);
  static int total(List<InvoiceItem> items) => subtotal(items) - discount(items) + tax(items);
}

class Invoice {
  const Invoice({required this.invoiceId, required this.shopId, required this.invoiceNumber, required this.jobCardId, required this.customerId, required this.vehicleId, required this.items, required this.subtotalMinorUnits, required this.discountMinorUnits, required this.taxMinorUnits, required this.totalMinorUnits, required this.amountPaidMinorUnits, required this.balanceMinorUnits, required this.status});

  final String invoiceId;
  final String shopId;
  final String invoiceNumber;
  final String jobCardId;
  final String customerId;
  final String vehicleId;
  final List<InvoiceItem> items;
  final int subtotalMinorUnits;
  final int discountMinorUnits;
  final int taxMinorUnits;
  final int totalMinorUnits;
  final int amountPaidMinorUnits;
  final int balanceMinorUnits;
  final InvoiceStatus status;

  factory Invoice.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Invoice(
      invoiceId: id, shopId: map['shopId'] as String? ?? '', invoiceNumber: map['invoiceNumber'] as String? ?? id,
      jobCardId: map['jobCardId'] as String? ?? '', customerId: map['customerId'] as String? ?? '', vehicleId: map['vehicleId'] as String? ?? '',
      items: rawItems is List ? rawItems.whereType<Map>().map((item) => InvoiceItem(type: InvoiceItemType.values.firstWhere((type) => type.name.toUpperCase() == item['type'], orElse: () => InvoiceItemType.service), description: item['description'] as String? ?? '', quantity: (item['quantity'] as num?)?.toInt() ?? 0, unitPriceMinorUnits: (item['unitPriceMinorUnits'] as num?)?.toInt() ?? 0, discountMinorUnits: (item['discountMinorUnits'] as num?)?.toInt() ?? 0, taxMinorUnits: (item['taxMinorUnits'] as num?)?.toInt() ?? 0)).toList() : const [],
      subtotalMinorUnits: (map['subtotalMinorUnits'] as num?)?.toInt() ?? 0, discountMinorUnits: (map['discountMinorUnits'] as num?)?.toInt() ?? 0, taxMinorUnits: (map['taxMinorUnits'] as num?)?.toInt() ?? 0, totalMinorUnits: (map['totalMinorUnits'] as num?)?.toInt() ?? 0, amountPaidMinorUnits: (map['amountPaidMinorUnits'] as num?)?.toInt() ?? 0, balanceMinorUnits: (map['balanceMinorUnits'] as num?)?.toInt() ?? 0,
      status: _statusFrom(map['status']),
    );
  }

  // Stored values are SCREAMING_SNAKE_CASE ('PARTIALLY_PAID'), enum names are
  // lowerCamel, so the underscore has to go before comparing.
  static InvoiceStatus _statusFrom(Object? value) => InvoiceStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == (value as String? ?? 'DRAFT').replaceAll('_', '').toUpperCase(),
        orElse: () => InvoiceStatus.draft,
      );
}
