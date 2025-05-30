import 'user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final String? classId;  // 所属クラスID（保育者は担任クラス、保護者は子供のクラス）
  final String kindergartenId; // 必須に変更
  final List<String> childIds; // 保護者の場合: 子供のIDリスト、保育者は空リスト
  final List<String> kindergartenIds; // 管理者用: 複数園ID
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.classId,
    required this.kindergartenId,
    this.childIds = const [],
    this.kindergartenIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // JSONからインスタンスを生成
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.toString() == json['role'] as String,
      ),
      classId: json['classId'] as String?,
      kindergartenId: json['kindergartenId'] as String, // 必須
      childIds: json['childIds'] != null
          ? List<String>.from(json['childIds'] as List)
          : const [],
      kindergartenIds: json['kindergartenIds'] != null
          ? List<String>.from(json['kindergartenIds'] as List)
          : const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // インスタンスからJSONを生成
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.toString(),
      'classId': classId,
      'kindergartenId': kindergartenId,
      'childIds': childIds,
      'kindergartenIds': kindergartenIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // コピーメソッド
  UserModel copyWith({
    String? email,
    String? displayName,
    UserRole? role,
    String? classId,
    String? kindergartenId,
    List<String>? childIds, // 追加
    List<String>? kindergartenIds,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      classId: classId ?? this.classId,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      childIds: childIds ?? this.childIds, // 追加
      kindergartenIds: kindergartenIds ?? this.kindergartenIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}