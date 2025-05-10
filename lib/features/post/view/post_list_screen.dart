import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_model/post_view_model.dart';
import 'post_detail_screen.dart';
import '../../../core/widgets/loading_overlay.dart';

class PostListScreen extends ConsumerWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postViewModelProvider);

    return postsState.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text('投稿がありません'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(postViewModelProvider);
          },
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: InkWell(
                  onTap: () {
                    context.push('/posts/${post.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title ?? '無題',  // nullの場合は'無題'を表示
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.content ?? '',  // nullの場合は空文字を表示
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (post.imageUrl != null)
                              const Icon(Icons.image),
                            Text(
                              post.createdAt.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingOverlay(),
      error: (error, _) => Center(
        child: Text('エラーが発生しました: $error'),
      ),
    );
  }
}
