import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/notice_model.dart';
import '../repository/notice_repository_provider.dart';
import '../../auth/view_model/user_provider.dart';

final noticeDetailProvider = FutureProvider.family<NoticeModel?, String>((ref, noticeId) async {
  return await ref.watch(noticeRepositoryProvider).getNoticeById(noticeId);
});

class NoticeDetailScreen extends ConsumerWidget {
  final String noticeId;
  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeAsync = ref.watch(noticeDetailProvider(noticeId));
    return Scaffold(
      appBar: AppBar(title: const Text('連絡詳細')),
      body: noticeAsync.when(
        data: (notice) {
          if (notice == null) {
            return const Center(child: Text('連絡が見つかりません'));
          }
          final authorAsync = ref.watch(userProvider(notice.authorId));
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Text(notice.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('作成日: ${notice.createdAt.toLocal()}'),
                const SizedBox(height: 8),
                authorAsync.when(
                  data: (author) => Text('投稿者: ${author?.displayName ?? author?.email ?? notice.authorId}'),
                  loading: () => const Text('投稿者: 読み込み中...'),
                  error: (e, _) => Text('投稿者取得エラー: $e'),
                ),
                const SizedBox(height: 16),
                Text(notice.content, style: Theme.of(context).textTheme.bodyLarge),
                if (notice.imageUrl != null && notice.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Image.network(notice.imageUrl!),
                ],
                if (notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // TODO: PDF表示画面へ遷移
                    },
                    child: const Text('添付PDFを開く'),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
