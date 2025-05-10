import 'package:flutter/material.dart';
import '../../features/auth/model/user_role.dart';

class PermissionUtils {
  static bool canManageClass(UserRole? role) {
    return role == UserRole.teacher || role == UserRole.admin;
  }

  static bool canEditClass(UserRole? role, {String? teacherId, String? userId}) {
    if (role == UserRole.admin) return true;
    if (role == UserRole.teacher && teacherId == userId) return true;
    return false;
  }

  static void showNoPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限がありません'),
        content: const Text('この操作を実行する権限がありません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
