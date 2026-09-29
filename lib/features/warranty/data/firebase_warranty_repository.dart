import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/warranty.dart';
import '../domain/warranty_repository.dart';

class FirebaseWarrantyRepository implements WarrantyRepository {
  FirebaseWarrantyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Warranty>> watchWarranties(String shopId) {
    return _firestore.collection('warranties').where('shopId', isEqualTo: shopId).orderBy('expiryDate').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Warranty.fromMap(doc.id, _mapTimestamps(doc.data()))).toList(),
        );
  }

  @override
  Future<Warranty> createWarranty({required String shopId, required String jobCardId, required String vehicleId, required String customerId, required int durationMonths, required String terms}) async {
    final reference = _firestore.collection('warranties').doc();
    final startDate = DateTime.now();
    final expiryDate = Warranty.calculateExpiry(startDate, durationMonths);
    try {
      await reference.set(<String, Object?>{
        'warrantyId': reference.id,
        'shopId': shopId,
        'jobCardId': jobCardId.trim(),
        'vehicleId': vehicleId.trim(),
        'customerId': customerId.trim(),
        'startDate': startDate,
        'durationMonths': durationMonths,
        'expiryDate': expiryDate,
        'terms': terms.trim(),
        'status': 'ACTIVE',
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await reference.get();
      return Warranty.fromMap(reference.id, _mapTimestamps(snapshot.data() ?? const <String, dynamic>{}));
    } on FirebaseException catch (error) {
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
