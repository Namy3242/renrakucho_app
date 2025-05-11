import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/child_model.dart';

class ChildRepository {
  final _childrenRef = FirebaseFirestore.instance.collection('children');

  Future<ChildModel?> getChildById(String id) async {
    final doc = await _childrenRef.doc(id).get();
    if (!doc.exists) return null;
    return ChildModel.fromJson(doc.data()!, doc.id);
  }

  Future<String> createChild(ChildModel child) async {
    final docRef = _childrenRef.doc();
    await docRef.set(child.toJson());
    return docRef.id;
  }

  Future<void> updateChild(ChildModel child) async {
    await _childrenRef.doc(child.id).update(child.toJson());
  }

  Future<void> deleteChild(String id) async {
    await _childrenRef.doc(id).delete();
  }
}
