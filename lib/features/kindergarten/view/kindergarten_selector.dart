import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/kindergarten_model.dart';
import '../repository/kindergarten_repository_provider.dart';
import '../../auth/view_model/auth_view_model.dart'; // 追加

final selectedKindergartenIdProvider = StateProvider<String?>((ref) => null);

class KindergartenSelector extends ConsumerWidget {
  const KindergartenSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kindergartensAsync = ref.watch(kindergartensProvider);
    final selectedId = ref.watch(selectedKindergartenIdProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        return kindergartensAsync.when(
          data: (kindergartens) {
            if (kindergartens.isEmpty) {
              return const Text('園がありません。まず園を登録してください。');
            }
            // 管理者は自分のkindergartenIdsのみ表示
            final filtered = (user?.role.toString() == 'UserRole.admin' && user?.kindergartenIds != null)
                ? kindergartens.where((k) => user!.kindergartenIds.contains(k.id)).toList()
                : kindergartens;
            if (filtered.isEmpty) {
              return const Text('あなたに紐付く園がありません。');
            }
            return DropdownButton<String>(
              value: selectedId ?? filtered.first.id,
              items: filtered
                  .map((k) => DropdownMenuItem(
                        value: k.id,
                        child: Text(k.name),
                      ))
                  .toList(),
              onChanged: (id) {
                ref.read(selectedKindergartenIdProvider.notifier).state = id;
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('園一覧取得エラー: $e'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('ユーザー取得エラー: $e'),
    );
  }
}

final kindergartensProvider = FutureProvider<List<KindergartenModel>>((ref) async {
  final repo = ref.read(kindergartenRepositoryProvider);
  return await repo.getKindergartens();
});
