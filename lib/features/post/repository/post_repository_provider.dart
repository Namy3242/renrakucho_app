import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});
// PostRepositoryは、Firebase Firestoreを使用してデータの取得や保存を行うクラスです。
// ここでは、Firebase Firestoreのインスタンスを取得し、データの取得や保存を行うメソッドを定義します。