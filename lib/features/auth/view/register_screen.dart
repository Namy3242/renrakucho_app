import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_role.dart';
import '../view_model/auth_view_model.dart';
import '../../kindergarten/repository/kindergarten_repository_provider.dart'; // 追加

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _kindergartenIdController = TextEditingController(); // 園ID入力用
  final _inviteCodeController = TextEditingController(); // 招待コード入力用
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.admin; // デフォルトを管理者に

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _kindergartenIdController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == UserRole.admin) {
        await ref.read(authViewModelProvider.notifier).registerAdmin(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
        );
      } else if (_selectedRole == UserRole.teacher) {
        // 保育者は園ID必須
        final kindergartenId = _kindergartenIdController.text.trim();
        final exists = await ref.read(kindergartenRepositoryProvider).exists(kindergartenId);
        if (!exists) throw Exception('園IDが正しくありません');
        await ref.read(authViewModelProvider.notifier).registerTeacher(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
          kindergartenId: kindergartenId,
        );
      } else if (_selectedRole == UserRole.parent) {
        // 保護者は招待コード必須
        final inviteCode = _inviteCodeController.text.trim();
        // 招待コードの検証・園児との紐付け処理をここで実装（例: API呼び出しやFirestore検索）
        final inviteResult = await ref.read(authViewModelProvider.notifier).registerParentWithInvite(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
          inviteCode: inviteCode,
        );
        if (!inviteResult) throw Exception('招待コードが正しくありません');
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'このメールアドレスは既に使用されています';
    } else if (error.contains('invalid-email')) {
      return '無効なメールアドレスです';
    } else if (error.contains('weak-password')) {
      return 'パスワードが脆弱です';
    }
    return '登録に失敗しました';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.admin,
                        label: Text('管理者'),
                        icon: Icon(Icons.admin_panel_settings),
                      ),
                      ButtonSegment(
                        value: UserRole.parent,
                        label: Text('保護者'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        label: Text('保育者'),
                        icon: Icon(Icons.school),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (Set<UserRole> role) {
                      setState(() => _selectedRole = role.first);
                    },
                  ),
                  if (_selectedRole == UserRole.teacher)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        controller: _kindergartenIdController,
                        decoration: const InputDecoration(
                          labelText: '園ID（管理者から発行されたIDを入力）',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        validator: (value) {
                          if (_selectedRole == UserRole.teacher && (value == null || value.isEmpty)) {
                            return '園IDを入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                  if (_selectedRole == UserRole.parent)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        controller: _inviteCodeController,
                        decoration: const InputDecoration(
                          labelText: '招待コード（管理者から発行されたコードを入力）',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: (value) {
                          if (_selectedRole == UserRole.parent && (value == null || value.isEmpty)) {
                            return '招待コードを入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      if (!_isValidEmail(value)) {
                        return '有効なメールアドレスを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: '名前',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '名前を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください';
                      }
                      if (value.length < 6) {
                        return 'パスワードは6文字以上である必要があります';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'パスワード（確認）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを再入力してください';
                      }
                      if (value != _passwordController.text) {
                        return 'パスワードが一致しません';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登録'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}