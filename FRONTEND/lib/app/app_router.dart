// app/app_router.dart — Router MVVM con todas las rutas
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/theme/app_theme.dart';
import '../view/screens/auth/login_screen.dart';
import '../view/screens/auth/register_screen.dart';
import '../view/screens/auth/verify_email_screen.dart';
import '../view/screens/onboarding/onboarding_screen.dart';
import '../view/screens/_all_screens.dart';
import '../view/screens/progression/progression_screen.dart';
import '../view/screens/chat/chat_screen.dart';
import '../view/screens/best_rep/best_rep_screen.dart';
import '../view/screens/improvement/improvement_plan_screen.dart';
import '../view/screens/capture/capture_screen.dart';
import '../view/screens/coach/become_coach_screen.dart';
import '../view/screens/coach/link_coach_screen.dart';

class GoRouterWrapper {
  final GoRouter router;
  GoRouterWrapper(AuthViewModel auth) : router = _build(auth);

  static GoRouter _build(AuthViewModel auth) => GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final loc    = state.matchedLocation;
      final authRoutes = ['/login', '/register', '/verify-email', '/forgot-password'];
      if (status == AuthStatus.unknown) return null;
      if (status == AuthStatus.unauthenticated && !authRoutes.contains(loc)) return '/login';
      if (status == AuthStatus.authenticated && authRoutes.contains(loc)) {
        if (!auth.onboardingDone) return '/onboarding';
        return _homeForRole(auth.role);
      }
      // Redirigir pantallas con problemas conocidos al dashboard
      if (status == AuthStatus.authenticated && loc == '/live') return _homeForRole(auth.role);
      return null;
    },
    routes: [
      GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',       builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding',     builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/dashboard',      builder: (_, __) => const AthleteDashboardScreen()),
      GoRoute(path: '/capture',        builder: (_, __) => const CaptureScreen()),
      GoRoute(path: '/results',        builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/history',        builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/calculator',     builder: (_, __) => const CalculatorScreen()),
      GoRoute(path: '/profile',        builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings',       builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/ai_model',       builder: (_, __) => const AIModelScreen()),
      GoRoute(path: '/achievements',   builder: (_, __) => const AchievementsScreen()),
      GoRoute(path: '/live',           builder: (_, __) => const LiveScreen()),
      GoRoute(path: '/become-coach',   builder: (_, __) => const BecomeCoachScreen()),
      GoRoute(path: '/link-coach',     builder: (_, __) => const LinkCoachScreen()),
      GoRoute(path: '/coach',          builder: (_, __) => const CoachDashboardScreen()),
      GoRoute(path: '/coach/athlete/:id',
          builder: (_, s) => AthleteDetailScreen(athleteId: s.pathParameters['id']!)),
      GoRoute(path: '/admin',          builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users',    builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/model',    builder: (_, __) => const AdminModelScreen()),
      GoRoute(path: '/progression',    builder: (_, __) => const ProgressionScreen()),
      GoRoute(path: '/improvement',    builder: (_, __) => const ImprovementPlanScreen()),
      GoRoute(path: '/best-reps',      builder: (_, __) => const BestRepsScreen()),  // Real screen
      GoRoute(path: '/chat',           builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/chat/:userId',    builder: (ctx, state) => ChatRoomScreen(
        otherUserId:   state.pathParameters['userId']!,
        otherUserName: state.uri.queryParameters['name'] ?? 'Usuario',
        otherRole:     state.uri.queryParameters['role'] ?? 'athlete',
        otherPhotoUrl: state.uri.queryParameters['photo'],
      )),
      GoRoute(path: '/verify-email',    builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(path: '/exercises',        builder: (_, __) => const AdditionalExercisesScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: BM.bg,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: BM.error, size: 48),
        const SizedBox(height: 16),
        Text('Página no encontrada: ${state.uri}',
            style: const TextStyle(color: BM.textSecondary, fontSize: 14)),
      ])),
    ),
  );

  void dispose() => router.dispose();
}

String _homeForRole(String role) {
  switch (role) {
    case 'admin': return '/admin';
    case 'coach': return '/dashboard';  // coach siempre inicia en dashboard
    default:      return '/dashboard';
  }
}
