class NoticeModel {
  final String id;
  final String type; // 'all', 'class', 'individual'
  final String kindergartenId;
  final String? classId;
  final String? childId;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final String? pdfUrl;
  final Map<String, String> reactions; // userId -> reaction

  NoticeModel({
    required this.id,
    required this.type,
    required this.kindergartenId,
    this.classId,
    this.childId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.pdfUrl,
    this.reactions = const {},
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json, String id) {
    return NoticeModel(
      id: id,
      type: json['type'] as String,
      kindergartenId: json['kindergartenId'] as String,
      classId: json['classId'],
      childId: json['childId'],
      authorId: json['authorId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['imageUrl'],
      pdfUrl: json['pdfUrl'],
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'kindergartenId': kindergartenId,
      'classId': classId,
      'childId': childId,
      'authorId': authorId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'reactions': reactions,
    };
  }
}
