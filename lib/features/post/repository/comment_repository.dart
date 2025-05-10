import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/comment.dart';

class CommentRepository {
  final _commentsRef = FirebaseFirestore.instance.collection('comments');

  // 投稿に紐づくコメントを取得
  Stream<List<Comment>> getComments(String postId) {
    return _commentsRef
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromJson(doc.data(), doc.id))
            .toList());
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