import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/post.dart';

class PostRepository {
  final _postsRef = FirebaseFirestore.instance.collection('posts');

  // 投稿を追加
  Future<void> addPost(Post post) async {
    // doc()を引数なしで呼び出すと、Firestoreが自動的にIDを生成します
    final docRef = _postsRef.doc();
    // 生成されたIDを使用して新しいPostオブジェクトを作成
    final newPost = Post(
      id: docRef.id,
      authorId: post.authorId,
      title: post.title,
      content: post.content,
      imageUrl: post.imageUrl,
      videoUrl: post.videoUrl,
      createdAt: post.createdAt,
    );
    // 新しいドキュメントを保存
    await docRef.set(newPost.toJson());
  }

  // 投稿を取得（新しい順）
  Stream<List<Post>> getPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(
              (doc) => Post.fromJson(doc.data(), doc.id),
            ).toList());
  }

  // 特定の投稿を取得（必要なら）
  Future<Post?> getPostById(String id) async {
    final doc = await _postsRef.doc(id).get();
    if (!doc.exists) return null;
    return Post.fromJson(doc.data()!, doc.id);
  }

  // 投稿を削除
  Future<void> deletePost(String id) async {
    await _postsRef.doc(id).delete();
  }
}
// 投稿の追加、取得、削除を行うリポジトリクラスです。
// addPostメソッドで投稿を追加し、getPostsメソッドで新しい順に投稿を取得します。
// getPostByIdメソッドで特定の投稿を取得し、deletePostメソッドで投稿を削除します。
// Firestoreのpostsコレクションを操作するためのメソッドを提供します。