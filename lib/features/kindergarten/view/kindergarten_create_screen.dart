import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/kindergarten_repository_provider.dart';
import '../../auth/view_model/auth_view_model.dart'; // 追加
import '../view/kindergarten_selector.dart'; // 修正: kindergartensProviderのimport

class KindergartenCreateScreen extends ConsumerStatefulWidget {
  const KindergartenCreateScreen({super.key});

  @override
  ConsumerState<KindergartenCreateScreen> createState() => _KindergartenCreateScreenState();
}

class _KindergartenCreateScreenState extends ConsumerState<KindergartenCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createKindergarten(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider).value;
      final adminUserId = currentUser?.id ?? '';
      await ref.read(kindergartenRepositoryProvider).createKindergarten(
        _nameController.text.trim(),
        adminUserId: adminUserId,
      );
      // 追加: 園リストを再取得
      ref.invalidate(kindergartensProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('園を登録しました')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('園を登録')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '園名'),
                validator: (v) => v == null || v.isEmpty ? '園名を入力してください' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _createKindergarten(context),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
