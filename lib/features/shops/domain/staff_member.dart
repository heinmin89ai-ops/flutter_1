import '../../auth/domain/auth_user.dart';

class StaffMember {
  const StaffMember({
    required this.uid,
    required this.shopId,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.permissions,
  });

  final String uid;
  final String shopId;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final Set<String> permissions;

  factory StaffMember.fromMap(String uid, Map<String, dynamic> map) {
    final role = UserRoleLabel.fromClaim(map['role']) ?? UserRole.frontDesk;
    final permissions = map['permissions'];
    return StaffMember(
      uid: uid,
      shopId: map['shopId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: role,
      isActive: map['isActive'] != false,
      permissions: permissions is List ? permissions.whereType<String>().toSet() : <String>{},
    );
  }
}
