import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/theme.dart';
import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/athlete_dashboard.dart';
import '../features/dashboard/coach_dashboard.dart';
import '../features/capture/capture_screen.dart';
import '../features/results/results_screen.dart';
import '../features/screens.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (ctx, state) {
    final st  = auth.status;
    final loc = state.matchedLocation;
    final authRoutes = ['/login', '/register'];
    if (st == AuthStatus.unknown) return null;
    if (st == AuthStatus.unauthenticated && !authRoutes.contains(loc)) return '/login';
    if (st == AuthStatus.authenticated && authRoutes.contains(loc)) {
      if (!auth.onboardingDone) return '/onboarding';
      return _home(auth.role);
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register',     builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/onboarding',   builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/dashboard',    builder: (_, __) => const AthleteDashboard()),
    GoRoute(path: '/capture',      builder: (_, __) => const CaptureScreen()),
    GoRoute(path: '/results',      builder: (_, __) => const ResultsScreen()),
    GoRoute(path: '/history',      builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/calculator',   builder: (_, __) => const CalculatorScreen()),
    GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/ai_model',     builder: (_, __) => const AIModelScreen()),
    GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
    GoRoute(path: '/live',         builder: (_, __) => const LiveScreen()),
    GoRoute(path: '/coach',        builder: (_, __) => const CoachDashboard()),
    GoRoute(path: '/coach/athlete/:id', builder: (_, s) => AthleteDetailScreen(athleteId: s.pathParameters['id']!)),
    GoRoute(path: '/admin',        builder: (_, __) => const AdminDashboard()),
    GoRoute(path: '/admin/users',  builder: (_, __) => const AdminUsersScreen()),
    GoRoute(path: '/admin/model',  builder: (_, __) => const AdminModelScreen()),
  ],
  errorBuilder: (_, st) => Scaffold(backgroundColor: BM.bg,
    body: Center(child: Text('Ruta no encontrada: ${st.uri}',
        style: const TextStyle(color: BM.textSecondary)))),
);

String _home(String role) {
  if (role == 'admin') return '/admin';
  if (role == 'coach') return '/coach';
  return '/dashboard';
}
