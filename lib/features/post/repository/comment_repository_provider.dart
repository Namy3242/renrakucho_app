import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'comment_repository.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository();
});