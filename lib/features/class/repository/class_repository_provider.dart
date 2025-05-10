import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_repository.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});
