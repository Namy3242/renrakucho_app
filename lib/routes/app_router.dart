import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';  // 追加
import '../features/home/view/home_screen.dart';
import '../features/class/view/class_list_screen.dart';
import '../features/class/view/class_create_screen.dart';
import '../features/class/view/class_detail_screen.dart';
import '../features/class/view/class_edit_screen.dart';
import '../features/common/view/not_found_screen.dart';
import '../core/widgets/loading_overlay.dart';
import '../features/common/view/error_screen.dart';
import '../providers/auth_provider.dart';
import '../features/class/repository/class_repository_provider.dart';
import '../features/post/view/post_create_screen.dart';
import '../features/post/view/post_detail_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  errorBuilder: (context, state) => const NotFoundScreen(),
  refreshListenable: GoRouterRefreshStream(Connectivity().onConnectivityChanged), // 追加
  redirect: (context, state) async { // asyncに変更
    try {
      final container = ProviderScope.containerOf(context);
      final user = container.read(authStateProvider).asData?.value;

      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final isAuthRoute = loggingIn || registering;

      if (user == null) {
        return isAuthRoute ? null : '/login';
      } else {
        return isAuthRoute ? '/home' : null;
      }
    } catch (e) {
      debugPrint('Routing error: $e');
      return '/error';
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
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
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
      builder: (context, state) => ClassDetailScreen(
        classId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/posts/create',
      builder: (context, state) => const PostCreateScreen(),
    ),
    GoRoute(
      path: '/posts/:id',
      builder: (context, state) => PostDetailScreen(
        postId: state.pathParameters['id']!,
      ),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<ConnectivityResult> stream) {
    notifyListeners();
    if (!kIsWeb) {
      _subscription = stream.listen(
        (ConnectivityResult result) => notifyListeners(),
        onError: (error) {
          debugPrint('Connectivity error: $error');
          notifyListeners();
        },
      );
    }
  }

  StreamSubscription<ConnectivityResult>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}