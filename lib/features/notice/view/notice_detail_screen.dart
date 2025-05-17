import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/notice_model.dart';
import '../repository/notice_repository_provider.dart';
import '../../auth/view_model/user_provider.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/model/user_role.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // 現在ユーザー・権限チェック
          final currentUser = ref.watch(currentUserProvider).value;
          final canModify = currentUser != null &&
              (currentUser.role == UserRole.admin || currentUser.id == notice.authorId);
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
                  // スタイル付き画像プレビュー（タップで拡大）
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: notice.imageUrl!,
                            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                    child: Hero(
                      tag: notice.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: notice.imageUrl!,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ],
                if (notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // PDFリンクを外部ビューアで開く
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(notice.pdfUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDFを開けませんでした')),
                        );
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDFを表示'),
                  ),
                ],
                if (canModify) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: 編集機能実装
                        },
                        child: const Text('編集'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('削除の確認'),
                              content: const Text('本当にこの連絡を削除しますか？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(noticeRepositoryProvider).deleteNotice(notice.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('削除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
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
