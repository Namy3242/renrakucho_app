import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../post/view/post_list_screen.dart';
import '../../post/view/post_create_screen.dart';
import '../../kindergarten/view/kindergarten_create_screen.dart';
import '../../kindergarten/view/kindergarten_selector.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'package:go_router/go_router.dart';

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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'ホーム',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: '設定',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  if (context.mounted) context.go('/home');
                  break;
                case 1:
                  // 設定ボタン押下時
                  _showQuickMenu(context, user);
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

  void _showQuickMenu(BuildContext context, user) {
    if (user.role == null) return;
    if (user.role.toString() != 'UserRole.admin' && user.role.toString() != 'UserRole.teacher') {
      // 一般ユーザーは何も表示しない
      return;
    }
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
                context.go('/classes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.child_care),
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