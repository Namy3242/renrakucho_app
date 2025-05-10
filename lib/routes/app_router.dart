import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/view/login_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/class/view/class_list_screen.dart';
import '../features/class/view/class_create_screen.dart';
import '../features/class/view/class_detail_screen.dart';
import '../features/class/view/class_edit_screen.dart';
import '../features/common/view/not_found_screen.dart';
import '../core/widgets/loading_overlay.dart';
import '../features/common/view/error_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';

final appRouter = GoRouter(
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final user = container.read(authStateProvider).asData?.value;

    final loggingIn = state.matchedLocation == '/login';

    if (user == null) {
      return loggingIn ? null : '/login';
    } else {
      return loggingIn ? '/home' : null;
    }
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/classes',
      builder: (context, state) => const ClassListScreen(),
    ),
    GoRoute(
      path: '/classes/create',
      builder: (context, state) => const ClassCreateScreen(),
    ),
    GoRoute(
      path: '/classes/:id',
      builder: (context, state) => ClassDetailScreen(
        classId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/classes/:id/edit',
      builder: (context, state) {
        final classModel = ref.watch(selectedClassProvider(state.pathParameters['id']!));
        return classModel.when(
          data: (model) => model == null
              ? const NotFoundScreen()
              : ClassEditScreen(classModel: model),
          loading: () => const LoadingOverlay(),
          error: (_, __) => const ErrorScreen(),
        );
      },
    ),
  ],
);
// このコードは、Flutterアプリケーションのルーティングを定義しています。
// GoRouterを使用して、ログイン画面とホーム画面のルートを設定しています。
// ユーザーの認証状態に基づいて、適切な画面にリダイレクトします。
// 各画面は、GoRouteを使用して定義されており、URLパスに基づいて表示されます。