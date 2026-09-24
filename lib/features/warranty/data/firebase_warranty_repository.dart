import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
      throw WarrantyFailure(_messageForCode(error.code));
    }
  }

  Map<String, dynamic> _mapTimestamps(Map<String, dynamic> data) => data.map((key, value) => MapEntry(key, value is Timestamp ? value.toDate() : value));

  String _messageForCode(String code) => code == 'permission-denied' ? 'You are not authorized to create warranties.' : 'Warranty operation is temporarily unavailable.';
}

class WarrantyFailure implements Exception {
  const WarrantyFailure(this.message);
  final String message;
}
