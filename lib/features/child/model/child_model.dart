class ChildModel {
  final String id;
  final String name;
  final int? age;
  final String? classId;
  final String? kindergartenId; // 追加
  final List<String> parentIds;

  ChildModel({
    required this.id,
    required this.name,
    this.age,
    this.classId,
    this.kindergartenId, // 追加
    required this.parentIds,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json, String id) {
    return ChildModel(
      id: id,
      name: json['name'] as String,
      age: json['age'] as int?,
      classId: json['classId'] as String?,
      kindergartenId: json['kindergartenId'] as String?, // 追加
      parentIds: List<String>.from(json['parentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'classId': classId,
      'kindergartenId': kindergartenId, // 追加
      'parentIds': parentIds,
    };
  }

  ChildModel copyWith({
    String? id,
    String? name,
    int? age,
    String? classId,
    String? kindergartenId, // 追加
    List<String>? parentIds,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      classId: classId ?? this.classId,
      kindergartenId: kindergartenId ?? this.kindergartenId, // 追加
      parentIds: parentIds ?? this.parentIds,
    );
  }
}
