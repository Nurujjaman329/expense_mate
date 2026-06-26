import 'package:expense_mate/core/errors/auth_exception_mapper.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/authentication/data/datasource/auth_remote_datasource.dart';
import 'package:expense_mate/features/authentication/data/models/user_model.dart';
import 'package:expense_mate/features/authentication/domain/entities/user_entity.dart';
import 'package:expense_mate/features/authentication/domain/repositories/auth_repository.dart';

/// Implements [AuthRepository] using Firebase Auth remote data source.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((user) {
      if (user == null) return null;
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
        isEmailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime,
        updatedAt: user.metadata.lastSignInTime,
      );
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _remoteDataSource.currentFirebaseUser;
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      updatedAt: user.metadata.lastSignInTime,
    );
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _execute(() => _remoteDataSource.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _execute(() => _remoteDataSource.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    return _execute(_remoteDataSource.signInWithGoogle);
  }

  @override
  Future<Result<UserEntity>> signInWithApple() async {
    return _execute(_remoteDataSource.signInWithApple);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return _executeVoid(() => _remoteDataSource.sendPasswordResetEmail(email));
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    return _executeVoid(_remoteDataSource.sendEmailVerification);
  }

  @override
  Future<Result<void>> reloadUser() async {
    return _executeVoid(_remoteDataSource.reloadUser);
  }

  @override
  Future<Result<void>> signOut() async {
    return _executeVoid(_remoteDataSource.signOut);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    return _executeVoid(_remoteDataSource.deleteAccount);
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    return _execute(() => _remoteDataSource.updateProfile(
          displayName: displayName,
          photoUrl: photoUrl,
          phoneNumber: phoneNumber,
        ));
  }

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _executeVoid(() => _remoteDataSource.updatePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
  }

  Future<Result<UserEntity>> _execute(
    Future<UserModel> Function() action,
  ) async {
    try {
      final user = await action();
      return Success(user.toEntity());
    } catch (e) {
      return Error(AuthExceptionMapper.mapException(e));
    }
  }

  Future<Result<void>> _executeVoid(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (e) {
      return Error(AuthExceptionMapper.mapException(e));
    }
  }
}
