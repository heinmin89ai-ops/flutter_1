class InventoryItem {
  const InventoryItem({
    required this.inventoryItemId,
    required this.shopId,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantityOnHand,
    required this.minimumStock,
    required this.costPriceMinorUnits,
    required this.sellingPriceMinorUnits,
    required this.isActive,
  });

  final String inventoryItemId;
  final String shopId;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final int quantityOnHand;
  final int minimumStock;
  final int costPriceMinorUnits;
  final int sellingPriceMinorUnits;
  final bool isActive;

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      inventoryItemId: id,
      shopId: map['shopId'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? 'piece',
      quantityOnHand: (map['quantityOnHand'] as num?)?.toInt() ?? 0,
      minimumStock: (map['minimumStock'] as num?)?.toInt() ?? 0,
      costPriceMinorUnits: (map['costPriceMinorUnits'] as num?)?.toInt() ?? 0,
      sellingPriceMinorUnits: (map['sellingPriceMinorUnits'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] != false,
    );
  }
}
