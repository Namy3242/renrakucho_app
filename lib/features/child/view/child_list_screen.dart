import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import '../../class/view_model/class_view_model.dart';
import '../model/child_model.dart';
import '../view_model/child_provider.dart';
import '../view_model/child_view_model.dart';
import '../view/child_create_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../auth/view_model/auth_view_model.dart'; // 追加

class ChildListScreen extends ConsumerWidget {
  const ChildListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(allChildrenProvider);

    // 未紐付園児数を計算
    int unlinkedCount = 0;
    childrenAsync.whenData((children) {
      unlinkedCount = children.where((c) => c.parentIds.isEmpty).length;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('園児マスタ'),
      ),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return const Center(child: Text('園児がいません'));
          }
          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final isUnlinked = child.parentIds.isEmpty;
              return Card(
                color: isUnlinked ? Colors.red[50] : null,
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(child: Text(child.name.characters.first)),
                      if (isUnlinked)
                        const Positioned(
                          right: -2, top: -2,
                          child: Icon(Icons.warning, color: Colors.red, size: 18),
                        ),
                    ],
                  ),
                  title: Text(child.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('年齢: ${child.age ?? '-'}${isUnlinked ? "（保護者未紐付）" : ""}'),
                      if (child.parentIds.isNotEmpty)
                        FutureBuilder(
                          future: Future.wait(child.parentIds.map((pid) async =>
                            await ref.read(userRepositoryProvider).getUserById(pid)
                          )),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final parents = snapshot.data!.whereType<UserModel>().toList();
                            if (parents.isEmpty) return const SizedBox();
                            return Text(
                              '保護者: ${parents.map((p) => p.displayName ?? p.email).join(", ")}',
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.vpn_key),
                    tooltip: '招待コード発行',
                    onPressed: () async {
                      final code = await ref.read(childViewModelProvider.notifier)
                        .createInviteCode(child);
                      if (context.mounted && code != null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('招待コード'),
                            content: SelectableText(code),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('閉じる'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    // TODO: 編集ダイアログや詳細画面へ遷移
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => ChildCreateDialog(),
          );
          ref.invalidate(allChildrenProvider);
          ref.invalidate(classViewModelProvider); // 追加: クラス一覧も再取得
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final children = ref.watch(allChildrenProvider).value ?? [];
          final unlinked = children.where((c) => c.parentIds.isEmpty).length;
          final currentUser = ref.watch(currentUserProvider).value;
          return NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
              NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  GoRouter.of(context).go('/home');
                  break;
                case 1:
                  if (currentUser != null && (currentUser.role.name == 'admin' || currentUser.role.name == 'teacher')) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.class_),
                              title: const Text('クラス'),
                              onTap: () {
                                Navigator.pop(context);
                                GoRouter.of(context).go('/classes');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.child_care),
                              title: const Text('園児'),
                              onTap: () {
                                Navigator.pop(context);
                                GoRouter.of(context).go('/children');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: const Text('保護者'),
                              onTap: () {
                                Navigator.pop(context);
                                GoRouter.of(context).go('/parents');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.school),
                              title: const Text('保育者'),
                              onTap: () {
                                Navigator.pop(context);
                                GoRouter.of(context).go('/teachers');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  break;
              }
            },
          );
        },
      ),
    );
  }
}

// 全園児取得Provider
final allChildrenProvider = FutureProvider<List<ChildModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('children').get();
  return snapshot.docs.map((doc) => ChildModel.fromJson(doc.data(), doc.id)).toList();
});
