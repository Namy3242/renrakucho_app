import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/view_model/user_provider.dart';
import '../../view_model/class_view_model.dart';
import 'add_member_dialog.dart';

class MemberList extends ConsumerWidget {
  const MemberList({
    super.key,
    required this.classId,
    required this.studentIds,
    required this.canEdit,
  });

  final String classId;
  final List<String> studentIds;
  final bool canEdit;

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddMemberDialog(
        existingMembers: studentIds,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(classViewModelProvider.notifier)
            .addMember(classId, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メンバーを追加しました')),
          );
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

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーの削除'),
        content: const Text('このメンバーをクラスから削除してもよろしいですか？'),
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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(classViewModelProvider.notifier)
            .removeMember(classId, studentId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メンバーを削除しました')),
          );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'メンバー一覧',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () => _showAddMemberDialog(context, ref),
                  ),
              ],
            ),
            const Divider(),
            if (studentIds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('メンバーがいません'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studentIds.length,
                itemBuilder: (context, index) {
                  final userId = studentIds[index];
                  return ref.watch(userProvider(userId)).when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.displayName?.characters.first ?? '?',
                          ),
                        ),
                        title: Text(user.displayName ?? '不明なユーザー'),
                        trailing: canEdit
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _confirmRemoveMember(
                                  context,
                                  ref,
                                  userId,
                                ),
                              )
                            : null,
                      );
                    },
                    loading: () => const ListTile(
                      title: Text('読み込み中...'),
                    ),
                    error: (_, __) => const ListTile(
                      title: Text('エラー'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}