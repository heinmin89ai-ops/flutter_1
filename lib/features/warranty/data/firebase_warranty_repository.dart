import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/warranty.dart';
import '../domain/warranty_repository.dart';

class FirebaseWarrantyRepository implements WarrantyRepository {
  FirebaseWarrantyRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Warranty>> watchWarranties(String shopId) {
    return _firestore.collection('warranties').where('shopId', isEqualTo: shopId).orderBy('expiryDate').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Warranty.fromMap(doc.id, _mapTimestamps(doc.data()))).toList(),
        );
  }

  @override
  Future<Warranty> createWarranty({required String shopId, required String jobCardId, required String vehicleId, required String customerId, required int durationMonths, required String terms}) async {
    try {
      final result = await _functions.httpsCallable('createWarranty').call({
        'shopId': shopId,
        'jobCardId': jobCardId,
        'vehicleId': vehicleId,
        'customerId': customerId,
        'durationMonths': durationMonths,
        'terms': terms,
      });
      return Warranty.fromMap('server', _mapTimestamps(Map<String, dynamic>.from(result.data as Map)));
    } on FirebaseFunctionsException catch (error) {
      final failure = _failureForCode(error.code);
      throw WarrantyFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  Map<String, dynamic> _mapTimestamps(Map<String, dynamic> data) => data.map((key, value) => MapEntry(key, value is Timestamp ? value.toDate() : value));

  ({String messageKey, String message}) _failureForCode(String code) => code == 'permission-denied'
      ? (messageKey: 'errWarrantyPermission', message: 'You are not authorized to create warranties.')
      : (messageKey: 'errWarrantyUnavailable', message: 'Warranty operation is temporarily unavailable.');
}

class WarrantyFailure extends LocalizedFailure {
  const WarrantyFailure(super.message, {super.messageKey = 'errWarrantyUnavailable'});
}
