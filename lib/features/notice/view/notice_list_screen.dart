import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repository/notice_repository_provider.dart';
import 'notice_detail_screen.dart';
import 'notice_create_screen.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/model/user_role.dart';
import '../model/notice_model.dart';

final noticeListProvider = StreamProvider.family<
  List<NoticeModel>,
  (String kindergartenId, String type, String? classId, String? childId)
>((ref, params) {
  final repo = ref.read(noticeRepositoryProvider);

  final (kindergartenId, type, classId, childId) = params;

  if (kindergartenId.isEmpty || type.isEmpty) {
    return const Stream.empty();
  }

  return repo.getNotices(
    kindergartenId: kindergartenId,
    classId: classId,
    childId: childId,
    type: type,
  );
});

class NoticeListScreen extends ConsumerWidget {
  final String kindergartenId;
  final String type;
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
    // 投稿権限チェック
    final currentUser = ref.watch(currentUserProvider).value;
    final canPost = currentUser != null &&
        (currentUser.role == UserRole.admin || currentUser.role == UserRole.teacher);

    // ボトムメニュー用選択インデックス
    final selectedIndex = switch (type) {
      'all' => 2,
      'class' => 3,
      'individual' => 4,
      _ => 0,
    };

    final noticesAsync = ref.watch(noticeListProvider((
      kindergartenId,
      type,
      classId,
      childId,
    )));
    debugPrint('[NoticeListScreen] params: kindergartenId=$kindergartenId, type=$type, classId=$classId, childId=$childId');

    return noticesAsync.when(
      data: (notices) {
        debugPrint('[NoticeListScreen] notices count: ${notices.length}');
        return Scaffold(
          appBar: AppBar(
            title: const Text('連絡一覧'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/home');
              },
            ),
          ),
          body: notices.isEmpty
              ? const Center(child: Text('連絡がありません'))
              : ListView.builder(
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    debugPrint('[NoticeListScreen] notice: $notice');
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
                            builder: (_) => NoticeDetailScreen(noticeId: notice.id),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: canPost
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
              NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
              NavigationDestination(icon: Icon(Icons.campaign), label: '全体連絡'),
              NavigationDestination(icon: Icon(Icons.groups), label: 'クラス連絡'),
              NavigationDestination(icon: Icon(Icons.person_pin), label: '個別連絡'),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  // 設定メニュー or クイックメニュー呼び出し
                  break;
                case 2:
                  context.go('/notices/all/$kindergartenId');
                  break;
                case 3:
                  context.go('/notices/class/$kindergartenId');
                  break;
                case 4:
                  context.go('/notices/individual/$kindergartenId');
                  break;
              }
            },
          ),
        );
      },
      loading: () {
        debugPrint('[NoticeListScreen] loading...');
        return Scaffold(
          appBar: AppBar(
            title: const Text('連絡一覧'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/home');
              },
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
          floatingActionButton: canPost
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
      },
      error: (e, stack) {
        debugPrint('[NoticeListScreen] error: ${e.toString()}');
        debugPrint('[NoticeListScreen] stack: ${stack.toString()}');
        return Scaffold(
          appBar: AppBar(
            title: const Text('連絡一覧'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/home');
              },
            ),
          ),
          body: Center(
            child: Text(
              'エラー: $e\nFirestoreの設定やデータ構造を再確認してください。',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          floatingActionButton: canPost
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
      },
    );
  }
}