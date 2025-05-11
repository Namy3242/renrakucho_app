class ChildModel {
  final String id;
  final String name;
  final int? age;
  final String? classId;
  final List<String> parentIds;

  ChildModel({
    required this.id,
    required this.name,
    this.age,
    this.classId,
    required this.parentIds,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json, String id) {
    return ChildModel(
      id: id,
      name: json['name'] as String,
      age: json['age'] as int?,
      classId: json['classId'] as String?,
      parentIds: List<String>.from(json['parentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'classId': classId,
      'parentIds': parentIds,
    };
  }

  ChildModel copyWith({
    String? id,
    String? name,
    int? age,
    String? classId,
    List<String>? parentIds,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      classId: classId ?? this.classId,
      parentIds: parentIds ?? this.parentIds,
    );
  }
}
