import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/child_model.dart';
import '../repository/child_repository.dart';
import '../repository/child_repository_provider.dart';

final childViewModelProvider = StateNotifierProvider<ChildViewModel, AsyncValue<List<ChildModel>>>(
  (ref) => ChildViewModel(ref.watch(childRepositoryProvider)),
);

class ChildViewModel extends StateNotifier<AsyncValue<List<ChildModel>>> {
  final ChildRepository _repository;

  ChildViewModel(this._repository) : super(const AsyncValue.loading());

  Future<String?> createChild(ChildModel child) async {
    try {
      return await _repository.createChild(child); // childIdを返す
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
