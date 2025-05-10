import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String content; // メッセージ
  final String? imageUrl; // 画像のURL（任意）
  final String? videoUrl; // 動画のURL（任意）
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json, String id) {
    return Post(
      id: id,
      authorId: json['authorId'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
// Postクラスは、Firebase Firestoreに保存される投稿データを表現するためのモデルクラスです。
// id、authorId、content、imageUrl、videoUrl、createdAtのプロパティを持ちます。