import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/notice_repository.dart';
import '../model/notice_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/repository/user_repository_provider.dart'; // 追加

class NoticeDetailScreen extends ConsumerWidget {
  final NoticeModel notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final repo = ref.read(noticeRepositoryProvider);

    // 投稿者名取得
    final authorAsync = ref.watch(_authorProvider(notice.authorId));

    return Scaffold(
      appBar: AppBar(title: Text(notice.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            authorAsync.when(
              data: (author) => Text(
                '投稿者: ${author?.displayName ?? author?.email ?? notice.authorId}  投稿日: ${notice.createdAt.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              loading: () => const SizedBox(height: 16),
              error: (_, __) => const SizedBox(height: 16),
            ),
            const SizedBox(height: 8),
            Text(notice.content),
            if (notice.imageUrl != null) ...[
              const SizedBox(height: 8),
              Image.network(notice.imageUrl!),
            ],
            if (notice.pdfUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf),
                  const SizedBox(width: 4),
                  Text(notice.pdfUrl!),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  color: notice.reactions[user?.id] == 'like' ? Colors.blue : null,
                  onPressed: user == null
                      ? null
                      : () => repo.addReaction(notice.id, user.id, 'like'),
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down),
                  color: notice.reactions[user?.id] == 'dislike' ? Colors.red : null,
                  onPressed: user == null
                      ? null
                      : () => repo.addReaction(notice.id, user.id, 'dislike'),
                ),
                Text('リアクション: ${notice.reactions.length}'),
              ],
            ),
            if (notice.type == 'individual') ...[
              const Divider(),
              const Text('返信'),
              _ReplySection(noticeId: notice.id),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplySection extends ConsumerStatefulWidget {
  final String noticeId;
  const _ReplySection({required this.noticeId, super.key});

  @override
  ConsumerState<_ReplySection> createState() => _ReplySectionState();
}

class _ReplySectionState extends ConsumerState<_ReplySection> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _controller.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    await ref.read(noticeRepositoryProvider).addReply(widget.noticeId, user.id, _controller.text.trim());
    _controller.clear();
    setState(() => _isSending = false);
  }

  Future<String?> _getUserDisplayName(String userId) async {
    final repo = ref.read(userRepositoryProvider);
    final user = await repo.getUserById(userId);
    return user?.displayName ?? user?.email;
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(_repliesProvider(widget.noticeId));
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: '返信を入力'),
                enabled: !_isSending,
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _isSending ? null : _sendReply,
            ),
          ],
        ),
        repliesAsync.when(
          data: (replies) => replies.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('返信はまだありません', style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: replies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = replies[index];
                    return FutureBuilder<String?>(
                      future: _getUserDisplayName(r['userId'] ?? ''),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? (r['userId'] ?? '');
                        final date = r['createdAt'] != null
                            ? DateTime.tryParse(r['createdAt'])?.toLocal().toString().substring(0, 16)
                            : '';
                        return ListTile(
                          title: Text(r['content'] ?? ''),
                          subtitle: Text('$name  $date'),
                        );
                      },
                    );
                  },
                ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('エラー: $e'),
        ),
      ],
    );
  }
}

final _repliesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, noticeId) {
  return ref.read(noticeRepositoryProvider).getReplies(noticeId);
});

final _authorProvider = FutureProvider.family.autoDispose((ref, String userId) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getUserById(userId);
});
