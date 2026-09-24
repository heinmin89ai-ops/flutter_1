import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().asyncMap(_mapUser);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Authentication returned no user.');
      }
      return _requireActive(await _mapUser(user));
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageForCode(error.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthUser?> _mapUser(User? user) async {
    if (user == null) return null;

    final token = await user.getIdTokenResult();
    final claims = token.claims ?? const <String, Object?>{};
    final rawPermissions = claims['permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions.whereType<String>().toSet()
        : <String>{};

    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      shopId: claims['shopId'] as String?,
      role: UserRoleLabel.fromClaim(claims['role']),
      permissions: permissions,
      isActive: claims['isActive'] != false,
    );
  }

  AuthUser _requireActive(AuthUser? user) {
    if (user == null) throw const AuthFailure('Authentication returned no user.');
    if (!user.isActive) throw const AuthFailure('This staff account is inactive.');
    if (user.role == null) throw const AuthFailure('Your account has no valid role.');
    if (user.role != UserRole.superAdmin && user.shopId == null) {
      throw const AuthFailure('Your account has no assigned workshop.');
    }
    return user;
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'user-disabled':
        return 'This staff account is disabled.';
      default:
        return 'Unable to sign in. Check your connection and try again.';
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
