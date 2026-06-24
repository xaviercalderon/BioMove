// view/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../../viewmodel/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _obscure   = true;
  bool _obscure2  = true;
  bool _acceptTerms = false;

  // Errores inline por campo
  String? _nameError, _emailError, _passError, _pass2Error;

  // Fortaleza de contraseña
  int _strength = 0; // 0-4
  bool _has8    = false;
  bool _hasUpper = false;
  bool _hasNum  = false;
  bool _hasSpec = false;

  static final _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_evalPassword);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  void _evalPassword() {
    final p = _passCtrl.text;
    setState(() {
      _has8    = p.length >= 8;
      _hasUpper = p.contains(RegExp(r'[A-Z]'));
      _hasNum  = p.contains(RegExp(r'[0-9]'));
      _hasSpec = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;]'));
      _strength = [_has8, _hasUpper, _hasNum, _hasSpec]
          .where((b) => b).length;
    });
  }

  bool _validateAll() {
    bool ok = true;
    setState(() {
      _nameError  = _nameCtrl.text.trim().isEmpty ? 'Ingresa tu nombre completo' : null;
      _emailError = _emailCtrl.text.trim().isEmpty
          ? 'Ingresa tu correo electrónico'
          : !_emailRegex.hasMatch(_emailCtrl.text.trim())
              ? 'El formato del correo no es válido'
              : null;
      _passError  = _passCtrl.text.length < 8
          ? 'Mínimo 8 caracteres'
          : !_hasUpper ? 'Necesita al menos una mayúscula'
          : !_hasNum   ? 'Necesita al menos un número'
          : !_hasSpec  ? 'Necesita al menos un carácter especial'
          : null;
      _pass2Error = _pass2Ctrl.text != _passCtrl.text
          ? 'Las contraseñas no coinciden' : null;
      ok = _nameError == null && _emailError == null &&
           _passError == null && _pass2Error == null;
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(backgroundColor: BM.bg, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('Crear cuenta',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BM.textPrimary))
            .animate().fadeIn().slideY(begin: -0.1),
        const SizedBox(height: 5),
        const Text('Completa todos los campos para registrarte',
            style: TextStyle(fontSize: 12, color: BM.textSecondary))
            .animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 24),

        // Error global Firebase
        Consumer<AuthViewModel>(builder: (_, auth, __) {
          if (auth.error == null) return const SizedBox.shrink();
          return Container(margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BM.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: BM.error, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error!, style: const TextStyle(color: BM.error, fontSize: 12))),
              GestureDetector(onTap: auth.clearError, child: const Icon(Icons.close, color: BM.error, size: 14)),
            ])).animate().fadeIn();
        }),

        // Nombre
        _field(controller: _nameCtrl, label: 'Nombre completo',
            icon: Icons.person_outline_rounded,
            error: _nameError, action: TextInputAction.next,
            caps: TextCapitalization.words,
            onChanged: (_) => setState(() => _nameError = null)),
        const SizedBox(height: 14),

        // Email
        _field(controller: _emailCtrl, label: 'Correo electrónico',
            icon: Icons.email_outlined, error: _emailError,
            type: TextInputType.emailAddress, action: TextInputAction.next,
            onChanged: (v) {
              setState(() => _emailError = v.isEmpty ? null
                  : !_emailRegex.hasMatch(v.trim())
                      ? 'Formato de correo inválido' : null);
            }),
        const SizedBox(height: 14),

        // Contraseña
        _field(controller: _passCtrl, label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            error: _passError, obscure: _obscure, action: TextInputAction.next,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: BM.textHint)),
            onChanged: (_) => setState(() => _passError = null)),
        const SizedBox(height: 10),

        // Indicador de fortaleza
        if (_passCtrl.text.isNotEmpty) ...[
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _strength / 4,
              minHeight: 6,
              backgroundColor: BM.elevated,
              valueColor: AlwaysStoppedAnimation(_strengthColor),
            )),
          const SizedBox(height: 6),
          Text(_strengthLabel, style: TextStyle(color: _strengthColor, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Checklist
          ...[
            (_has8,    '8 caracteres mínimo'),
            (_hasUpper,'Una letra mayúscula'),
            (_hasNum,  'Un número'),
            (_hasSpec, 'Un carácter especial (!@#\$...)'),
          ].map((r) => Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Icon(r.$1 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: r.$1 ? BM.accent : BM.textHint, size: 14),
              const SizedBox(width: 8),
              Text(r.$2, style: TextStyle(
                  color: r.$1 ? BM.accent : BM.textHint, fontSize: 12)),
            ]))),
          const SizedBox(height: 6),
        ],

        // Confirmar contraseña
        _field(controller: _pass2Ctrl, label: 'Confirmar contraseña',
            icon: Icons.lock_outline_rounded,
            error: _pass2Error, obscure: _obscure2, action: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure2 = !_obscure2),
              child: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: BM.textHint)),
            onChanged: (_) => setState(() => _pass2Error = null),
            onSubmitted: (_) => _submit()),
        const SizedBox(height: 18),

        // Info roles
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BM.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BM.primary.withOpacity(0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded, color: BM.primary, size: 16),
              SizedBox(width: 8),
              Text('¿Quieres ser entrenador?',
                  style: TextStyle(color: BM.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            SizedBox(height: 6),
            Text('Todos se registran como atletas. Después ve a Perfil → "Convertirme en entrenador".',
                style: TextStyle(color: BM.textSecondary, fontSize: 12, height: 1.4)),
          ])).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),

        // Términos
        GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: Row(children: [
            AnimatedContainer(duration: 200.ms, width: 22, height: 22,
              decoration: BoxDecoration(
                color: _acceptTerms ? BM.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _acceptTerms ? BM.primary : BM.elevated, width: 1.5)),
              child: _acceptTerms
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null),
            const SizedBox(width: 10),
            const Expanded(child: Text('Acepto el uso de mis datos para el análisis biomecánico',
                style: TextStyle(color: BM.textSecondary, fontSize: 13))),
          ])).animate().fadeIn(delay: 240.ms),
        const SizedBox(height: 22),

        Consumer<AuthViewModel>(builder: (_, auth, __) =>
          GBtn(text: 'Crear cuenta', icon: Icons.person_add_rounded,
            loading: auth.loading,
            onTap: (auth.loading || !_acceptTerms) ? null : _submit,
          )).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 18),
        Center(child: GestureDetector(onTap: () => context.go('/login'),
          child: const Text('¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(color: BM.primary, fontSize: 13, fontWeight: FontWeight.w500),
          ))).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
      ])))),
  );

  Color get _strengthColor {
    switch (_strength) {
      case 1: return BM.error;
      case 2: return BM.warning;
      case 3: return const Color(0xFF8BC34A);
      case 4: return BM.accent;
      default: return BM.textHint;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1: return 'Contraseña débil';
      case 2: return 'Contraseña media';
      case 3: return 'Contraseña fuerte';
      case 4: return 'Contraseña muy fuerte ✓';
      default: return '';
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? error,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    TextCapitalization caps = TextCapitalization.none,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: type, textInputAction: action,
        textCapitalization: caps,
        style: const TextStyle(color: BM.textPrimary),
        onChanged: onChanged, onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BM.error)),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BM.error, width: 1.5)),
        ),
      ),
      if (error != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 12),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: BM.error, size: 13),
            const SizedBox(width: 4),
            Text(error, style: const TextStyle(color: BM.error, fontSize: 11)),
          ])),
    ]);
  }

  Future<void> _submit() async {
    if (!_validateAll()) return;
    if (!_acceptTerms) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.register(
        _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    if (ok && mounted) context.go('/verify-email');
  }
}
