import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/class_model.dart';

class ClassRepository {
  final _classesRef = FirebaseFirestore.instance.collection('classes');

  // クラス一覧を取得
  Stream<List<ClassModel>> getClasses() {
    return _classesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // 特定のクラスを取得
  Future<ClassModel?> getClassById(String id) async {
    final doc = await _classesRef.doc(id).get();
    if (!doc.exists) return null;
    return ClassModel.fromJson(doc.data()!, doc.id);
  }

  // クラスを作成
  Future<void> createClass(ClassModel classModel) async {
    final docRef = _classesRef.doc();
    await docRef.set(classModel.toJson());
  }

  // クラスを更新
  Future<void> updateClass(ClassModel classModel) async {
    await _classesRef.doc(classModel.id).update(classModel.toJson());
  }

  // クラスを削除
  Future<void> deleteClass(String id) async {
    await _classesRef.doc(id).delete();
  }

  // クラスにメンバーを追加
  Future<void> addMember(String classId, String studentId) async {
    await _classesRef.doc(classId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  // クラスからメンバーを削除
  Future<void> removeMember(String classId, String studentId) async {
    await _classesRef.doc(classId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }
}