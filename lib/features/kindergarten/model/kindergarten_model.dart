class KindergartenModel {
  final String id;
  final String name;
  final DateTime createdAt;

  KindergartenModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory KindergartenModel.fromJson(Map<String, dynamic> json, String id) {
    return KindergartenModel(
      id: id,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
