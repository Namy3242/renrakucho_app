import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/kindergarten_model.dart';
import '../repository/kindergarten_repository_provider.dart';

final selectedKindergartenIdProvider = StateProvider<String?>((ref) => null);

class KindergartenSelector extends ConsumerWidget {
  const KindergartenSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kindergartensAsync = ref.watch(kindergartensProvider);
    final selectedId = ref.watch(selectedKindergartenIdProvider);

    return kindergartensAsync.when(
      data: (kindergartens) {
        if (kindergartens.isEmpty) {
          return const Text('園がありません。まず園を登録してください。');
        }
        return DropdownButton<String>(
          value: selectedId ?? kindergartens.first.id,
          items: kindergartens
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
  }
}

final kindergartensProvider = FutureProvider<List<KindergartenModel>>((ref) async {
  final repo = ref.read(kindergartenRepositoryProvider);
  return await repo.getKindergartens();
});
