import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../repository/auth_repository_provider.dart';

// 現在のFirebaseAuthユーザーの状態を監視
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// 現在のユーザー情報（UserModel）の状態を管理
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return await ref.watch(authRepositoryProvider).getCurrentUser();
});

// 認証関連の操作を管理するViewModel
class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _repository.signInWithEmailAndPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> registerParent({
    required String email,
    required String password,
    required String displayName,
    String? classId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.registerParent(
        email: email,
        password: password,
        displayName: displayName,
        classId: classId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> registerTeacher({
    required String email,
    required String password,
    required String displayName,
    String? classId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.registerTeacher(
        email: email,
        password: password,
        displayName: displayName,
        classId: classId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// AuthViewModelのProvider
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});
