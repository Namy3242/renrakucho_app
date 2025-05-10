import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/post_view_model.dart';
import '../model/post.dart';

class PostListScreen extends ConsumerWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(postViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿一覧'),
      ),
      body: postState.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('投稿がありません'));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                title: Text(post.content),
                subtitle: Text(post.createdAt.toIso8601String()),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }
}
// This screen displays a list of posts fetched from the PostViewModel.
