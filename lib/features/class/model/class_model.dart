class ClassModel {
  final String id;
  final String name;
  final String teacherId; // 担任の先生のID
  final List<String> studentIds; // 所属する園児のID
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.studentIds,
    required this.createdAt,
  });

  // JSONからインスタンスを生成
  factory ClassModel.fromJson(Map<String, dynamic> json, String id) {
    return ClassModel(
      id: id,
      name: json['name'] as String,
      teacherId: json['teacherId'] as String,
      studentIds: List<String>.from(json['studentIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // インスタンスからJSONを生成
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // コピーメソッド
  ClassModel copyWith({
    String? name,
    String? teacherId,
    List<String>? studentIds,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}