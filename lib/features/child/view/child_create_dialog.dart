import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/child_model.dart';
import '../view_model/child_view_model.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';

class ChildCreateDialog extends ConsumerStatefulWidget {
  final String? parentId;
  final String? classId;
  final void Function(String childId)? onCreated;

  const ChildCreateDialog({
    super.key,
    this.parentId,
    this.classId,
    this.onCreated,
  });

  @override
  ConsumerState<ChildCreateDialog> createState() => _ChildCreateDialogState();
}

class _ChildCreateDialogState extends ConsumerState<ChildCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  List<String> _selectedParentIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.parentId != null && widget.parentId!.isNotEmpty) {
      _selectedParentIds = [widget.parentId!];
    }
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final child = ChildModel(
        id: '',
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        classId: widget.classId,
        parentIds: _selectedParentIds,
      );
      final childId = await ref.read(childViewModelProvider.notifier).createChild(child);
      if (widget.onCreated != null && childId != null) {
        widget.onCreated!(childId);
      }
      Navigator.pop(context, childId);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsProvider);

    return AlertDialog(
      title: const Text('園児を新規作成'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名前'),
              validator: (v) => v == null || v.isEmpty ? '名前を入力してください' : null,
            ),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: '年齢'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            parentsAsync.when(
              data: (parents) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('保護者を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...parents.map((parent) => CheckboxListTile(
                        value: _selectedParentIds.contains(parent.id),
                        title: Text(parent.displayName ?? parent.email),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedParentIds.add(parent.id);
                            } else {
                              _selectedParentIds.remove(parent.id);
                            }
                          });
                        },
                      )),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('保護者の取得に失敗しました'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createChild,
          child: const Text('作成'),
        ),
      ],
    );
  }
}

// 保護者一覧取得用Provider（既存のものを流用）
final parentsProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getParents();
});
