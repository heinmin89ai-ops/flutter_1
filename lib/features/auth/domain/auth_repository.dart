import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();
}
