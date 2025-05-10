import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/comment.dart';

class CommentRepository {
  final _commentsRef = FirebaseFirestore.instance.collection('comments');

  // 投稿に紐づくコメントを取得
  Stream<List<Comment>> getComments(String postId) {
    try {
      return _commentsRef
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            if (error.toString().contains('failed-precondition')) {
              print('インデックスが必要です: $error');
              // Firestoreコンソールに表示されるリンクをコピーしてインデックスを作成してください
            }
            throw error;
          })
          .map((snapshot) => snapshot.docs
              .map((doc) => Comment.fromJson(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }

  // コメントを追加
  Future<void> addComment(Comment comment) async {
    final docRef = _commentsRef.doc();
    await docRef.set(comment.toJson());
  }

  // コメントを削除
  Future<void> deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }
}