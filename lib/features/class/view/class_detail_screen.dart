import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';  // Add this import
import 'package:renrakucho_app/features/class/view/class_edit_screen.dart';
import '../../auth/view_model/user_provider.dart';
import '../../child/model/child_model.dart';
import '../../child/view_model/child_provider.dart';
import '../../class/view_model/class_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../repository/class_repository_provider.dart'; // 修正されたパス
import '../model/class_model.dart'; // Ensure this is the correct path to ClassModel
import '../../auth/model/user_role.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'widgets/member_list.dart';
import '../../kindergarten/model/kindergarten_model.dart';
import '../../kindergarten/repository/kindergarten_repository_provider.dart';

final selectedClassProvider = FutureProvider.family<ClassModel?, String>((ref, classId) async {
  return await ref.watch(classRepositoryProvider).getClassById(classId);
});

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({
    super.key,
    required this.classId,
  });

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classState = ref.watch(selectedClassProvider(classId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: classState.whenOrNull(
          data: (classModel) => Text(classModel?.name ?? 'クラス詳細'),
        ),
        actions: [
          if (currentUser.valueOrNull?.role == UserRole.teacher || 
              currentUser.valueOrNull?.role == UserRole.admin)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('編集'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('削除'),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    final classModel = classState.value;
                    if (classModel != null) {
                      if (context.mounted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassEditScreen(classModel: classModel),
                          ),
                        );
                        if (result == true && context.mounted) {
                          ref.invalidate(selectedClassProvider(classId));
                          ref.invalidate(classViewModelProvider);
                        }
                      }
                    }
                    break;
                  case 'delete':
                    await _confirmDelete(context, ref);
                    break;
                }
              },
            ),
        ],
      ),
      body: classState.when(
        data: (classModel) {
          if (classModel == null) {
            return const Center(
              child: Text('クラスが見つかりません'),
            );
          }

          final kindergartenAsync = ref.watch(_kindergartenProvider(classModel.kindergartenId));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(selectedClassProvider(classId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'クラス情報',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.school),
                          title: const Text('クラス名'),
                          subtitle: Text(classModel.name),
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('園名'),
                          subtitle: kindergartenAsync.when(
                            data: (kg) => Text(kg?.name ?? '不明'),
                            loading: () => const Text('読み込み中...'),
                            error: (_, __) => const Text('エラー'),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('担任'),
                          subtitle: _TeachersNamesWidget(teacherIds: classModel.teacherIds),
                        ),
                        ListTile(
                          leading: const Icon(Icons.groups),
                          title: const Text('生徒数'),
                          subtitle: FutureBuilder<List<ChildModel?>>(
                            future: Future.wait(
                              classModel.studentIds.map((id) => ref.watch(childProvider(id).future)),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('読み込み中...');
                              }
                              final count = snapshot.data!
                                  .where((child) => child != null)
                                  .length;
                              return Text('$count人');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MemberList(
                  classId: classId,
                  studentIds: classModel.studentIds,
                  canEdit: currentUser.valueOrNull?.role == UserRole.teacher || 
                          currentUser.valueOrNull?.role == UserRole.admin,
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (error, _) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クラスの削除'),
        content: const Text('このクラスを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '削除',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(classViewModelProvider.notifier).deleteClass(classId);
        if (context.mounted) {
          Navigator.pop(context); // context.pop() から変更
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  // 園情報取得Provider
  static final _kindergartenProvider = FutureProvider.family<KindergartenModel?, String>((ref, kindergartenId) async {
    final repo = ref.read(kindergartenRepositoryProvider);
    final doc = await repo.getKindergartenById(kindergartenId);
    return doc;
  });
}

// 複数担任名表示用ウィジェット
class _TeachersNamesWidget extends ConsumerWidget {
  final List<String> teacherIds;
  const _TeachersNamesWidget({required this.teacherIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (teacherIds.isEmpty) return const Text('未設定');
    return FutureBuilder<List<String>>(
      future: () async {
        final futures = teacherIds.map((id) => ref.read(userProvider(id).future)).toList();
        final users = await Future.wait(futures);
        return users.map((u) => u?.displayName ?? u?.email ?? '不明').toList();
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('読み込み中...');
        return Text(snapshot.data!.join(', '));
      },
    );
  }
}