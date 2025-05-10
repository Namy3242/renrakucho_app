import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../repository/auth_repository_provider.dart';

final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  return await ref.watch(authRepositoryProvider).getUserById(userId);
});