import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_model/comment_view_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/view_model/auth_view_model.dart';
import 'comment_item.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(commentViewModelProvider(widget.postId).notifier).addComment(
            content: content,
            authorId: currentUser.id,
          );
      _commentController.clear();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentViewModelProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'コメント',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (currentUser.valueOrNull != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'コメントを入力',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        commentsState.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Center(
                child: Text('コメントはありません'),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) => CommentItem(
                comment: comments[index],
                currentUserId: currentUser.valueOrNull?.id,
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('エラーが発生しました: $error'),
          ),
        ),
      ],
    );
  }
}