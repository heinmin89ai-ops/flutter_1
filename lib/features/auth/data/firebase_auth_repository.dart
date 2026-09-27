import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/localized_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.idTokenChanges().asyncMap(_mapUser);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Authentication returned no user.', messageKey: 'authNoUserReturned');
      }
      return _requireActive(await _mapUser(user));
    } on FirebaseAuthException catch (error) {
      final failure = _failureForCode(error.code);
      throw AuthFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<AuthUser> activate({
    required String email,
    required String password,
    required String invitationCode,
  }) async {
    final User created;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _normalizeEmail(email),
        password: password,
      );
      created = credential.user ??
          (throw const AuthFailure('Authentication returned no user.', messageKey: 'authNoUserReturned'));
    } on FirebaseAuthException catch (error) {
      final failure = _activationFailureForCode(error.code);
      throw AuthFailure(failure.message, messageKey: failure.messageKey);
    }

    try {
      final invitation = await _readInvitation(invitationCode, created.email);
      await _firestore.collection('users').doc(created.uid).set({
        'uid': created.uid,
        'email': created.email,
        'name': invitation['name'],
        'role': invitation['role'],
        'shopId': invitation['shopId'],
        'permissions': const <String>[],
        'isActive': true,
        'invitationId': invitation.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await invitation.reference.update({
        'status': 'CLAIMED',
        'claimedAt': FieldValue.serverTimestamp(),
      });
      // The profile did not exist when this session opened, so force the auth
      // stream to re-read it.
      await created.getIdToken(true);
      return _requireActive(await _mapUser(created));
    } catch (error) {
      await _auth.signOut();
      if (error is AuthFailure) rethrow;
      throw const AuthFailure(
        'This invitation code was not recognised for that email address.',
        messageKey: 'errInvitationNotFound',
      );
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _readInvitation(String code, String? email) async {
    final snapshot = await _firestore.collection('staffInvitations').doc(code.trim()).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const AuthFailure(
        'This invitation code was not recognised for that email address.',
        messageKey: 'errInvitationNotFound',
      );
    }
    if (data['email'] != email) {
      throw const AuthFailure(
        'This invitation was issued for a different email address.',
        messageKey: 'errInvitationEmailMismatch',
      );
    }
    if (data['status'] != 'PENDING') {
      throw const AuthFailure(
        'This invitation has already been used. Sign in instead.',
        messageKey: 'errInvitationAlreadyClaimed',
      );
    }
    return snapshot;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure('Authentication returned no user.', messageKey: 'authNoUserReturned');
    }
    if (newPassword.length < _minPasswordLength) {
      throw const AuthFailure(_weakPasswordMessage, messageKey: 'authWeakPassword');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      final failure = switch (error.code) {
        'wrong-password' || 'invalid-credential' => (
            messageKey: 'authInvalidCredentials',
            message: 'Email or password is incorrect.',
          ),
        'weak-password' => (messageKey: 'authWeakPassword', message: _weakPasswordMessage),
        'requires-recent-login' => (
            messageKey: 'authReauthRequired',
            message: 'Please sign in again and try once more.',
          ),
        _ => (messageKey: 'authPasswordChangeFailed', message: 'Unable to change the password. Try again.'),
      };
      throw AuthFailure(failure.message, messageKey: failure.messageKey);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static const _minPasswordLength = 8;
  static const _weakPasswordMessage = 'Password must be at least 8 characters.';

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<AuthUser?> _mapUser(User? user) async {
    if (user == null) return null;

    Map<String, dynamic> profile = const {};
    try {
      final document = await _firestore.collection('users').doc(user.uid).get();
      profile = document.data() ?? const {};
    } on FirebaseException {
      // Firestore is unreachable; the claims below still render the shell.
    }

    if (UserRoleLabel.fromClaim(profile['role']) == null) {
      // An empty read means the profile is not in the local cache yet rather
      // than genuinely absent, so fall back to the claims written when the
      // account was created. Without this the owner silently loses staff
      // management until the next auth event.
      final token = await user.getIdTokenResult();
      profile = {...?token.claims, ...profile};
    }

    final rawPermissions = profile['permissions'];
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      shopId: profile['shopId'] as String?,
      role: UserRoleLabel.fromClaim(profile['role']),
      permissions: rawPermissions is List
          ? rawPermissions.whereType<String>().toSet()
          : <String>{},
      isActive: profile['isActive'] != false,
    );
  }

  AuthUser _requireActive(AuthUser? user) {
    if (user == null) throw const AuthFailure('Authentication returned no user.', messageKey: 'authNoUserReturned');
    if (!user.isActive) throw const AuthFailure('This staff account is inactive.', messageKey: 'authAccountInactive');
    if (user.role == null) throw const AuthFailure('Your account has no valid role.', messageKey: 'authNoValidRole');
    if (user.role != UserRole.superAdmin && user.shopId == null) {
      throw const AuthFailure('Your account has no assigned workshop.', messageKey: 'noWorkshopAssigned');
    }
    return user;
  }

  /// Firebase error codes map onto a stable localization key plus the English
  /// prose kept as a fallback when a key has no `AppLocalizations` entry.
  ({String messageKey, String message}) _failureForCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return (messageKey: 'authInvalidCredentials', message: 'Email or password is incorrect.');
      case 'too-many-requests':
        return (messageKey: 'authTooManyRequests', message: 'Too many attempts. Please wait and try again.');
      case 'user-disabled':
        return (messageKey: 'authUserDisabled', message: 'This staff account is disabled.');
      default:
        return (messageKey: 'authConnectionRetry', message: 'Unable to sign in. Check your connection and try again.');
    }
  }

  ({String messageKey, String message}) _activationFailureForCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return (
          messageKey: 'errEmailAlreadyInUse',
          message: 'An account already exists for this email. Sign in instead.',
        );
      case 'weak-password':
        return (messageKey: 'authWeakPassword', message: _weakPasswordMessage);
      case 'invalid-email':
        return (messageKey: 'validationValidEmail', message: 'Enter a valid email address.');
      case 'operation-not-allowed':
      case 'network-request-failed':
        return (
          messageKey: 'authConnectionRetry',
          message: 'Unable to activate your account. Check your connection and try again.',
        );
      default:
        return (
          messageKey: 'errAccountActivationFailed',
          message: 'Unable to activate your account. Please try again.',
        );
    }
  }
}

class AuthFailure extends LocalizedFailure {
  const AuthFailure(super.message, {super.messageKey = 'authUnknown'});
}
