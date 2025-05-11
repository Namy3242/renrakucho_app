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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _ageController = TextEditingController(text: widget.child.age?.toString() ?? '');
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
            // 保護者・クラスの紐付け編集UIもここに追加可能
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
                  setState(() => _isLoading = true);
                  final updated = widget.child.copyWith(
                    name: _nameController.text.trim(),
                    age: int.tryParse(_ageController.text),
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
