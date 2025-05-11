import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/child_model.dart';
import '../repository/child_repository_provider.dart';

final childProvider = FutureProvider.family<ChildModel?, String>((ref, childId) async {
  return await ref.watch(childRepositoryProvider).getChildById(childId);
});
