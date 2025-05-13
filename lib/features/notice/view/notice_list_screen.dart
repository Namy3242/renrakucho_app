import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/notice_repository.dart';
import '../model/notice_model.dart';
import 'notice_create_screen.dart'; // 追加
import 'notice_detail_screen.dart'; // 追加
import '../../auth/view_model/auth_view_model.dart'; // 追加

final noticeRepositoryProvider = Provider((ref) => NoticeRepository());

final noticeListProvider = StreamProvider.family<List<NoticeModel>, Map<String, String?>>((ref, params) {
  final repo = ref.read(noticeRepositoryProvider);
  return repo.getNotices(
    kindergartenId: params['kindergartenId']!,
    classId: params['classId'],
    childId: params['childId'],
    type: params['type']!,
  );
});

class NoticeListScreen extends ConsumerWidget {
  final String kindergartenId;
  final String type; // 'all', 'class', 'individual'
  final String? classId;
  final String? childId;

  const NoticeListScreen({
    super.key,
    required this.kindergartenId,
    required this.type,
    this.classId,
    this.childId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticeListProvider({
      'kindergartenId': kindergartenId,
      'type': type,
      'classId': classId,
      'childId': childId,
    }));
    final user = ref.watch(currentUserProvider).value;
    final isAllowed = user != null &&
        (user.role.toString() == 'UserRole.admin' || user.role.toString() == 'UserRole.teacher');

    return Scaffold(
      appBar: AppBar(title: Text('連絡一覧')),
      body: noticesAsync.when(
        data: (notices) => ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return ListTile(
              title: Text(notice.title),
              subtitle: Text(notice.content),
              trailing: notice.imageUrl != null
                  ? const Icon(Icons.image)
                  : notice.pdfUrl != null
                      ? const Icon(Icons.picture_as_pdf)
                      : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeDetailScreen(notice: notice),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      floatingActionButton: isAllowed
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeCreateScreen(
                      kindergartenId: kindergartenId,
                      type: type,
                      classId: classId,
                      childId: childId,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: '連絡を作成',
            )
          : null,
    );
  }
}
