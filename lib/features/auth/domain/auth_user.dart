enum UserRole {
  superAdmin,
  shopOwner,
  manager,
  frontDesk,
  mechanic,
}

extension UserRoleLabel on UserRole {
  static UserRole? fromClaim(Object? value) {
    if (value is! String) return null;
    switch (value.toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'SHOP_OWNER':
        return UserRole.shopOwner;
      case 'MANAGER':
        return UserRole.manager;
      case 'FRONT_DESK':
        return UserRole.frontDesk;
      case 'MECHANIC':
        return UserRole.mechanic;
      default:
        return null;
    }
  }
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.shopId,
    required this.role,
    required this.permissions,
    required this.isActive,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? shopId;
  final UserRole? role;
  final Set<String> permissions;
  final bool isActive;
}
