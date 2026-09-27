import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/localized_failure.dart';
import '../../auth/domain/auth_user.dart';
import '../domain/staff_invitation.dart';
import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class FirebaseStaffRepository implements StaffRepository {
  FirebaseStaffRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Random? random,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Random _random;

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
  Future<StaffInvitation> createStaff({
    required String shopId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final invitation = StaffInvitation(
      code: _secret(_codeAlphabet, 10),
      email: normalizedEmail,
      name: name.trim(),
      role: role,
      temporaryPassword: _secret(_passwordAlphabet, 12),
    );
    try {
      await _firestore.collection('staffInvitations').doc(invitation.code).set({
        'shopId': shopId,
        'email': normalizedEmail,
        'name': invitation.name,
        'role': _roleClaim(role),
        'status': 'PENDING',
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw _failureForCode(error.code);
    }
    return invitation;
  }

  @override
  Future<void> updateStaff({
    required String shopId,
    required String uid,
    required UserRole role,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': _roleClaim(role),
        'isActive': isActive,
      });
    } on FirebaseException catch (error) {
      throw _failureForCode(error.code);
    }
  }

  @override
  Stream<List<StaffInvitation>> watchInvitations(String shopId) {
    return _firestore
        .collection('staffInvitations')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StaffInvitation.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  @override
  Future<void> cancelInvitation({required String code}) async {
    try {
      await _firestore.collection('staffInvitations').doc(code).delete();
    } on FirebaseException catch (error) {
      throw _failureForCode(error.code);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (error) {
      final failure = switch (error.code) {
        'user-not-found' => (
            messageKey: 'errResetEmailNotFound',
            message: 'No staff account uses this email address yet.',
          ),
        'too-many-requests' => (
            messageKey: 'authTooManyRequests',
            message: 'Too many attempts. Please wait and try again.',
          ),
        _ => (
            messageKey: 'errResetEmailFailed',
            message: 'Unable to send the reset email. Try again.',
          ),
      };
      throw StaffManagementFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  String _secret(String alphabet, int length) =>
      List.generate(length, (_) => alphabet[_random.nextInt(alphabet.length)]).join();

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

  StaffManagementFailure _failureForCode(String code) {
    final failure = switch (code) {
      'permission-denied' => (
          messageKey: 'errStaffPermission',
          message: 'You are not authorized to manage this workshop staff.',
        ),
      'already-exists' => (
          messageKey: 'errStaffEmailExists',
          message: 'A staff account with this email already exists.',
        ),
      'not-found' => (
          messageKey: 'errShopUnavailable',
          message: 'This workshop could not be found.',
        ),
      _ => (
          messageKey: 'errStaffUnavailable',
          message: 'Staff management is temporarily unavailable.',
        ),
    };
    return StaffManagementFailure(failure.message, messageKey: failure.messageKey);
  }

  /// Ambiguous glyphs are excluded because the owner reads these out to the
  /// new staff member.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _passwordAlphabet = 'abcdefghijkmnpqrstuvwxyz23456789';
}

class StaffManagementFailure extends LocalizedFailure {
  const StaffManagementFailure(super.message, {super.messageKey = 'errStaffUnavailable'});
}
