import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/class_model.dart';
import '../repository/class_repository.dart';
import '../repository/class_repository_provider.dart';
import '../../child/view_model/child_view_model.dart';
import '../../child/view_model/child_provider.dart';
import '../../child/model/child_model.dart'; // 追加

final classViewModelProvider = StateNotifierProvider<ClassViewModel, AsyncValue<List<ClassModel>>>(
  (ref) => ClassViewModel(ref.watch(classRepositoryProvider)),
);

class ClassViewModel extends StateNotifier<AsyncValue<List<ClassModel>>> {
  final ClassRepository _repository;

  ClassViewModel(this._repository) : super(const AsyncValue.loading()) {
    _fetchClasses();
  }

  void _fetchClasses() {
    _repository.getClasses().listen(
      (classes) {
        state = AsyncValue.data(classes);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  Future<void> createClass({
    required String name,
    required List<String> teacherIds, // 変更
    required String kindergartenId,
    List<String> studentIds = const [],
  }) async {
    try {
      final classModel = ClassModel(
        id: '',
        name: name,
        teacherIds: teacherIds, // 変更
        studentIds: studentIds,
        createdAt: DateTime.now(),
        kindergartenId: kindergartenId,
      );
      await _repository.createClass(classModel);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateClass(ClassModel classModel) async {
    try {
      await _repository.updateClass(classModel);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await _repository.deleteClass(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMember(String classId, String studentId) async {
    try {
      await _repository.addMember(classId, studentId);
      // studentIdの園児のclassIdも更新
      final container = ProviderContainer();
      final child = await container.read(childProvider(studentId).future);
      if (child != null && child.classId != classId) {
        final updated = child.copyWith(classId: classId);
        await container.read(childViewModelProvider.notifier).updateChild(updated);
      }
      container.dispose();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeMember(String classId, String studentId) async {
    try {
      await _repository.removeMember(classId, studentId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}