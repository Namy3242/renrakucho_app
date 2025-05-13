import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/notice_repository.dart';
import '../model/notice_model.dart';
import '../../auth/view_model/auth_view_model.dart';

class NoticeCreateScreen extends ConsumerStatefulWidget {
  final String kindergartenId;
  final String type; // 'all', 'class', 'individual'
  final String? classId;
  final String? childId;

  const NoticeCreateScreen({
    super.key,
    required this.kindergartenId,
    required this.type,
    this.classId,
    this.childId,
  });

  @override
  ConsumerState<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends ConsumerState<NoticeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _imageUrl;
  String? _pdfUrl;
  bool _isLoading = false;

  // ダミーのファイル添付
  Future<void> _pickFile(bool isImage) async {
    setState(() {
      if (isImage) {
        _imageUrl = 'dummy_image.png';
      } else {
        _pdfUrl = 'dummy_file.pdf';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final notice = NoticeModel(
        id: '',
        type: widget.type,
        kindergartenId: widget.kindergartenId,
        classId: widget.classId,
        childId: widget.childId,
        authorId: user.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        imageUrl: _imageUrl,
        pdfUrl: _pdfUrl,
      );
      await ref.read(noticeRepositoryProvider).addNotice(notice);
      if (mounted) Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final isAllowed = user != null &&
        (user.role.toString() == 'UserRole.admin' || user.role.toString() == 'UserRole.teacher');

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('連絡作成')),
        body: const Center(child: Text('投稿権限がありません')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('連絡作成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (v) => v == null || v.isEmpty ? 'タイトルを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '内容'),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? '内容を入力してください' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('画像添付'),
                    onPressed: () => _pickFile(true),
                  ),
                  const SizedBox(width: 8),
                  if (_imageUrl != null) Text(_imageUrl!),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF添付'),
                    onPressed: () => _pickFile(false),
                  ),
                  const SizedBox(width: 8),
                  if (_pdfUrl != null) Text(_pdfUrl!),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('投稿'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
