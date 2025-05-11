import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../auth/model/user_role.dart';
import '../../../auth/model/user_model.dart';
import '../../../auth/repository/auth_repository_provider.dart';
import '../../../auth/repository/user_repository_provider.dart';
import '../../../child/view/child_create_dialog.dart';
import '../../../child/view_model/child_view_model.dart';
import '../../model/class_model.dart';
import '../../view_model/class_view_model.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../child/model/child_model.dart';
import '../../../child/view_model/child_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 検索結果を管理するプロバイダー
final searchResultsProvider = StateProvider<List<UserModel>>((ref) => []);

class ExistingChildSelectTab extends ConsumerStatefulWidget {
  final List<String> existingMembers;
  final void Function(String childId) onSelected;

  const ExistingChildSelectTab({
    super.key,
    required this.existingMembers,
    required this.onSelected,
  });

  @override
  ConsumerState<ExistingChildSelectTab> createState() => _ExistingChildSelectTabState();
}

class _ExistingChildSelectTabState extends ConsumerState<ExistingChildSelectTab> {
  final _searchController = TextEditingController();
  List<ChildModel> _children = [];
  String? _selectedChildId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllChildren();
  }

  Future<void> _fetchAllChildren() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .get();
      final children = snapshot.docs
          .map((doc) => ChildModel.fromJson(doc.data(), doc.id))
          .where((child) => !widget.existingMembers.contains(child.id))
          .toList();
      setState(() {
        _children = children;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchChildren(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (query.isEmpty) {
        await _fetchAllChildren();
        return;
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      final children = snapshot.docs
          .map((doc) => ChildModel.fromJson(doc.data(), doc.id))
          .where((child) => !widget.existingMembers.contains(child.id))
          .toList();

      setState(() {
        _children = children;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: '園児名で検索',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _searchChildren(value);
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _children.isEmpty
                  ? const Center(child: Text('検索結果がありません'))
                  : ListView.builder(
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        return RadioListTile<String>(
                          title: Text(child.name),
                          subtitle: Text('年齢: ${child.age ?? '-'}'),
                          value: child.id,
                          groupValue: _selectedChildId,
                          onChanged: (value) {
                            setState(() => _selectedChildId = value);
                            if (value != null) {
                              widget.onSelected(value);
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class AddMemberDialog extends ConsumerStatefulWidget {
  const AddMemberDialog({
    super.key,
    required this.existingMembers,
  });

  final List<String> existingMembers;

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  String? _selectedParentId;

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsProvider);

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: const Text('園児を追加'),
        content: SizedBox(
          width: 400,
          height: 480,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '既存園児から追加'),
                  Tab(text: '新規園児作成'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // 既存園児から追加タブ
                    ExistingChildSelectTab(
                      existingMembers: widget.existingMembers,
                      onSelected: (childId) => Navigator.pop(context, childId),
                    ),
                    // 新規園児作成タブ
                    _NewChildForm(
                      onCreated: (childId) => Navigator.pop(context, childId),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

// 新規園児作成フォーム（タブ用）
class _NewChildForm extends ConsumerStatefulWidget {
  final void Function(String childId) onCreated;
  const _NewChildForm({required this.onCreated, super.key});

  @override
  ConsumerState<_NewChildForm> createState() => _NewChildFormState();
}

class _NewChildFormState extends ConsumerState<_NewChildForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  List<String> _selectedParentIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final child = ChildModel(
        id: '',
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        classId: null,
        parentIds: _selectedParentIds,
      );
      final childId = await ref.read(childViewModelProvider.notifier).createChild(child);
      if (childId != null) {
        widget.onCreated(childId);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 4, right: 4, bottom: 4),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名前'),
                validator: (v) => v == null || v.isEmpty ? '名前を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: '年齢'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              parentsAsync.when(
                data: (parents) => ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const Text('保護者を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...parents.map((parent) => CheckboxListTile(
                            value: _selectedParentIds.contains(parent.id),
                            title: Text(parent.displayName ?? parent.email),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedParentIds.add(parent.id);
                                } else {
                                  _selectedParentIds.remove(parent.id);
                                }
                              });
                            },
                          )),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Text('保護者の取得に失敗しました'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _createChild,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('作成'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 保護者一覧取得用Provider
final parentsProvider = FutureProvider((ref) async {
  final repo = ref.read(userRepositoryProvider);
  final parents = await repo.getParents();
  return parents;
});

class ClassEditScreen extends ConsumerStatefulWidget {
  const ClassEditScreen({
    super.key,
    required this.classModel,
  });

  final ClassModel classModel;

  @override
  ConsumerState<ClassEditScreen> createState() => _ClassEditScreenState();
}

class _ClassEditScreenState extends ConsumerState<ClassEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.classModel.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedClass = widget.classModel.copyWith(
        name: _nameController.text.trim(),
      );

      await ref.read(classViewModelProvider.notifier).updateClass(updatedClass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クラスを更新しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このクラスを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(classViewModelProvider.notifier).deleteClass(widget.classModel.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('クラスを削除しました')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('クラス編集'),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        const Text('編集'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          '削除',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      final classModel = widget.classModel;
                      if (classModel != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassEditScreen(classModel: classModel),
                          ),
                        );
                        ref.invalidate(classViewModelProvider); // Replace with the correct provider if applicable
                      }
                      break;
                    case 'delete':
                      await _confirmDelete(context, ref);
                      break;
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'クラス名',
                      hintText: '例：うさぎ組',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'クラス名を入力してください';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _updateClass(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateClass,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('更新'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }
}