import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/model/user_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
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

final teachersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getTeachers();
});
