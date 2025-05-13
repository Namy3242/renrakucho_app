import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_role.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../model/kindergarten_model.dart';
import '../repository/kindergarten_repository_provider.dart';

final kindergartensProvider = FutureProvider<List<KindergartenModel>>((ref) async {
  final repo = ref.read(kindergartenRepositoryProvider);
  return await repo.getKindergartens();
});

class KindergartenSelectScreen extends ConsumerWidget {
  final void Function(KindergartenModel) onSelected;
  const KindergartenSelectScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final kindergartensAsync = ref.watch(kindergartensProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('園を選択')),
      body: kindergartensAsync.when(
        data: (kindergartens) => ListView.builder(
          itemCount: kindergartens.length,
          itemBuilder: (context, index) {
            final kindergarten = kindergartens[index];
            return ListTile(
              title: Text(kindergarten.name),
              onTap: () => onSelected(kindergarten),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      floatingActionButton: (currentUser?.role == UserRole.admin)
          ? FloatingActionButton(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => _KindergartenCreateDialog(),
                );
                if (name != null && name.isNotEmpty) {
                  // 管理者IDを渡す
                  await ref.read(kindergartenRepositoryProvider).createKindergarten(
                    name,
                    adminUserId: currentUser!.id,
                  );
                  ref.invalidate(kindergartensProvider);
                }
              },
              child: const Icon(Icons.add),
              tooltip: '園を新規作成',
            )
          : null,
    );
  }
}

class _KindergartenCreateDialog extends StatefulWidget {
  @override
  State<_KindergartenCreateDialog> createState() => _KindergartenCreateDialogState();
}

class _KindergartenCreateDialogState extends State<_KindergartenCreateDialog> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しい園を作成'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: '園名'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('作成'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
