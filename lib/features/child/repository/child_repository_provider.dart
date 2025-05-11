import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'child_repository.dart';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository();
});
