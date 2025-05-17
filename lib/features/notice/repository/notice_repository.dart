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

  /// Adds a new notice and returns the generated document ID.
  Future<String> addNotice(NoticeModel notice) async {
    final docRef = await _collection.add(notice.toMap());
    return docRef.id;
  }

  Future<NoticeModel?> getNoticeById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return NoticeModel.fromFirestore(doc);
  }

  // ドキュメントを削除
  Future<void> deleteNotice(String id) async {
    await _collection.doc(id).delete();
  }

  /// Updates an existing notice document with given data fields.
  Future<void> updateNotice(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Generates a new document ID without writing.
  String generateId() => _collection.doc().id;
  
  /// Creates or overwrites a notice document with the given ID.
  Future<void> setNotice(String id, NoticeModel notice) async {
    await _collection.doc(id).set(notice.toMap());
  }
}
