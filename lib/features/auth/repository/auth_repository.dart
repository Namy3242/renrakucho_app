import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../model/user_role.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _usersRef = FirebaseFirestore.instance.collection('users');

  // 現在のユーザーの状態を監視
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ログイン
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ユーザー登録（保護者用）
  Future<void> registerParent({
    required String email,
    required String password,
    required String displayName,
    String? classId,
  }) async {
    // Firebaseで認証用のユーザーを作成
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Firestoreにユーザー情報を保存
    await _usersRef.doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'role': UserRole.parent.toString(),
      'classId': classId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // 保育者登録用のメソッド
  Future<void> registerTeacher({
    required String email,
    required String password,
    required String displayName,
    String? classId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _usersRef.doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'role': UserRole.teacher.toString(),
        'classId': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 現在のユーザー情報を取得
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await getUserById(user.uid);
  }

  // ユーザー情報の取得
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!, doc.id);
  }

  // Firebase Authのエラーハンドリング
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('このメールアドレスは既に使用されています');
      case 'invalid-email':
        return Exception('無効なメールアドレスです');
      case 'operation-not-allowed':
        return Exception('この操作は許可されていません');
      case 'weak-password':
        return Exception('パスワードが脆弱です');
      case 'user-disabled':
        return Exception('このアカウントは無効化されています');
      case 'user-not-found':
        return Exception('ユーザーが見つかりません');
      case 'wrong-password':
        return Exception('パスワードが間違っています');
      default:
        return Exception('認証エラーが発生しました: ${e.message}');
    }
  }

  // ログアウト
  Future<void> signOut() => _auth.signOut();
}