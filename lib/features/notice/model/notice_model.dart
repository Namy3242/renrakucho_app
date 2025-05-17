import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String kindergartenId;
  final String? classId;
  final String? childId;
  final String authorId;
  final String type; // 'all', 'class', 'individual'
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final String? pdfUrl;

  NoticeModel({
    required this.id,
    required this.kindergartenId,
    this.classId,
    this.childId,
    required this.authorId,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.pdfUrl,
  });

  factory NoticeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // createdAt は Timestamp, DateTime, String のいずれかで受け取る可能性がある
    final rawCreatedAt = data['createdAt'];
    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.parse(rawCreatedAt);
    } else {
      createdAt = DateTime.now();
    }
    return NoticeModel(
      id: doc.id,
      kindergartenId: data['kindergartenId'] ?? '',
      classId: data['classId'],
      childId: data['childId'],
      authorId: data['authorId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: createdAt,
      imageUrl: data['imageUrl'],
      pdfUrl: data['pdfUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kindergartenId': kindergartenId,
      'classId': classId,
      'childId': childId,
      'authorId': authorId,
      'type': type,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
    };
  }
}
