import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/post.dart';
import '../repository/post_repository.dart';
import '../repository/post_repository_provider.dart';

final postViewModelProvider = StateNotifierProvider<PostViewModel, AsyncValue<List<Post>>>(
  (ref) => PostViewModel(ref.watch(postRepositoryProvider)),
);

class PostViewModel extends StateNotifier<AsyncValue<List<Post>>> {
  final PostRepository _repository;

  PostViewModel(this._repository) : super(const AsyncLoading()) {
    _fetchPosts();
  }

  void _fetchPosts() {
    _repository.getPosts().listen(
      (posts) {
        state = AsyncValue.data(posts);
      },
      onError: (err, stack) {
        state = AsyncValue.error(err, stack);
      },
    );
  }
  Future<void> addPost(String title, String content) async {
    try {
      state = const AsyncLoading();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }
      
      final post = Post(
        id: '', // Repositoryで自動生成されるため、空文字列でOK
        authorId: user.uid,
        title: title,
        content: content,
        createdAt: DateTime.now(),
      );
      
      await _repository.addPost(post);
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  Future<void> deletePost(String id) async {
    try {
      state = const AsyncLoading();
      
      await _repository.deletePost(id);
      
      // 成功した場合は自動的に_fetchPosts()によって
      // 最新のデータがstateに反映されます
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
// PostViewModelは、投稿の取得、追加、削除を行うためのクラスです。
// StateNotifierを継承しており、AsyncValue<List<Post>>を状態として持ちます。