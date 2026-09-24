import 'inventory_item.dart';
import 'inventory_movement.dart';

abstract interface class InventoryRepository {
  Stream<List<InventoryItem>> watchItems(String shopId);

  Future<void> createItem(InventoryItem item);

  Future<void> recordMovement({
    required String shopId,
    required String inventoryItemId,
    required InventoryMovementType type,
    required int quantity,
    required String reason,
  });
}
