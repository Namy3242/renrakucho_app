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

  // 管理者登録用のメソッド
  Future<void> registerAdmin({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // 管理者は複数園を持つため kindergartenIds を空配列で初期化
    await _usersRef.doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'role': UserRole.admin.toString(),
      'kindergartenId': '', // 旧フィールド（互換用）
      'kindergartenIds': <String>[], // 新フィールド
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ユーザー登録（保護者用）
  Future<void> registerParent({
    required String email,
    required String password,
    required String displayName,
    required String kindergartenId, // 修正
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
      'kindergartenId': kindergartenId, // 修正
      'classId': classId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // 招待コードによる保護者登録
  Future<bool> registerParentWithInvite({
    required String email,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    // 1. 招待コードをFirestore等で検証し、園ID・childId等を取得
    final inviteSnapshot = await FirebaseFirestore.instance
        .collection('invites')
        .doc(inviteCode)
        .get();
    if (!inviteSnapshot.exists) {
      return false;
    }
    final inviteData = inviteSnapshot.data()!;
    final kindergartenId = inviteData['kindergartenId'] as String?;
    final childId = inviteData['childId'] as String?;
    if (kindergartenId == null || childId == null) {
      return false;
    }

    // 2. Firebase Authでユーザー作成
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final parentUid = credential.user!.uid;

    // 3. Firestoreにユーザー情報を保存し、childIdをchildIdsに追加
    await _usersRef.doc(parentUid).set({
      'email': email,
      'displayName': displayName,
      'role': UserRole.parent.toString(),
      'kindergartenId': kindergartenId,
      'childIds': [childId],
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 4. childドキュメントのparentIdsにこのユーザーIDを追加
    final childRef = FirebaseFirestore.instance.collection('children').doc(childId);
    await childRef.update({
      'parentIds': FieldValue.arrayUnion([parentUid])
    });

    // 5. 招待コードを無効化（削除）
    await inviteSnapshot.reference.delete();

    return true;
  }

  // 保育者登録用のメソッド
  Future<void> registerTeacher({
    required String email,
    required String password,
    required String displayName,
    required String kindergartenId, // 修正
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
        'kindergartenId': kindergartenId, // 修正
        'classId': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 招待コードを発行（管理者用）
  Future<String> createInviteCode({
    required String kindergartenId,
    required String childId,
  }) async {
    // ランダムなコード生成（例: 8桁英数字）
    final code = _generateRandomCode(8);
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'kindergartenId': kindergartenId,
      'childId': childId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return code;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (i) => chars[(rand + i * 31) % chars.length]).join();
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

  // メールアドレスで保護者を検索
  Future<List<UserModel>> searchParents(String email) async {
    if (email.isEmpty) return [];

    try {
      final snapshot = await _usersRef
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThan: email + 'z')
          .where('role', isEqualTo: UserRole.parent.toString())
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching parents: $e');
      return [];
    }
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