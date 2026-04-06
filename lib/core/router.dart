import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/features/auth/auth_controller.dart';
import 'package:shaya_ai/features/auth/forgot_password_screen.dart';
import 'package:shaya_ai/features/auth/login_screen.dart';
import 'package:shaya_ai/features/auth/onboarding_screen.dart';
import 'package:shaya_ai/features/auth/register_screen.dart';
import 'package:shaya_ai/features/auth/splash_screen.dart';
import 'package:shaya_ai/features/generate/generate_music_screen.dart';
import 'package:shaya_ai/features/generate/generate_video_screen.dart';
import 'package:shaya_ai/features/home/home_screen.dart';
import 'package:shaya_ai/features/library/library_screen.dart';
import 'package:shaya_ai/features/library/playlist_screen.dart';
import 'package:shaya_ai/features/lyrics/lyrics_screen.dart';
import 'package:shaya_ai/features/player/now_playing_screen.dart';
import 'package:shaya_ai/features/profile/profile_screen.dart';
import 'package:shaya_ai/features/profile/settings_screen.dart';
import 'package:shaya_ai/features/search/search_screen.dart';
import 'package:shaya_ai/features/subscription/payment_screen.dart';
import 'package:shaya_ai/features/subscription/subscription_screen.dart';
import 'package:shaya_ai/shared/widgets/bottom_nav.dart';

GoRouter buildRouter(Ref ref, AppSessionController sessionController) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: sessionController,
    redirect: (context, state) {
      final location = state.uri.path;
      final publicRoutes = <String>{
        '/splash',
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      };

      if (!sessionController.initialized) {
        return location == '/splash' ? null : '/splash';
      }

      if (!sessionController.onboardingComplete &&
          location != '/onboarding' &&
          location != '/splash') {
        return '/onboarding';
      }

      if (!sessionController.onboardingComplete && location == '/splash') {
        return '/onboarding';
      }

      final isPublic = publicRoutes.contains(location);
      if (!sessionController.isAuthenticated && !isPublic) {
        return '/login';
      }

      if (sessionController.isAuthenticated &&
          (location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location == '/onboarding' ||
              location == '/splash')) {
        return '/home';
      }

      if (!sessionController.isAuthenticated && location == '/splash') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) =>
            ShayaShellScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
          GoRoute(
            path: '/generate',
            builder: (_, _) => const GenerateMusicScreen(),
          ),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/generate/video',
        builder: (_, _) => const GenerateVideoScreen(),
      ),
      GoRoute(path: '/lyrics', builder: (_, _) => const LyricsScreen()),
      GoRoute(
        path: '/player',
        pageBuilder: (_, state) =>
            _buildOverlayPage(state, const NowPlayingScreen()),
      ),
      GoRoute(
        path: '/playlist/:id',
        pageBuilder: (_, state) => _buildOverlayPage(
          state,
          PlaylistScreen(playlistId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/subscription',
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
    ],
  );
}

CustomTransitionPage<void> _buildOverlayPage(
  GoRouterState state,
  Widget child,
) {
  final isCupertino =
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: Duration(milliseconds: isCupertino ? 340 : 280),
    reverseTransitionDuration: Duration(milliseconds: isCupertino ? 280 : 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: isCupertino ? Curves.easeOutQuart : Curves.easeOutCubic,
        reverseCurve: isCupertino ? Curves.easeInQuart : Curves.easeInCubic,
      );
      final scale = Tween<double>(begin: isCupertino ? 0.985 : 0.965, end: 1)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: isCupertino ? Curves.easeOutQuart : Curves.easeOutCubic,
            ),
          );
      final slide =
          Tween<Offset>(
            begin: isCupertino ? const Offset(0, 0.018) : Offset.zero,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: isCupertino ? Curves.easeOutQuart : Curves.easeOutCubic,
            ),
          );
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, child: child),
        ),
      );
    },
  );
}
