import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _emailMode  = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 60),

            // Logo
            Center(child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.5), blurRadius: 28, offset: const Offset(0, 10))]),
                child: const Center(child: Text('BM', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              const Text('BioMove', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: BM.textPrimary))
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              const Text('Análisis biomecánico con IA', style: TextStyle(fontSize: 14, color: BM.textSecondary))
                  .animate().fadeIn(delay: 300.ms),
            ])),

            const SizedBox(height: 52),

            Consumer<AuthProvider>(builder: (_, auth, __) {
              if (auth.error != null) return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BM.error.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: BM.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: const TextStyle(color: BM.error, fontSize: 13))),
                  GestureDetector(onTap: auth.clearError, child: const Icon(Icons.close, color: BM.error, size: 16)),
                ]),
              ).animate().fadeIn().slideY(begin: -0.1);
              return const SizedBox.shrink();
            }),

            // Google Sign-In
            Consumer<AuthProvider>(builder: (_, auth, __) =>
              GoogleBtn(loading: auth.loading && !_emailMode,
                  onTap: auth.loading ? null : () => _googleLogin(auth))
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

            const SizedBox(height: 16),

            // Divider
            Row(children: [
              const Expanded(child: Divider(color: Color(0xFF202038))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(color: BM.textHint, fontSize: 13))),
              const Expanded(child: Divider(color: Color(0xFF202038))),
            ]).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 16),

            if (!_emailMode) ...[
              // Show email/password button
              GestureDetector(
                onTap: () => setState(() => _emailMode = true),
                child: Container(
                  height: 56, width: double.infinity,
                  decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BM.elevated)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.email_outlined, color: BM.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text('Continuar con email', style: TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
            ] else ...[
              // Email form
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: BM.textPrimary),
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
              ).animate().fadeIn().slideX(begin: 0.1),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: BM.textPrimary),
                onFieldSubmitted: (_) => _login(context.read<AuthProvider>()),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: BM.textHint),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: 0.1),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(builder: (_, auth, __) =>
                GBtn(text: 'Iniciar sesión', icon: Icons.login_rounded,
                    loading: auth.loading && _emailMode,
                    onTap: auth.loading ? null : () => _login(auth))
              ).animate().fadeIn().slideY(begin: 0.2),
            ],

            const SizedBox(height: 24),

            // Register link
            Center(child: GestureDetector(
              onTap: () { context.read<AuthProvider>().clearError(); context.go('/register'); },
              child: RichText(text: const TextSpan(children: [
                TextSpan(text: '¿No tienes cuenta? ', style: TextStyle(color: BM.textSecondary, fontSize: 14)),
                TextSpan(text: 'Regístrate', style: TextStyle(color: BM.primary, fontSize: 14, fontWeight: FontWeight.w600)),
              ])),
            )).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Future<void> _googleLogin(AuthProvider auth) async {
    setState(() => _emailMode = false);
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _navigate(auth);
  }

  Future<void> _login(AuthProvider auth) async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    final ok = await auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) _navigate(auth);
  }

  void _navigate(AuthProvider auth) {
    if (!auth.onboardingDone) { context.go('/onboarding'); return; }
    switch (auth.role) {
      case 'admin': context.go('/admin'); break;
      case 'coach': context.go('/coach'); break;
      default:      context.go('/dashboard');
    }
  }
}
