import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/view_model/auth_view_model.dart'; // 追加

class TeacherListScreen extends ConsumerWidget {
  const TeacherListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保育者マスタ'),
      ),
      body: teachersAsync.when(
        data: (teachers) {
          if (teachers.isEmpty) {
            return const Center(child: Text('保育者がいません'));
          }
          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return ListTile(
                leading: const Icon(Icons.school),
                title: Text(teacher.displayName ?? teacher.email),
                subtitle: Text(teacher.email),
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
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
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

final teachersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getTeachers();
});
