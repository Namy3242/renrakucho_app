import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import 'package:go_router/go_router.dart';
import '../../child/view_model/child_view_model.dart';
import '../../child/model/child_model.dart';
import '../../child/view_model/child_provider.dart';
import '../../child/view/child_list_screen.dart'; // 追加: allChildrenProviderのimport

class ParentListScreen extends ConsumerWidget {
  const ParentListScreen({super.key});

  Future<void> _addChildToParent(BuildContext context, WidgetRef ref, UserModel parent) async {
    final List<ChildModel> children = await ref.read(allChildrenProvider.future);
    final availableChildren = children.where((c) => !parent.childIds.contains(c.id)).toList();
    String? selectedChildId;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('園児を追加'),
        content: DropdownButtonFormField<String>(
          value: null,
          items: availableChildren
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (v) => selectedChildId = v,
          decoration: const InputDecoration(labelText: '園児を選択'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedChildId != null) {
                // 保護者のchildIdsに追加
                final repo = ref.read(userRepositoryProvider);
                final updated = parent.copyWith(
                  childIds: [...parent.childIds, selectedChildId!],
                );
                await repo.updateUser(updated);
                // 園児のparentIdsにも追加
                final child = await ref.read(childProvider(selectedChildId!).future);
                if (child != null && !child.parentIds.contains(parent.id)) {
                  await ref.read(childViewModelProvider.notifier).updateChild(
                    child.copyWith(parentIds: [...child.parentIds, parent.id]),
                  );
                }
                ref.invalidate(parentsProvider);
                ref.invalidate(childProvider(selectedChildId!));
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(parentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者マスタ'),
      ),
      body: parentsAsync.when(
        data: (parents) {
          if (parents.isEmpty) {
            return const Center(child: Text('保護者がいません'));
          }
          return ListView.builder(
            itemCount: parents.length,
            itemBuilder: (context, index) {
              final parent = parents[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(parent.displayName ?? parent.email),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parent.email),
                    if ((parent.childIds ?? []).isNotEmpty)
                      FutureBuilder(
                        future: Future.wait((parent.childIds ?? []).map((cid) =>
                          ref.read(childProvider(cid).future)
                        )),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final children = snapshot.data!.whereType<ChildModel>().toList();
                          if (children.isEmpty) return const SizedBox();
                          return Text(
                            '園児: ${children.map((c) => c.name).join(", ")}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: '園児を追加',
                  onPressed: () => _addChildToParent(context, ref, parent),
                ),
                onTap: () {
                  // TODO: 編集ダイアログや詳細画面へ遷移
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.class_), label: 'クラス'),
          NavigationDestination(icon: Icon(Icons.child_care), label: '園児'),
          NavigationDestination(icon: Icon(Icons.people), label: '保護者'),
          NavigationDestination(icon: Icon(Icons.school), label: '保育者'),
          NavigationDestination(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              GoRouter.of(context).go('/home');
              break;
            case 1:
              GoRouter.of(context).go('/classes');
              break;
            case 2:
              GoRouter.of(context).go('/children');
              break;
            case 3:
              GoRouter.of(context).go('/parents');
              break;
            case 4:
              GoRouter.of(context).go('/teachers');
              break;
            case 5:
              // TODO: プロフィール画面への遷移
              break;
          }
        },
      ),
    );
  }
}

final parentsProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getParents();
});
