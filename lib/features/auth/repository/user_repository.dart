import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../model/user_role.dart';

class UserRepository {
  final _usersRef = FirebaseFirestore.instance.collection('users');

  Future<List<UserModel>> getTeachers() async {
    try {
      final snapshot = await _usersRef
          .where('role', isEqualTo: UserRole.teacher.toString())
          .orderBy('displayName')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting teachers: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getParents() async {
    try {
      final snapshot = await _usersRef
          .where('role', isEqualTo: UserRole.parent.toString())
          .orderBy('displayName')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting parents: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toJson());
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersRef.doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!, doc.id);
  }
}