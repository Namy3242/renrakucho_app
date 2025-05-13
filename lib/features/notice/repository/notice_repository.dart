import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notice_model.dart';

class NoticeRepository {
  final _noticesRef = FirebaseFirestore.instance.collection('notices');

  Future<void> addNotice(NoticeModel notice) async {
    final docRef = _noticesRef.doc();
    await docRef.set(notice.toJson());
  }

  Stream<List<NoticeModel>> getNotices({
    required String kindergartenId,
    String? classId,
    String? childId,
    required String type, // 'all', 'class', 'individual'
  }) {
    var query = _noticesRef.where('kindergartenId', isEqualTo: kindergartenId).where('type', isEqualTo: type);
    if (type == 'class' && classId != null) {
      query = query.where('classId', isEqualTo: classId);
    }
    if (type == 'individual' && childId != null) {
      query = query.where('childId', isEqualTo: childId);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => NoticeModel.fromJson(doc.data(), doc.id)).toList(),
    );
  }

  Future<void> addReaction(String noticeId, String userId, String reaction) async {
    await _noticesRef.doc(noticeId).update({'reactions.$userId': reaction});
  }

  // 個別連絡の返信（サブコレクション）
  Future<void> addReply(String noticeId, String userId, String content) async {
    final replyRef = _noticesRef.doc(noticeId).collection('replies').doc();
    await replyRef.set({
      'userId': userId,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> getReplies(String noticeId) {
    return _noticesRef.doc(noticeId).collection('replies').orderBy('createdAt').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }
}
