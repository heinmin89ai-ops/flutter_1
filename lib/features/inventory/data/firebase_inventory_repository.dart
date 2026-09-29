import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_movement.dart';
import '../domain/inventory_repository.dart';

class FirebaseInventoryRepository implements InventoryRepository {
  FirebaseInventoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    final itemReference = _firestore.collection('inventoryItems').doc(inventoryItemId);
    InventoryFailure? rejection;
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(itemReference);
        final item = InventoryItem.fromMap(inventoryItemId, snapshot.data() ?? const <String, dynamic>{});
        // ADJUSTMENT carries the stock figure the workshop wants on the shelf,
        // the rest move it by the given quantity.
        final delta = switch (type) {
          InventoryMovementType.stockOut => -quantity,
          InventoryMovementType.adjustment => quantity - item.quantityOnHand,
          _ => quantity,
        };
        if (!snapshot.exists || item.shopId != shopId) {
          rejection = const InventoryFailure('Inventory item was not found.', messageKey: 'errInventoryPermission');
          return;
        }
        if (quantity <= 0 || item.quantityOnHand + delta < 0) {
          rejection = const InventoryFailure(
            'The stock movement would make inventory negative.',
            messageKey: 'errInventoryNegativeStock',
          );
          return;
        }
        transaction.update(itemReference, <String, Object?>{
          'quantityOnHand': item.quantityOnHand + delta,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(_firestore.collection('inventoryMovements').doc(), <String, Object?>{
          'shopId': shopId,
          'inventoryItemId': inventoryItemId,
          'type': type.value,
          'quantity': quantity,
          'delta': delta,
          'reason': reason.trim(),
          'actorUid': FirebaseAuth.instance.currentUser?.uid ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw InventoryFailure(failure.message, messageKey: failure.messageKey);
    }
    // Reported after the transaction so the abort cannot be retried or wrapped
    // by the Firestore client.
    if (rejection != null) throw rejection!;
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
