import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/notice_model.dart';
import '../repository/notice_repository_provider.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../class/view_model/class_view_model.dart';
import '../../child/view_model/child_view_model.dart';
import '../../child/view/child_list_screen.dart';
import '../../auth/model/user_role.dart';

class NoticeCreateScreen extends ConsumerStatefulWidget {
  final String type;
  final String kindergartenId;
  final String? classId;
  final String? childId;
  const NoticeCreateScreen({super.key, required this.type, required this.kindergartenId, this.classId, this.childId});

  @override
  ConsumerState<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends ConsumerState<NoticeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedClassId;
  String? _selectedChildId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    // ユーザー取得エラーまたは未ログインの場合
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('連絡作成')),
        body: const Center(child: Text('ユーザー情報が取得できません')),
      );
    }
    final isClassType = widget.type == 'class';
    final isIndividualType = widget.type == 'individual';
    // 投稿権限：管理者・保育者のみ
    final canPost = currentUser.role == UserRole.admin || currentUser.role == UserRole.teacher;
    final classListAsync = ref.watch(classViewModelProvider);
    final childListAsync = ref.watch(allChildrenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('連絡作成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              if (isClassType) ...[
                const SizedBox(height: 16),
                classListAsync.when(
                  data: (classes) => DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (id) => setState(() => _selectedClassId = id),
                    decoration: const InputDecoration(labelText: 'クラスを選択'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('クラス取得エラー: $e'),
                ),
              ],
              if (isIndividualType) ...[
                const SizedBox(height: 16),
                childListAsync.when(
                  data: (children) => DropdownButtonFormField<String>(
                    value: _selectedChildId,
                    items: children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (id) => setState(() => _selectedChildId = id),
                    decoration: const InputDecoration(labelText: '園児を選択'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('園児取得エラー: $e'),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (!canPost || _isLoading)
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  try {
                    final notice = NoticeModel(
                      id: '',
                      kindergartenId: widget.kindergartenId,
                      classId: isClassType ? _selectedClassId : null,
                      childId: isIndividualType ? _selectedChildId : null,
                      authorId: currentUser.id,
                      type: widget.type,
                      title: _titleController.text.trim(),
                      content: _contentController.text.trim(),
                      createdAt: DateTime.now(),
                      imageUrl: null,
                      pdfUrl: null,
                    );
                    await ref.read(noticeRepositoryProvider).addNotice(notice);
                    // 投稿成功フィードバック
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('投稿が完了しました')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('投稿に失敗しました: $e')),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                child: _isLoading ? const CircularProgressIndicator() : const Text('投稿する'),
              ),
              if (!canPost)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('投稿権限がありません', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
