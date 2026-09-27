import '../../auth/domain/auth_user.dart';
import 'staff_invitation.dart';
import 'staff_member.dart';

abstract interface class StaffRepository {
  Stream<List<StaffMember>> watchStaff(String shopId);

  /// Records an invitation for a person who does not have an account yet.
  /// Nothing is activated until they sign up with the returned code.
  Future<StaffInvitation> createStaff({
    required String shopId,
    required String email,
    required String name,
    required UserRole role,
  });

  Future<void> updateStaff({
    required String shopId,
    required String uid,
    required UserRole role,
    required bool isActive,
  });

  /// Invitations the owner has created but nobody has activated yet.
  Stream<List<StaffInvitation>> watchInvitations(String shopId);

  Future<void> cancelInvitation({required String code});

  Future<void> sendPasswordReset({required String email});
}
