import '../../auth/domain/auth_user.dart';

/// An invitation the workshop owner hands over in person: the new staff member
/// types the code plus their own email on the activation screen, and the
/// temporary password is only a suggested starting point.
class StaffInvitation {
  const StaffInvitation({
    required this.code,
    required this.email,
    required this.name,
    required this.role,
    required this.temporaryPassword,
  });

  final String code;
  final String email;
  final String name;
  final UserRole role;
  final String temporaryPassword;

  /// The suggested password is never stored, so a re-read invitation only has
  /// the code left to share.
  factory StaffInvitation.fromMap(String code, Map<String, dynamic> map) => StaffInvitation(
    code: code,
    email: map['email'] as String? ?? '',
    name: map['name'] as String? ?? '',
    role: UserRoleLabel.fromClaim(map['role']) ?? UserRole.frontDesk,
    temporaryPassword: '',
  );
}
