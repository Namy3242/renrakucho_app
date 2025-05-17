import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notice_model.dart';

class NoticeRepository {
  final _collection = FirebaseFirestore.instance.collection('notices');

  Stream<List<NoticeModel>> getNotices({
    required String kindergartenId,
    String? classId,
    String? childId,
    required String type,
  }) {
    Query query = _collection.where('kindergartenId', isEqualTo: kindergartenId).where('type', isEqualTo: type);
    if (classId != null) {
      query = query.where('classId', isEqualTo: classId);
    }
    if (childId != null) {
      query = query.where('childId', isEqualTo: childId);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => NoticeModel.fromFirestore(doc)).toList());
  }

  Future<void> addNotice(NoticeModel notice) async {
    await _collection.add(notice.toMap());
  }

  Future<NoticeModel?> getNoticeById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return NoticeModel.fromFirestore(doc);
  }
}
