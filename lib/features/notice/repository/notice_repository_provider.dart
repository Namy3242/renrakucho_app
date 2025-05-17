import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notice_repository.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository();
});
