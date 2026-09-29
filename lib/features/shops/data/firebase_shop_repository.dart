import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/shop.dart';
import '../domain/shop_repository.dart';

class FirebaseShopRepository implements ShopRepository {
  FirebaseShopRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<Shop?> watchShop(String shopId) {
    return _firestore.collection('shops').doc(shopId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return snapshot.exists && data != null ? Shop.fromMap(snapshot.id, data) : null;
    });
  }

  @override
  Stream<List<Shop>> watchAllShops() {
    return _firestore
        .collection('shops')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Shop.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Future<Shop> createShop({required String name, required String code}) async {
    final trimmedName = name.trim();
    final upperCode = code.trim().toUpperCase();
    if (trimmedName.isEmpty || upperCode.isEmpty) {
      throw const ShopManagementFailure(
        'Workshop name and code are required.',
        messageKey: 'errShopFieldsRequired',
      );
    }
    try {
      // Rules have no way to query, so the duplicate-code guard adminCreateShop
      // used sits here instead. A race between two admins could still produce a
      // repeated code; nothing keys a tenant off it, so the worst case is a
      // confusing entry in the platform admin's own list.
      final clash = await _firestore
          .collection('shops')
          .where('code', isEqualTo: upperCode)
          .limit(1)
          .get();
      if (clash.docs.isNotEmpty) {
        throw const ShopManagementFailure(
          'This workshop code is already in use.',
          messageKey: 'errShopCodeExists',
        );
      }
      final reference = _firestore.collection('shops').doc();
      await reference.set(<String, Object?>{
        'shopId': reference.id,
        'name': trimmedName,
        'code': upperCode,
        'currency': 'USD',
        'timezone': 'UTC',
        'isActive': true,
        'enabledModules': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await reference.get();
      return Shop.fromMap(reference.id, snapshot.data() ?? const <String, dynamic>{});
    } on FirebaseException catch (error) {
      final failure = _failureForCode(error.code);
      throw ShopManagementFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> updateShop({required Shop shop}) {
    return _firestore.collection('shops').doc(shop.shopId).update({
      'name': shop.name,
      'code': shop.code,
      'phone': shop.phone,
      'email': shop.email,
      'address': shop.address,
      'currency': shop.currency,
      'timezone': shop.timezone,
      'enabledModules': shop.enabledModules.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  ({String messageKey, String message}) _failureForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return (messageKey: 'errShopPermission', message: 'You are not authorized to create a workshop.');
      default:
        return (messageKey: 'errShopUnavailable', message: 'Workshop management is temporarily unavailable.');
    }
  }
}

class ShopManagementFailure extends LocalizedFailure {
  const ShopManagementFailure(super.message, {super.messageKey = 'errShopUnavailable'});
}
