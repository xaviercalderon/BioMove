// view/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../../viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure   = true;
  bool _emailMode = false;
  bool _rememberEmail = false;
  String? _emailError, _passError;
  late AnimationController _pulse;

  static final _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: 2000.ms)..repeat(reverse: true);
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('remembered_email');
    final remember = prefs.getBool('remember_email') ?? false;
    if (saved != null && remember && mounted) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberEmail = true;
        _emailMode = true;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberEmail) {
      await prefs.setString('remembered_email', email);
      await prefs.setBool('remember_email', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_email', false);
    }
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _pulse.dispose(); super.dispose(); }

  bool _validate() {
    bool ok = true;
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty
          ? 'Ingresa tu correo'
          : !_emailRegex.hasMatch(_emailCtrl.text.trim())
              ? 'Formato de correo inválido' : null;
      _passError = _passCtrl.text.isEmpty ? 'Ingresa tu contraseña' : null;
      ok = _emailError == null && _passError == null;
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 56),

        // Logo animado
        Center(child: Column(children: [
          AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
            width: 80, height: 80,
            decoration: BoxDecoration(gradient: BM.grad1,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: BM.primary.withOpacity(0.4 + _pulse.value * 0.2),
                blurRadius: 24 + _pulse.value * 8, offset: const Offset(0, 10))]),
            child: const Center(child: Text('BM',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
          )).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 14),
          const Text('BioMove',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: BM.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 5),
          const Text('Análisis biomecánico con IA',
              style: TextStyle(fontSize: 13, color: BM.textSecondary))
              .animate().fadeIn(delay: 300.ms),
        ])),
        const SizedBox(height: 48),

        // Error global
        Consumer<AuthViewModel>(builder: (_, auth, __) {
          if (auth.error == null) return const SizedBox.shrink();
          return Container(margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BM.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: BM.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error!, style: const TextStyle(color: BM.error, fontSize: 12))),
              GestureDetector(onTap: auth.clearError, child: const Icon(Icons.close, color: BM.error, size: 15)),
            ])).animate().fadeIn().slideY(begin: -0.1);
        }),

        // Google
        Consumer<AuthViewModel>(builder: (_, auth, __) => GoogleBtn(
          loading: auth.loading && !_emailMode,
          onTap: auth.loading ? null : () => _googleLogin(auth),
        )).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 14),

        // Divider
        Row(children: [
          const Expanded(child: Divider(color: Color(0xFF202038))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: const TextStyle(color: BM.textHint, fontSize: 13))),
          const Expanded(child: Divider(color: Color(0xFF202038))),
        ]).animate().fadeIn(delay: 480.ms),
        const SizedBox(height: 14),

        if (!_emailMode)
          GestureDetector(
            onTap: () => setState(() => _emailMode = true),
            child: Container(height: 56, width: double.infinity,
              decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BM.elevated)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.email_outlined, color: BM.textSecondary, size: 20),
                SizedBox(width: 10),
                Text('Continuar con email',
                    style: TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              ])),
          ).animate().fadeIn(delay: 520.ms)
        else ...[ // ── Formulario email/contraseña ──
          // Email
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: BM.textPrimary),
              onChanged: (v) => setState(() => _emailError =
                  !_emailRegex.hasMatch(v.trim()) && v.isNotEmpty ? 'Formato inválido' : null),
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20))),
            if (_emailError != null) _inlineError(_emailError!),
          ]).animate().fadeIn(),
          const SizedBox(height: 12),

          // Contraseña
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _passCtrl,
              obscureText: _obscure, textInputAction: TextInputAction.done,
              style: const TextStyle(color: BM.textPrimary),
              onFieldSubmitted: (_) => _login(context.read<AuthViewModel>()),
              onChanged: (_) => setState(() => _passError = null),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20, color: BM.textHint)))),
            if (_passError != null) _inlineError(_passError!),
          ]).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 10),

          // Recordar email
          GestureDetector(
            onTap: () => setState(() => _rememberEmail = !_rememberEmail),
            child: Row(children: [
              SizedBox(width: 20, height: 20,
                child: Checkbox(
                  value: _rememberEmail, activeColor: BM.primary,
                  onChanged: (v) => setState(() => _rememberEmail = v!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                )),
              const SizedBox(width: 8),
              const Text('Recordar mi email',
                  style: TextStyle(color: BM.textSecondary, fontSize: 13)),
            ])).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 18),

          Consumer<AuthViewModel>(builder: (_, auth, __) => GBtn(
            text: 'Iniciar sesión', icon: Icons.login_rounded,
            loading: auth.loading && _emailMode,
            onTap: auth.loading ? null : () => _login(auth),
          )).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          // Olvidé contraseña
          Center(child: GestureDetector(
            onTap: () => context.go('/forgot-password'),
            child: const Text('¿Olvidaste tu contraseña?',
                style: TextStyle(color: BM.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          )).animate().fadeIn(delay: 120.ms),
        ],

        const SizedBox(height: 22),
        Center(child: GestureDetector(
          onTap: () { context.read<AuthViewModel>().clearError(); context.go('/register'); },
          child: RichText(text: const TextSpan(children: [
            TextSpan(text: '¿No tienes cuenta? ',
                style: TextStyle(color: BM.textSecondary, fontSize: 13)),
            TextSpan(text: 'Regístrate',
                style: TextStyle(color: BM.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ])))).animate().fadeIn(delay: 580.ms),
        const SizedBox(height: 40),
      ]),
    )),
  );

  Widget _inlineError(String msg) => Padding(
    padding: const EdgeInsets.only(top: 5, left: 12),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: BM.error, size: 13),
      const SizedBox(width: 4),
      Text(msg, style: const TextStyle(color: BM.error, fontSize: 11)),
    ]));

  Future<void> _googleLogin(AuthViewModel auth) async {
    setState(() => _emailMode = false);
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _navigate(auth);
  }

  Future<void> _login(AuthViewModel auth) async {
    if (!_validate()) return;
    await _saveEmail(_emailCtrl.text.trim());
    final ok = await auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      // Verificar si el email está confirmado
      final verified = await auth.checkEmailVerified();
      if (!verified) { context.go('/verify-email'); return; }
      _navigate(auth);
    }
  }

  void _navigate(AuthViewModel auth) {
    if (!auth.onboardingDone) { context.go('/onboarding'); return; }
    switch (auth.role) {
      case 'admin': context.go('/admin'); break;
      case 'coach': context.go('/coach'); break;
      default:      context.go('/dashboard');
    }
  }
}
