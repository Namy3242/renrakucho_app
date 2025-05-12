class ClassModel {
  final String id;
  final String name;
  final List<String> teacherIds; // 担任の先生のIDリストに変更
  final List<String> studentIds;
  final DateTime createdAt;
  final String kindergartenId;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherIds, // 変更
    required this.studentIds,
    required this.createdAt,
    required this.kindergartenId,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json, String id) {
    return ClassModel(
      id: id,
      name: json['name'] as String,
      teacherIds: List<String>.from(json['teacherIds'] ?? []), // 変更
      studentIds: List<String>.from(json['studentIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      kindergartenId: json['kindergartenId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teacherIds': teacherIds, // 変更
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'kindergartenId': kindergartenId,
    };
  }

  ClassModel copyWith({
    String? name,
    List<String>? teacherIds, // 変更
    List<String>? studentIds,
    DateTime? createdAt,
    String? kindergartenId,
  }) {
    return ClassModel(
      id: id,
      name: name ?? this.name,
      teacherIds: teacherIds ?? this.teacherIds, // 変更
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      kindergartenId: kindergartenId ?? this.kindergartenId,
    );
  }
}