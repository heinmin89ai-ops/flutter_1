enum InventoryMovementType { stockIn, stockOut, adjustment, returnStock }

extension InventoryMovementTypeValue on InventoryMovementType {
  String get value {
    switch (this) {
      case InventoryMovementType.stockIn:
        return 'STOCK_IN';
      case InventoryMovementType.stockOut:
        return 'STOCK_OUT';
      case InventoryMovementType.adjustment:
        return 'ADJUSTMENT';
      case InventoryMovementType.returnStock:
        return 'RETURN';
    }
  }
}
