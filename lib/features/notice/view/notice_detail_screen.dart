import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../model/notice_model.dart';
import '../repository/notice_repository_provider.dart';
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
          final currentUser = ref.watch(currentUserProvider).value;
          final canModify = currentUser != null &&
              (currentUser.role == UserRole.admin || currentUser.id == notice.authorId);
          final isMe = currentUser?.id == notice.authorId;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // メッセージバブル
                    Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) const CircleAvatar(child: Icon(Icons.person)),
                        if (!isMe) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy/MM/dd HH:mm').format(notice.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 8),
                        if (isMe) const CircleAvatar(child: Icon(Icons.person)),
                      ],
                    ),
                    // 添付画像
                    if (notice.imageUrl != null && notice.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) const SizedBox(width: 40),
                          Flexible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: notice.imageUrl!,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 40),
                        ],
                      ),
                    ],
                    // 添付PDF
                    if (notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(notice.pdfUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDFを表示'),
                      ),
                    ],
                  ],
                ),
              ),
              // 編集／削除
              if (canModify)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('編集')),
                    TextButton(onPressed: () {}, child: const Text('削除', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
