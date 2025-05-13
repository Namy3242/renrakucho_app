import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/child_model.dart';
import '../repository/child_repository.dart';
import '../repository/child_repository_provider.dart';
import '../../class/view_model/class_view_model.dart';

// 保護者一覧取得用Provider（他ファイルでも使えるようにここで定義）
final parentsProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getParents();
});

final childViewModelProvider = StateNotifierProvider<ChildViewModel, AsyncValue<List<ChildModel>>>(
  (ref) => ChildViewModel(ref.watch(childRepositoryProvider), ref),
);

class ChildViewModel extends StateNotifier<AsyncValue<List<ChildModel>>> {
  final ChildRepository _repository;
  final Ref ref; // 追加

  ChildViewModel(this._repository, this.ref) : super(const AsyncValue.loading());

  Future<String?> createChild(ChildModel child) async {
    try {
      final childId = await _repository.createChild(child); // childIdを返す
      // クラスIDが指定されていれば、クラスのstudentIdsにも追加
      if (child.classId != null && child.classId!.isNotEmpty) {
        // クラスViewModelのaddMemberを呼び出す
        // refはStateNotifierでは使えないので、ProviderContainer経由で呼び出す必要あり
        final container = ProviderContainer();
        await container.read(classViewModelProvider.notifier).addMember(child.classId!, childId!);
        container.dispose();
      }
      return childId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<String?> createInviteCode(ChildModel child) async {
    try {
      // 保護者未紐付園児のみ発行可
      if (child.parentIds.isNotEmpty) {
        throw Exception('すでに保護者が紐付いています');
      }
      final repo = ref.read(authViewModelProvider.notifier);
      return await repo.createInviteCode(
        kindergartenId: child.kindergartenId,
        childId: child.id,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateChild(ChildModel child) async {
    try {
      await _repository.updateChild(child);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteChild(String id) async {
    try {
      await _repository.deleteChild(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
