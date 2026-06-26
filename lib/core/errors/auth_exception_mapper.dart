import 'package:expense_mate/core/errors/exceptions.dart';
import 'package:expense_mate/core/errors/failures.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth exceptions to domain [AuthFailure]s.
class AuthExceptionMapper {
  AuthExceptionMapper._();

  static AuthFailure mapFirebaseAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'The email address is invalid.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'operation-not-allowed' => 'This sign-in method is not enabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      'requires-recent-login' =>
        'Please sign in again to complete this action.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      'invalid-credential' => 'Invalid credentials. Please try again.',
      'credential-already-in-use' =>
        'This credential is already linked to another account.',
      _ => e.message ?? 'Authentication failed. Please try again.',
    };

    return AuthFailure(message: message, code: e.code);
  }

  static AuthFailure mapException(Object e) {
    if (e is FirebaseAuthException) {
      return mapFirebaseAuthException(e);
    }
    if (e is AuthException) {
      return AuthFailure(message: e.message, code: e.code);
    }
    return AuthFailure(message: e.toString());
  }
}
