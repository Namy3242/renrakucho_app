import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}
