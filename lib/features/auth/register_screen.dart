// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(backgroundColor: BM.bg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/login'))),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          const Text('Crear cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BM.textPrimary))
              .animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(height: 6),
          const Text('Empieza a analizar tu técnica con IA', style: TextStyle(fontSize: 14, color: BM.textSecondary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),

          Consumer<AuthProvider>(builder: (_, auth, __) {
            if (auth.error != null) return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: BM.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(auth.error!, style: const TextStyle(color: BM.error, fontSize: 13))),
              ]),
            );
            return const SizedBox.shrink();
          }),

          TextFormField(controller: _nameCtrl, textInputAction: TextInputAction.next,
              style: const TextStyle(color: BM.textPrimary),
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 14),
          TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: BM.textPrimary),
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 14),
          TextFormField(controller: _passCtrl, obscureText: _obscure,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: BM.textPrimary),
              onFieldSubmitted: (_) => _register(context.read<AuthProvider>()),
              decoration: InputDecoration(
                labelText: 'Contraseña (mín. 6 caracteres)',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: GestureDetector(onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: BM.textHint)),
              )).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 24),

          Consumer<AuthProvider>(builder: (_, auth, __) =>
            GBtn(text: 'Crear cuenta', icon: Icons.person_add_rounded,
                loading: auth.loading,
                onTap: auth.loading ? null : () => _register(auth))
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),
          Center(child: GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text('¿Ya tienes cuenta? Inicia sesión',
                style: TextStyle(color: BM.primary, fontSize: 14, fontWeight: FontWeight.w500)),
          )).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 40),
        ]),
      ),
    ),
  );

  Future<void> _register(AuthProvider auth) async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    final ok = await auth.register(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    if (ok && mounted) context.go('/onboarding');
  }
}
