import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/child_model.dart';
import '../view_model/child_view_model.dart';

class ChildEditDialog extends ConsumerStatefulWidget {
  final ChildModel child;
  final String? classId;
  const ChildEditDialog({super.key, required this.child, this.classId});

  @override
  ConsumerState<ChildEditDialog> createState() => _ChildEditDialogState();
}

class _ChildEditDialogState extends ConsumerState<ChildEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  bool _isLoading = false;
  List<String> _selectedParentIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _ageController = TextEditingController(text: widget.child.age?.toString() ?? '');
    _selectedParentIds = List<String>.from(widget.child.parentIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('園児情報の編集'),
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
            Consumer(
              builder: (context, ref, _) {
                final parentsAsync = ref.watch(parentsProvider);
                return parentsAsync.when(
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
                      if (_selectedParentIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '※保護者を1人以上選択してください',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('保護者の取得に失敗しました'),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  // 園児自体を削除
                  setState(() => _isLoading = true);
                  await ref.read(childViewModelProvider.notifier).deleteChild(widget.child.id);
                  if (mounted) Navigator.pop(context);
                },
          child: const Text('園児を削除', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedParentIds.isEmpty) {
                    setState(() {}); // エラー表示のため再描画
                    return;
                  }
                  setState(() => _isLoading = true);
                  final updated = widget.child.copyWith(
                    name: _nameController.text.trim(),
                    age: int.tryParse(_ageController.text),
                    parentIds: _selectedParentIds,
                  );
                  await ref.read(childViewModelProvider.notifier).updateChild(updated);
                  if (mounted) Navigator.pop(context);
                },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
