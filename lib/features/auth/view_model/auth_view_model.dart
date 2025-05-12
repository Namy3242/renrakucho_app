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

  Future<void> registerAdmin({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.registerAdmin(
        email: email,
        password: password,
        displayName: displayName,
      );
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
    required String kindergartenId, // 修正
    String? classId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.registerParent(
        email: email,
        password: password,
        displayName: displayName,
        kindergartenId: kindergartenId, // 修正
        classId: classId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> registerParentWithInvite({
    required String email,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    try {
      state = const AsyncValue.loading();
      final result = await _repository.registerParentWithInvite(
        email: email,
        password: password,
        displayName: displayName,
        inviteCode: inviteCode,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> registerTeacher({
    required String email,
    required String password,
    required String displayName,
    required String kindergartenId, // 修正
    String? classId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.registerTeacher(
        email: email,
        password: password,
        displayName: displayName,
        kindergartenId: kindergartenId, // 修正
        classId: classId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<String> createInviteCode({
    required String kindergartenId,
    required String childId,
  }) async {
    try {
      state = const AsyncValue.loading();
      final code = await _repository.createInviteCode(
        kindergartenId: kindergartenId,
        childId: childId,
      );
      state = const AsyncValue.data(null);
      return code;
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
      // Note: 画面遷移はGoRouterのredirectで自動的に処理されるため、
      // ここでの明示的な画面遷移は不要
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
