import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/domain/auth_user.dart';
import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class FirebaseStaffRepository implements StaffRepository {
  FirebaseStaffRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<StaffMember>> watchStaff(String shopId) {
    return _firestore
        .collection('users')
        .where('shopId', isEqualTo: shopId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StaffMember.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Future<void> createStaff({
    required String shopId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    await _callAdminFunction('adminCreateStaff', {
      'shopId': shopId,
      'email': email.trim(),
      'name': name.trim(),
      'role': _roleClaim(role),
    });
  }

  @override
  Future<void> updateStaff({
    required String shopId,
    required String uid,
    required UserRole role,
    required bool isActive,
  }) async {
    await _callAdminFunction('adminUpdateStaff', {
      'shopId': shopId,
      'uid': uid,
      'role': _roleClaim(role),
      'isActive': isActive,
    });
  }

  Future<void> _callAdminFunction(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
    } on FirebaseFunctionsException catch (error) {
      throw StaffManagementFailure(_messageForCode(error.code));
    }
  }

  String _roleClaim(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.shopOwner:
        return 'SHOP_OWNER';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.frontDesk:
        return 'FRONT_DESK';
      case UserRole.mechanic:
        return 'MECHANIC';
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You are not authorized to manage this workshop staff.';
      case 'already-exists':
        return 'A staff account with this email already exists.';
      case 'invalid-argument':
        return 'The staff details are invalid.';
      default:
        return 'Staff management is temporarily unavailable.';
    }
  }
}

class StaffManagementFailure implements Exception {
  const StaffManagementFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
