import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../class/view/class_detail_screen.dart';
import '../model/child_model.dart';
import '../view_model/child_view_model.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import '../../kindergarten/view/kindergarten_selector.dart';
import '../../class/model/class_model.dart';
import '../../class/view_model/class_view_model.dart';

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
  String? _selectedKindergartenId; // 管理者用
  String? _selectedClassId; // クラス選択用

  @override
  void initState() {
    super.initState();
    if (widget.parentId != null && widget.parentId!.isNotEmpty) {
      _selectedParentIds = [widget.parentId!];
    }
    // 管理者の場合は初期値として現在選択中の園IDをセット
    final user = ref.read(currentUserProvider).value;
    if (user?.role.name == 'admin') {
      _selectedKindergartenId = ref.read(selectedKindergartenIdProvider);
    }
    _selectedClassId = widget.classId;
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      String kindergartenId;
      if (user?.role.name == 'admin') {
        kindergartenId = _selectedKindergartenId ?? '';
      } else {
        kindergartenId = user?.kindergartenId ?? '';
      }

      if (kindergartenId.isEmpty) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('園が選択されていません'),
              content: const Text('園を選択してください。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final child = ChildModel(
        id: '',
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        classId: _selectedClassId,
        kindergartenId: kindergartenId,
        parentIds: _selectedParentIds,
      );
      final childId = await ref.read(childViewModelProvider.notifier).createChild(child);
      if (widget.onCreated != null && childId != null) {
        widget.onCreated!(childId);
      }
      // ここでクラス一覧・クラス詳細をinvalidateして即時反映
      if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
        ref.invalidate(classViewModelProvider);
        // クラス詳細画面を開いている場合も即時反映
        // selectedClassProviderはfamilyなので、classIdを指定してinvalidate
        ref.invalidate(selectedClassProvider(_selectedClassId!));
      }
      Navigator.pop(context, childId);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsProvider);
    final user = ref.watch(currentUserProvider).value;

    // 園IDを決定
    final selectedKindergartenId = user?.role.name == 'admin'
        ? _selectedKindergartenId
        : user?.kindergartenId;

    // クラス一覧取得（選択中の園IDでフィルタ）
    final classesAsync = ref.watch(classViewModelProvider);

    return AlertDialog(
      title: const Text('園児を新規作成'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.role.name == 'admin')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Consumer(
                  builder: (context, ref, _) {
                    final kindergartens = ref.watch(kindergartensProvider);
                    return kindergartens.when(
                      data: (list) => DropdownButtonFormField<String>(
                        value: _selectedKindergartenId ?? (list.isNotEmpty ? list.first.id : null),
                        items: list
                            .map((k) => DropdownMenuItem(
                                  value: k.id,
                                  child: Text(k.name),
                                ))
                            .toList(),
                        onChanged: (id) {
                          setState(() {
                            _selectedKindergartenId = id;
                            _selectedClassId = null; // 園が変わったらクラスもリセット
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '園を選択',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('園一覧取得エラー: $e'),
                    );
                  },
                ),
              ),
            // クラス選択ドロップダウン（選択中の園IDでフィルタ）
            classesAsync.when(
              data: (classList) {
                final filtered = classList.where((c) =>
                  c.kindergartenId == selectedKindergartenId
                ).toList();
                return DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  items: filtered
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedClassId = id;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'クラス（任意）',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('クラス一覧取得エラー: $e'),
            ),
            const SizedBox(height: 12),
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
