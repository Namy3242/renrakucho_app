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

class ChildListScreen extends ConsumerWidget {
  const ChildListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(allChildrenProvider);

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
              return ListTile(
                leading: CircleAvatar(child: Text(child.name.characters.first)),
                title: Text(child.name),
                subtitle: Text('年齢: ${child.age ?? '-'}'),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
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

// 全園児取得Provider
final allChildrenProvider = FutureProvider<List<ChildModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('children').get();
  return snapshot.docs.map((doc) => ChildModel.fromJson(doc.data(), doc.id)).toList();
});
