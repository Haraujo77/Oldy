import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.registerWithEmail(email, password, name);
      state = AsyncValue.data(user);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e) {
      if (e.toString().contains('sign-in-cancelled')) {
        state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithApple();
      state = AsyncValue.data(user);
    } catch (e) {
      if (e.toString().contains('AuthorizationErrorCode.canceled')) {
        state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
