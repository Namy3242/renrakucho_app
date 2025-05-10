import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/view/login_screen.dart';
import '../features/home/view/home_screen.dart';
import '../providers/auth_provider.dart';

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
  ],
);
// このコードは、Flutterアプリケーションのルーティングを定義しています。
// GoRouterを使用して、ログイン画面とホーム画面のルートを設定しています。