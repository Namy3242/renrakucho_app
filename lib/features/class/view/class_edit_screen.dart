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
  String? _selectedTeacherId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel.name);
    _selectedTeacherId = widget.classModel.teacherId ??
        ref.read(currentUserProvider).value?.id;  // 修正
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
        teacherId: _selectedTeacherId,
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
                    data: (teachersList) => DropdownButtonFormField<String>(
                      value: _selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: '担任',
                      ),
                      items: teachersList.map((teacher) {
                        return DropdownMenuItem(
                          value: teacher.id,
                          child: Text(teacher.displayName ?? '名前なし'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTeacherId = value;
                        });
                      },
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
