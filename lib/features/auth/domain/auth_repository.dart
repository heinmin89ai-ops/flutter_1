import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser> signIn({required String email, required String password});

  /// Creates the sign-in for an invited staff member and copies their workshop
  /// and role from the invitation, which is the only trusted source for both.
  Future<AuthUser> activate({
    required String email,
    required String password,
    required String invitationCode,
  });

  Future<void> changePassword({required String currentPassword, required String newPassword});

  Future<void> signOut();
}
