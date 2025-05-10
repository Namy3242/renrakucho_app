import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';  // Add this import
import 'package:renrakucho_app/features/class/view/class_edit_screen.dart';
import '../../auth/view_model/user_provider.dart';
import '../../class/view_model/class_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../repository/class_repository_provider.dart'; // 修正されたパス
import '../model/class_model.dart'; // Ensure this is the correct path to ClassModel
import '../../auth/model/user_role.dart';
import '../../../core/widgets/loading_overlay.dart';
import 'widgets/member_list.dart';

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
                          leading: const Icon(Icons.person),
                          title: const Text('担任'),
                          subtitle: ref.watch(userProvider(classModel.teacherId)).when(
                            data: (teacher) => Text(teacher?.displayName ?? '不明'),
                            loading: () => const Text('読み込み中...'),
                            error: (_, __) => const Text('エラー'),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.groups),
                          title: const Text('生徒数'),
                          subtitle: Text('${classModel.studentIds.length}人'),
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
}