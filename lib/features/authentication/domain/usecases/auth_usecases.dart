import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/features/authentication/domain/entities/user_entity.dart';
import 'package:expense_mate/features/authentication/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call() => _repository.signInWithGoogle();
}

class SignInWithAppleUseCase {
  const SignInWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call() => _repository.signInWithApple();
}

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) =>
      _repository.sendPasswordResetEmail(email);
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccount();
}

class SendEmailVerificationUseCase {
  const SendEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.sendEmailVerification();
}

class ReloadUserUseCase {
  const ReloadUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.reloadUser();
}
