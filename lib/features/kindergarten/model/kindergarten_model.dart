class KindergartenModel {
  final String id;
  final String name;

  KindergartenModel({
    required this.id,
    required this.name,
  });

  factory KindergartenModel.fromJson(Map<String, dynamic> json, String id) {
    return KindergartenModel(
      id: id,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
