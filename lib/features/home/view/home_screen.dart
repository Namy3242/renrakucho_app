import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../post/view/post_list_screen.dart';
import '../../post/view/post_create_screen.dart';
import '../../kindergarten/view/kindergarten_create_screen.dart';
import '../../kindergarten/view/kindergarten_selector.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'package:go_router/go_router.dart';
import '../../child/view_model/child_view_model.dart';
import '../../child/view/child_list_screen.dart'; // allChildrenProvider
import '../../class/view_model/class_view_model.dart'; // 追加: クラス一覧取得用

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authViewModelProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final allChildrenAsync = ref.watch(allChildrenProvider);
    final classListAsync = ref.watch(classViewModelProvider); // 追加

    // 未紐付園児数
    int unlinkedChildCount = 0;
    allChildrenAsync.whenData((children) {
      unlinkedChildCount = children.where((c) => c.parentIds.isEmpty).length;
    });

    // 担任未設定クラス数
    int unassignedClassCount = 0;
    classListAsync.whenData((classes) {
      unassignedClassCount = classes.where((c) => c.teacherIds.isEmpty).length;
    });

    return currentUser.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(
            title: const Text('ホーム'),
            actions: [
              if (user.role.toString() == 'UserRole.admin')
                IconButton(
                  icon: const Icon(Icons.add_business),
                  tooltip: '園登録',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KindergartenCreateScreen()),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context, ref),
              ),
            ],
          ),
          body: Column(
            children: [
              if (user.role.toString() == 'UserRole.admin')
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: KindergartenSelector(),
                ),
              const Expanded(child: PostListScreen()),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/posts/create');
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home),
                label: 'ホーム',
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    const Icon(Icons.settings),
                    if (unlinkedChildCount > 0 || unassignedClassCount > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${unlinkedChildCount + unassignedClassCount}',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: '設定',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  if (context.mounted) context.go('/home');
                  break;
                case 1:
                  _showQuickMenu(context, user, ref);
                  break;
              }
            },
          ),
        );
      },
      loading: () => const LoadingOverlay(),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context, user, WidgetRef ref) async {
    if (user.role == null) return;
    if (user.role.toString() != 'UserRole.admin' && user.role.toString() != 'UserRole.teacher') {
      return;
    }
    // 最新の未紐付園児数・担任未設定クラス数を取得
    final children = await ref.read(allChildrenProvider.future);
    final unlinked = children.where((c) => c.parentIds.isEmpty).length;
    final classAsync = await ref.read(classViewModelProvider);
    final classes = classAsync.value ?? [];
    final unassigned = classes.where((c) => c.teacherIds.isEmpty).length;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.class_),
                  if (unassigned > 0)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$unassigned',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('クラス'),
              onTap: () {
                Navigator.pop(context);
                context.go('/classes');
              },
            ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.child_care),
                  if (unlinked > 0)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$unlinked',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('園児'),
              onTap: () {
                Navigator.pop(context);
                context.go('/children');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('保護者'),
              onTap: () {
                Navigator.pop(context);
                context.go('/parents');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('保育者'),
              onTap: () {
                Navigator.pop(context);
                context.go('/teachers');
              },
            ),
          ],
        ),
      ),
    );
  }
}