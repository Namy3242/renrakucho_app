import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../class/view_model/class_view_model.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/model/user_role.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository.dart';
import '../../auth/repository/user_repository_provider.dart';
import '../../kindergarten/view/kindergarten_selector.dart';

final teachersProvider = FutureProvider<List<UserModel>>((ref) async {
  return await ref.read(userRepositoryProvider).getTeachers();
});

class ClassCreateScreen extends ConsumerStatefulWidget {
  const ClassCreateScreen({super.key});

  @override
  ConsumerState<ClassCreateScreen> createState() => _ClassCreateScreenState();
}

class _ClassCreateScreenState extends ConsumerState<ClassCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  List<String> _selectedTeacherIds = [];

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(currentUserProvider).value?.id;
    if (currentUserId != null) {
      _selectedTeacherIds = [currentUserId];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      // 管理者は選択中の園IDを使う
      final kindergartenId = currentUser.role.name == 'admin'
          ? ref.read(selectedKindergartenIdProvider)
          : currentUser.kindergartenId;

      if (kindergartenId == null || kindergartenId.isEmpty) {
        throw Exception('園が選択されていません');
      }

      await ref.read(classViewModelProvider.notifier).createClass(
            name: _nameController.text.trim(),
            teacherIds: _selectedTeacherIds,
            kindergartenId: kindergartenId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラスを作成しました')),
        );
        Navigator.pop(context);
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
            title: const Text('クラス作成'),
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
                    onFieldSubmitted: (_) => _createClass(),
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
                    onPressed: _isLoading ? null : _createClass,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('作成'),
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