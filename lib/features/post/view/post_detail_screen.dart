import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../model/post.dart';
import '../repository/post_repository_provider.dart';
import '../view_model/comment_view_model.dart';
import '../view_model/post_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/utils/date_formatter.dart';
import 'widgets/comment_section.dart';  // コメントセクションを別ファイルに分離

final selectedPostProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final repository = ref.watch(postRepositoryProvider);
  return await repository.getPostById(postId);
});

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(selectedPostProvider(postId));
    final currentUser = ref.watch(currentUserProvider);

    return postState.when(
      data: (post) {
        if (post == null) {
          return const Scaffold(
            body: Center(child: Text('投稿が見つかりません')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('投稿詳細'),
            actions: [
              if (currentUser.valueOrNull?.id == post.authorId)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, ref, post),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? '無題',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(post.authorId),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.format(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Divider(height: 32),
                      CommentSection(postId: post.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿の削除'),
        content: const Text('この投稿を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(postViewModelProvider.notifier).deletePost(post.id);
        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }
}