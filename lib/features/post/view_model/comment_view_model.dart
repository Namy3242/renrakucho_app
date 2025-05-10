import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/comment.dart';
import '../repository/comment_repository.dart';
import '../repository/comment_repository_provider.dart';

final commentViewModelProvider = StateNotifierProvider.family<CommentViewModel, AsyncValue<List<Comment>>, String>(
  (ref, postId) => CommentViewModel(ref.watch(commentRepositoryProvider), postId),
);

class CommentViewModel extends StateNotifier<AsyncValue<List<Comment>>> {
  final CommentRepository _repository;
  final String _postId;

  CommentViewModel(this._repository, this._postId) : super(const AsyncValue.loading()) {
    _fetchComments();
  }

  void _fetchComments() {
    _repository.getComments(_postId).listen(
      (comments) {
        state = AsyncValue.data(comments);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  Future<void> addComment({
    required String content,
    required String authorId,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final comment = Comment(
        id: '',  // リポジトリで自動生成
        postId: _postId,
        authorId: authorId,
        content: content,
        createdAt: DateTime.now(),
      );
      
      await _repository.addComment(comment);
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      state = const AsyncValue.loading();
      await _repository.deleteComment(commentId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}