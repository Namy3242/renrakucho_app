import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/child_model.dart';
import '../repository/child_repository.dart';
import '../repository/child_repository_provider.dart';
import '../../class/view_model/class_view_model.dart';

final childViewModelProvider = StateNotifierProvider<ChildViewModel, AsyncValue<List<ChildModel>>>(
  (ref) => ChildViewModel(ref.watch(childRepositoryProvider)),
);

class ChildViewModel extends StateNotifier<AsyncValue<List<ChildModel>>> {
  final ChildRepository _repository;

  ChildViewModel(this._repository) : super(const AsyncValue.loading());

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
