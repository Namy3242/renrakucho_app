import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repository/notice_repository_provider.dart';
import 'notice_detail_screen.dart';
import 'notice_create_screen.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/model/user_role.dart';
import '../model/notice_model.dart';
import 'package:intl/intl.dart';
import '../../child/view/child_list_screen.dart';
import '../../kindergarten/view/kindergarten_selector.dart';  // for selectedKindergartenIdProvider
import '../../kindergarten/view/kindergarten_select_screen.dart';

final noticeListProvider = StreamProvider.family<
  List<NoticeModel>,
  (String kindergartenId, String type, String? classId, String? childId)
>((ref, params) {
  final repo = ref.read(noticeRepositoryProvider);

  final (kindergartenId, type, classId, childId) = params;

  if (kindergartenId.isEmpty || type.isEmpty) {
    return const Stream.empty();
  }

  // 保護者は自身の子どものクラス連絡のみ取得
  if (type == 'class') {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser != null && currentUser.role == UserRole.parent) {
      final children = ref.watch(allChildrenProvider).maybeWhen(data: (list) => list, orElse: () => []);
      final myChild = children.firstWhere(
        (c) => c.parentIds.contains(currentUser.id),
        orElse: () => null,
      );
      final filterClassId = myChild?.classId;
      if (filterClassId == null) return const Stream.empty();
      return repo.getNotices(
        kindergartenId: kindergartenId,
        classId: filterClassId,
        childId: null,
        type: type,
      );
    }
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

    // ボトムメニュー用選択インデックス (Home と同じ並び)
    final selectedIndex = switch (type) {
      'all' => 1,
      'class' => 2,
      'individual' => 3,
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
        // リスト取得完了
        debugPrint('[NoticeListScreen] notices count: ${notices.length}');
        // 保護者フィルター: 子どものクラスのみ表示
        var displayNotices = notices;
        if (type == 'class' && currentUser?.role == UserRole.parent) {
          final children = ref.watch(allChildrenProvider).valueOrNull ?? [];
          final myClassIds = children
              .where((c) => c.parentIds.contains(currentUser!.id))
              .map((c) => c.classId)
              .whereType<String>()
              .toSet();
          displayNotices = displayNotices.where((n) => n.classId != null && myClassIds.contains(n.classId)).toList();
        }
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
          body: displayNotices.isEmpty
              ? const Center(child: Text('連絡がありません'))
              : ListView.builder(
                  itemCount: displayNotices.length,
                  itemBuilder: (context, index) {
                    final notice = displayNotices[index];
                    debugPrint('[NoticeListScreen] notice: $notice');
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoticeDetailScreen(noticeId: notice.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notice.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notice.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(notice.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
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
              NavigationDestination(icon: Icon(Icons.campaign), label: '全体連絡'),
              NavigationDestination(icon: Icon(Icons.groups), label: 'クラス連絡'),
              NavigationDestination(icon: Icon(Icons.person_pin), label: '個別連絡'),
              NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.go('/notices/all/$kindergartenId');
                  break;
                case 2:
                  context.go('/notices/class/$kindergartenId');
                  break;
                case 3:
                  context.go('/notices/individual/$kindergartenId');
                  break;
                case 4:
                  if (currentUser != null && (currentUser.role == UserRole.admin || currentUser.role == UserRole.teacher)) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.class_),
                              title: const Text('クラス管理'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/classes');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.child_care),
                              title: const Text('園児管理'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/children');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: const Text('保護者管理'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/parents');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.school),
                              title: const Text('保育者管理'),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/teachers');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.business),
                              title: const Text('園管理'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KindergartenSelectScreen(
                                      onSelected: (kg) {
                                        ref.read(selectedKindergartenIdProvider.notifier).state = kg.id;
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
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