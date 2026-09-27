import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_movement.dart';
import '../domain/inventory_repository.dart';

class FirebaseInventoryRepository implements InventoryRepository {
  FirebaseInventoryRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<InventoryItem>> watchItems(String shopId) {
    return _firestore
        .collection('inventoryItems')
        .where('shopId', isEqualTo: shopId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => InventoryItem.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Future<void> createItem(InventoryItem item) {
    return _firestore.collection('inventoryItems').doc(item.inventoryItemId).set({
      'inventoryItemId': item.inventoryItemId,
      'shopId': item.shopId,
      'sku': item.sku,
      'name': item.name,
      'category': item.category,
      'unit': item.unit,
      'quantityOnHand': 0,
      'minimumStock': item.minimumStock,
      'costPriceMinorUnits': item.costPriceMinorUnits,
      'sellingPriceMinorUnits': item.sellingPriceMinorUnits,
      'isActive': item.isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordMovement({
    required String shopId,
    required String inventoryItemId,
    required InventoryMovementType type,
    required int quantity,
    required String reason,
  }) async {
    try {
      await _functions.httpsCallable('recordInventoryMovement').call({
        'shopId': shopId,
        'inventoryItemId': inventoryItemId,
        'type': type.value,
        'quantity': quantity,
        'reason': reason,
      });
    } on FirebaseFunctionsException catch (error) {
      final failure = _failureForCode(error.code);
      throw InventoryFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  ({String messageKey, String message}) _failureForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return (messageKey: 'errInventoryPermission', message: 'You are not authorized to manage inventory.');
      case 'failed-precondition':
        return (messageKey: 'errInventoryNegativeStock', message: 'The stock movement would make inventory negative.');
      default:
        return (messageKey: 'errInventoryUnavailable', message: 'Inventory operation is temporarily unavailable.');
    }
  }
}

class InventoryFailure extends LocalizedFailure {
  const InventoryFailure(super.message, {super.messageKey = 'errInventoryUnavailable'});
}
