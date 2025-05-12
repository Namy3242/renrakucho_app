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
              if (user.role.name == 'admin')
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
              if (user.role.name == 'admin')
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: KindergartenSelector(),
                ),
              const Expanded(child: PostListScreen()),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/posts/create');  // MaterialRouteから変更
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
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
                icon: Icon(Icons.child_care),
                label: '園児',
              ),
              NavigationDestination(
                icon: Icon(Icons.people),
                label: '保護者',
              ),
              NavigationDestination(
                icon: Icon(Icons.school),
                label: '保育者',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'プロフィール',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  if (context.mounted) context.go('/home');
                  break;
                case 1:
                  if (context.mounted) context.go('/classes');
                  break;
                case 2:
                  if (context.mounted) context.go('/children');
                  break;
                case 3:
                  if (context.mounted) context.go('/parents');
                  break;
                case 4:
                  if (context.mounted) context.go('/teachers');
                  break;
                case 5:
                  // TODO: プロフィール画面への遷移を実装
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
}