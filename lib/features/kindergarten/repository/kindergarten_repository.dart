import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/kindergarten_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../auth/repository/user_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KindergartenRepository {
  final _ref = FirebaseFirestore.instance.collection('kindergartens');

  Future<List<KindergartenModel>> getKindergartens() async {
    final snapshot = await _ref.get();
    return snapshot.docs
        .map((doc) => KindergartenModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createKindergarten(String name, {required String adminUserId}) async {
    final doc = _ref.doc();
    await doc.set({
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 管理者ユーザーのkindergartenIdsに追加
    final userRef = FirebaseFirestore.instance.collection('users').doc(adminUserId);
    await userRef.set({
      'kindergartenIds': FieldValue.arrayUnion([doc.id])
    }, SetOptions(merge: true));
  }

  Future<bool> exists(String kindergartenId) async {
    final doc = await _ref.doc(kindergartenId).get();
    return doc.exists;
  }

  Future<KindergartenModel?> getKindergartenById(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return KindergartenModel.fromJson(doc.data()!, doc.id);
  }
}
