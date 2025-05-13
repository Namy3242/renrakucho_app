import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/view_model/user_provider.dart';
import '../../../child/view/child_edit_dialog.dart';
import '../../view_model/class_view_model.dart';
import '../class_detail_screen.dart';
import 'add_member_dialog.dart';
import '../../../child/view_model/child_provider.dart'; // 園児Providerをインポート
import '../../../child/model/child_model.dart';

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
        // クラス一覧・クラス詳細を再取得して即時反映
        ref.invalidate(classViewModelProvider);
        ref.invalidate(selectedClassProvider(classId));
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
    // studentIdsからnullでない園児のみカウント・表示
    final memberFutures = studentIds.map((id) => ref.watch(childProvider(id).future)).toList();

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
            FutureBuilder<List<ChildModel?>>(
              future: Future.wait(memberFutures),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final children = snapshot.data!
                    .where((child) => child != null)
                    .toList();

                if (children.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('メンバーがいません'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index]!;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          child.name.characters.first,
                        ),
                      ),
                      title: Text(child.name),
                      subtitle: Text('年齢: ${child.age ?? '-'}'),
                      trailing: canEdit
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _confirmRemoveMember(
                                context,
                                ref,
                                child.id,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}