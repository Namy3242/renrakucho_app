import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/model/user_role.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../child/model/child_model.dart';
import '../../child/view_model/child_provider.dart';
import '../../class/view_model/class_view_model.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/utils/permission_utils.dart';

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(classViewModelProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('クラス一覧'),
      ),
      body: classesState.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Text('クラスがありません'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(classViewModelProvider);
            },
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classModel = classes[index];
                final memberFutures = classModel.studentIds.map((id) => ref.watch(childProvider(id).future)).toList();

                return FutureBuilder<List<ChildModel?>>(
                  future: Future.wait(memberFutures),
                  builder: (context, snapshot) {
                    int realCount = 0;
                    if (snapshot.hasData) {
                      realCount = snapshot.data!.where((child) => child != null).length;
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(classModel.name),
                        subtitle: Text('生徒数: $realCount人'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            currentUser.whenOrNull(
                              data: (user) => user != null && PermissionUtils.canManageClass(user.role)
                                  ? IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        if (PermissionUtils.canEditClass(
                                          user.role,
                                          teacherId: classModel.teacherId,
                                          userId: user.id,
                                        )) {
                                          if (context.mounted) context.push('/classes/${classModel.id}/edit');
                                        } else {
                                          PermissionUtils.showNoPermissionDialog(context);
                                        }
                                      },
                                    )
                                  : null,
                            ) ?? const SizedBox.shrink(),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          if (context.mounted) context.push('/classes/${classModel.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
      floatingActionButton: currentUser.whenOrNull(
        data: (user) => user?.role == UserRole.teacher || user?.role == UserRole.admin
            ? FloatingActionButton(
                onPressed: () => context.push('/classes/create'),
                child: const Icon(Icons.add),
              )
            : null,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1, // クラス画面を選択状態に
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_),
            label: 'クラス',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/classes');
              break;
            case 2:
              // TODO: プロフィール画面への遷移を実装
              break;
          }
        },
      ),
    );
  }
}