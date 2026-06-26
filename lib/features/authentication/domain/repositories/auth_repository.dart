import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/authentication/domain/entities/user_entity.dart';

/// Contract for authentication operations — implemented in data layer.
abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  UserEntity? get currentUser;

  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<UserEntity>> signInWithGoogle();

  Future<Result<UserEntity>> signInWithApple();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> sendEmailVerification();

  Future<Result<void>> reloadUser();

  Future<Result<void>> signOut();

  Future<Result<void>> deleteAccount();

  Future<Result<UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  });

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}
