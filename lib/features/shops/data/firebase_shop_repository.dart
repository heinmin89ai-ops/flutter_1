import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/shop.dart';
import '../domain/shop_repository.dart';

class FirebaseShopRepository implements ShopRepository {
  FirebaseShopRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

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
    try {
      final result = await _functions.httpsCallable('adminCreateShop').call({
        'name': name.trim(),
        'code': code.trim().toUpperCase(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return Shop.fromMap(data['shopId'] as String, data);
    } on FirebaseFunctionsException catch (error) {
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
      case 'already-exists':
        return (messageKey: 'errShopCodeExists', message: 'This workshop code is already in use.');
      case 'invalid-argument':
        return (messageKey: 'errShopFieldsRequired', message: 'Workshop name and code are required.');
      default:
        return (messageKey: 'errShopUnavailable', message: 'Workshop management is temporarily unavailable.');
    }
  }
}

class ShopManagementFailure extends LocalizedFailure {
  const ShopManagementFailure(super.message, {super.messageKey = 'errShopUnavailable'});
}
