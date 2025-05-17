import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/model/user_role.dart';
import '../../kindergarten/view/kindergarten_selector.dart';  // for KindergartenSelector & selectedKindergartenIdProvider
import '../../notice/view/notice_list_screen.dart';
import '../../notice/view/notice_detail_screen.dart';
import '../../notice/view/notice_create_screen.dart';
import '../../kindergarten/view/kindergarten_select_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final selectedKindergartenId = user.role == UserRole.admin
            ? ref.watch(selectedKindergartenIdProvider) ?? ''
            : user.kindergartenId;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ホーム'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: '全体連絡'),
                  Tab(text: 'クラス連絡'),
                  Tab(text: '個別連絡'),
                ],
              ),
              actions: [
                if (user.role == UserRole.admin)
                  IconButton(
                    icon: const Icon(Icons.business),
                    tooltip: '園選択',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KindergartenSelectScreen(
                          onSelected: (kindergarten) {
                            ref.read(selectedKindergartenIdProvider.notifier).state = kindergarten.id;
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ref.read(authViewModelProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (user.role == UserRole.admin)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: KindergartenSelector(),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _NoticeFeedTab(kindergartenId: selectedKindergartenId, type: 'all'),
                      _NoticeFeedTab(kindergartenId: selectedKindergartenId, type: 'class'),
                      _NoticeFeedTab(kindergartenId: selectedKindergartenId, type: 'individual'),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
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
                    context.go('/notices/all/$selectedKindergartenId');
                    break;
                  case 2:
                    context.go('/notices/class/$selectedKindergartenId');
                    break;
                  case 3:
                    context.go('/notices/individual/$selectedKindergartenId');
                    break;
                  case 4:
                    if (user.role == UserRole.admin || user.role == UserRole.teacher) {
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
                                  // 園選択画面へ遷移
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
            floatingActionButton: user.role == UserRole.admin || user.role == UserRole.teacher
                ? FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeCreateScreen(
                          kindergartenId: selectedKindergartenId,
                          type: 'all',
                        ),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
        );
      },
      loading: () => const LoadingOverlay(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラー: $e')),
      ),
    );
  }
}

class _NoticeFeedTab extends ConsumerWidget {
  final String kindergartenId;
  final String type;
  const _NoticeFeedTab({required this.kindergartenId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kindergartenId.isEmpty) {
      return const Center(child: Text('園が選択されていません'));
    }
    final noticesAsync = ref.watch(noticeListProvider((kindergartenId, type, null, null)));
    return noticesAsync.when(
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('連絡がありません'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final n = list[index];
            return ListTile(
              title: Text(n.title),
              subtitle: Text(n.content),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoticeDetailScreen(noticeId: n.id)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
    );
  }
}