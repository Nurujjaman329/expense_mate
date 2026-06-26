import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/services/sync_engine.dart';
import 'package:expense_mate/features/authentication/data/datasource/auth_remote_datasource.dart';
import 'package:expense_mate/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:expense_mate/features/authentication/domain/entities/user_entity.dart';
import 'package:expense_mate/features/authentication/domain/repositories/auth_repository.dart';
import 'package:expense_mate/features/authentication/domain/usecases/auth_usecases.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

extension _ResultExtension<T> on Result<T> {
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Error<T>(:final failure) => onFailure(failure),
    };
  }
}

// --- Data layer providers ---

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// --- Use case providers ---

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  return SignUpWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final signInWithAppleUseCaseProvider = Provider<SignInWithAppleUseCase>((ref) {
  return SignInWithAppleUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>((ref) {
  return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
  return SendEmailVerificationUseCase(ref.watch(authRepositoryProvider));
});

final reloadUserUseCaseProvider = Provider<ReloadUserUseCase>((ref) {
  return ReloadUserUseCase(ref.watch(authRepositoryProvider));
});

// --- Auth state ---

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Controller for auth form actions (login, register, social sign-in).
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(signInWithEmailUseCaseProvider).call(
          email: email,
          password: password,
        );
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(signUpWithEmailUseCaseProvider).call(
          email: email,
          password: password,
          displayName: displayName,
        );
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _ref.read(signInWithGoogleUseCaseProvider).call();
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> signInWithApple() async {
    state = const AsyncLoading();
    final result = await _ref.read(signInWithAppleUseCaseProvider).call();
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    final result =
        await _ref.read(sendPasswordResetEmailUseCaseProvider).call(email);
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> sendEmailVerification() async {
    state = const AsyncLoading();
    final result = await _ref.read(sendEmailVerificationUseCaseProvider).call();
    return result.when(
      onSuccess: (_) {
        state = const AsyncData(null);
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> reloadUser() async {
    final result = await _ref.read(reloadUserUseCaseProvider).call();
    return result.when(
      onSuccess: (_) => true,
      onFailure: (_) => false,
    );
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
