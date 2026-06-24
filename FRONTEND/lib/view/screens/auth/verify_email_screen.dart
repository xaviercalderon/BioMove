// view/screens/auth/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../../viewmodel/auth_viewmodel.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _countdown = 0;     // segundos hasta que puede reenviar
  bool _sending  = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      final verified = await auth.checkEmailVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        _navigate(auth);
      }
    });
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _countdownTimer?.cancel(); return; }
      setState(() { if (_countdown > 0) _countdown--; else _countdownTimer?.cancel(); });
    });
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _sending) return;
    setState(() => _sending = true);
    final auth = context.read<AuthViewModel>();
    await auth.sendVerificationEmail();
    if (mounted) {
      setState(() => _sending = false);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de verificación enviado'),
            backgroundColor: Color(0xFF00D4AA)));
    }
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    setState(() => _checking = true);
    final auth = context.read<AuthViewModel>();
    final verified = await auth.checkEmailVerified();
    if (mounted) {
      setState(() => _checking = false);
      if (verified) {
        _pollTimer?.cancel();
        _navigate(auth);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún no verificado. Revisa tu correo.'),
              backgroundColor: Color(0xFFFF5252)));
      }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final email = auth.currentEmail ?? 'tu correo';

    return Scaffold(
      backgroundColor: BM.bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const SizedBox(height: 80),

          // Ícono animado
          Container(width: 90, height: 90,
            decoration: BoxDecoration(
              color: BM.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: BM.primary.withOpacity(0.3), width: 2)),
            child: const Center(child: Icon(Icons.mark_email_unread_rounded,
                color: BM.primary, size: 42)))
            .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 28),

          const Text('Verifica tu correo',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: BM.textPrimary))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),

          RichText(textAlign: TextAlign.center, text: TextSpan(children: [
            const TextSpan(text: 'Enviamos un enlace de verificación a\n',
                style: TextStyle(color: BM.textSecondary, fontSize: 14, height: 1.6)),
            TextSpan(text: email,
                style: const TextStyle(color: BM.primary, fontSize: 14,
                    fontWeight: FontWeight.w700, height: 1.6)),
          ])).animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 8),
          const Text('Haz clic en el enlace del correo para activar tu cuenta.\nEsta pantalla se actualizará automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BM.textHint, fontSize: 12, height: 1.5))
              .animate().fadeIn(delay: 320.ms),
          const SizedBox(height: 40),

          // Botón verificar ahora
          GBtn(
            text: _checking ? 'Verificando...' : 'Ya lo verifiqué',
            icon: Icons.check_circle_rounded,
            loading: _checking,
            onTap: _checking ? null : _checkNow,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 14),

          // Reenviar correo
          GestureDetector(
            onTap: (_countdown > 0 || _sending) ? null : _resend,
            child: AnimatedOpacity(
              opacity: (_countdown > 0 || _sending) ? 0.4 : 1.0, duration: 200.ms,
              child: Container(height: 52, width: double.infinity,
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BM.elevated)),
                child: Center(child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: BM.primary, strokeWidth: 2))
                  : Text(
                      _countdown > 0 ? 'Reenviar en ${_countdown}s' : 'Reenviar correo de verificación',
                      style: const TextStyle(color: BM.textPrimary, fontSize: 14,
                          fontWeight: FontWeight.w500)))),
            ),
          ).animate().fadeIn(delay: 460.ms),
          const SizedBox(height: 24),

          // Volver al login
          TextButton(
            onPressed: () async {
              _pollTimer?.cancel();
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Cambiar cuenta / Volver al login',
                style: TextStyle(color: BM.textHint, fontSize: 13)),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 40),
        ]),
      )),
    );
  }
}
