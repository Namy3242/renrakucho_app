import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/kindergarten_model.dart';

class KindergartenRepository {
  final _ref = FirebaseFirestore.instance.collection('kindergartens');

  Future<List<KindergartenModel>> getKindergartens() async {
    final snapshot = await _ref.get();
    return snapshot.docs
        .map((doc) => KindergartenModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> createKindergarten(String name) async {
    final doc = _ref.doc();
    await doc.set({
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
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
