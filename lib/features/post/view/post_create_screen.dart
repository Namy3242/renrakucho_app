import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_model/post_view_model.dart';

class PostCreateScreen extends ConsumerStatefulWidget {
  const PostCreateScreen({super.key});

  @override
  ConsumerState<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends ConsumerState<PostCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final postViewModel = ref.watch(postViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'タイトルを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '内容'),
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? '内容を入力してください' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    await postViewModel.addPost(
                      _titleController.text,
                      _contentController.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('投稿する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
