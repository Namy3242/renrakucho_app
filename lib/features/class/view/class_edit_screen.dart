import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../model/class_model.dart';
import '../view_model/class_view_model.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/view_model/user_provider.dart';  // 追加

final teachersProvider = FutureProvider<List<UserModel>>((ref) async {
  return await ref.read(userRepositoryProvider).getTeachers();
});

class ClassEditScreen extends ConsumerStatefulWidget {
  const ClassEditScreen({
    super.key,
    required this.classModel,
  });

  final ClassModel classModel;

  @override
  ConsumerState<ClassEditScreen> createState() => _ClassEditScreenState();
}

class _ClassEditScreenState extends ConsumerState<ClassEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<String> _selectedTeacherIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel.name);
    _selectedTeacherIds = List<String>.from(widget.classModel.teacherIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedClass = widget.classModel.copyWith(
        name: _nameController.text.trim(),
        teacherIds: _selectedTeacherIds,
      );

      await ref.read(classViewModelProvider.notifier).updateClass(updatedClass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラスを更新しました')),
        );
        Navigator.pop(context, true); // 更新成功を通知
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('クラス編集'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'クラス名',
                      hintText: '例：うさぎ組',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'クラス名を入力してください';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _updateClass(),
                  ),
                  const SizedBox(height: 16),
                  teachers.when(
                    data: (teachersList) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('担任（複数選択可）'),
                        ...teachersList.map((teacher) => CheckboxListTile(
                              value: _selectedTeacherIds.contains(teacher.id),
                              title: Text(teacher.displayName ?? '名前なし'),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedTeacherIds.add(teacher.id);
                                  } else {
                                    _selectedTeacherIds.remove(teacher.id);
                                  }
                                });
                              },
                            )),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('教師一覧の取得に失敗しました'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateClass,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('更新'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }
}
