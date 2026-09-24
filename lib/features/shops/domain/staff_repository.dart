import '../../auth/domain/auth_user.dart';
import 'staff_member.dart';

abstract interface class StaffRepository {
  Stream<List<StaffMember>> watchStaff(String shopId);

  Future<void> createStaff({
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
}
