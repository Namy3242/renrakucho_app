import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../post/view/post_list_screen.dart';
import '../../post/view/post_create_screen.dart';
import '../../../core/widgets/loading_overlay.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
              ),
            ],
          ),
          body: const PostListScreen(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostCreateScreen(),
                ),
              );
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
                icon: Icon(Icons.person),
                label: 'プロフィール',
              ),
            ],
            onDestinationSelected: (index) {
              // TODO: 画面遷移の実装
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