// view/screens/_all_screens.dart
// Todas las pantallas restantes con imports MVVM correctos
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../../model/analysis_model.dart';
import '../../../model/user_model.dart';
import '../../../viewmodel/auth_viewmodel.dart';
import '../../../viewmodel/analysis_viewmodel.dart';
import '../../../repository/analysis_repository.dart';
import '../../../repository/user_repository.dart';
import '../../services/pdf_service.dart';
import '../../services/api_service.dart';
import '../../services/haptic_service.dart';
import '../../services/theme_service.dart';
import '../../services/settings_service.dart';
import '../../view/widgets/percentile_widget.dart';
import '../../view/widgets/tutorial_overlay.dart';
import '../../viewmodel/chat_viewmodel.dart';
import '../../view/screens/improvement/improvement_plan_screen.dart';
import 'package:video_player/video_player.dart';
import 'chat/chat_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ════════════════════════════════════════════════════════════════════════════
// RESULTS SCREEN
// ════════════════════════════════════════════════════════════════════════════
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisViewModel>();

    // Pantalla de procesamiento con barra de progreso
    if (analysis.isLoading) {
      return _ProcessingScreen(vm: analysis);
    }
    if (analysis.step == AnalysisStep.failed) {
      return _ErrorScreen(
        error: analysis.error ?? 'Error desconocido',
        onRetry: () { analysis.reset(); context.go('/capture'); },
      );
    }
    final result = analysis.result;
    if (result == null) {
      return _ErrorScreen(
        error: 'Sin resultados. Sube un video para analizar.',
        onRetry: () => context.go('/capture'),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/dashboard');
        Future.microtask(() => context.read<AnalysisViewModel>().reset());
      },
      child: Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: Text(ExerciseInfo.fromId(result.exerciseType).label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () { context.go('/dashboard'); Future.microtask(() => context.read<AnalysisViewModel>().reset()); },
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: BM.primary,
          labelColor: BM.primary,
          unselectedLabelColor: BM.textSecondary,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 16), text: 'Resumen'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 16), text: 'Análisis'),
            Tab(icon: Icon(Icons.repeat_rounded, size: 16), text: 'Reps'),
            Tab(icon: Icon(Icons.psychology_rounded, size: 16), text: 'Mi IA'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _SummaryTab(result: result),
        _ParamsTab(result: result),
        _RepsTab(result: result),
        _AITab(result: result),
      ]),
    ));
  }
}

// ── Pantalla de procesamiento ─────────────────────────────────────────────────
class _ProcessingScreen extends StatelessWidget {
  final AnalysisViewModel vm;
  const _ProcessingScreen({required this.vm});

  @override
  Widget build(BuildContext context) {
    final pct = vm.totalProgressPct / 100.0;
    return Scaffold(
      backgroundColor: BM.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
              ),
              child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 42),
            ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1800.ms, color: Colors.white24),
            const SizedBox(height: 32),
            const Text('Analizando tu técnica',
                style: TextStyle(color: BM.textPrimary,
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(vm.statusMessage,
                style: const TextStyle(color: BM.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            LinearPercentIndicator(
              lineHeight: 18,
              percent: pct.clamp(0.0, 1.0),
              center: Text('${vm.totalProgressPct}%',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)),
              barRadius: const Radius.circular(9),
              backgroundColor: Colors.white10,
              linearGradient: LinearGradient(
                colors: vm.totalProgressPct < 40
                    ? [const Color(0xFF6C63FF), const Color(0xFF9C8FFF)]
                    : vm.totalProgressPct < 80
                        ? [const Color(0xFF00D4AA), const Color(0xFF00A882)]
                        : [const Color(0xFF4CAF50), const Color(0xFF00D4AA)]),
              animation: true, animationDuration: 600,
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _StepDot('Subir',    vm.totalProgressPct >= 30),
              _StepDot('Analizar', vm.totalProgressPct >= 70),
              _StepDot('Informe',  vm.totalProgressPct >= 100),
            ]),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BM.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.accent.withOpacity(0.25)),
              ),
              child: Row(children: const [
                Icon(Icons.notifications_active_rounded, color: BM.accent, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Puedes navegar por la app — te avisaremos cuando termine',
                  style: TextStyle(color: BM.accent, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Ir al inicio'),
              onPressed: () => context.go('/dashboard'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label; final bool done;
  const _StepDot(this.label, this.done);
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 24, height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: done ? BM.accent : Colors.white12,
        border: Border.all(color: done ? BM.accent : Colors.white24)),
      child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 10, color: done ? BM.accent : BM.textHint)),
  ]);
}

class _ErrorScreen extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorScreen({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    body: Center(child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: BM.error, size: 60),
        const SizedBox(height: 16),
        Text(error, style: const TextStyle(color: BM.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GBtn(text: 'Intentar de nuevo', height: 50, onTap: onRetry),
        const SizedBox(height: 12),
        TextButton(onPressed: () => context.go('/dashboard'),
            child: const Text('Ir al inicio')),
      ]))),
  );
}

// ── Video Player con descarga ─────────────────────────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});
  @override State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _ctrl;
  bool _ready = false, _err = false, _downloading = false;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    try {
      final raw = widget.videoUrl;
      final url = raw.startsWith('http')
          ? raw
          : 'http://10.0.2.2:8000$raw';
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) { if (mounted) setState(() => _err = true); }
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/biomove_${DateTime.now().millisecondsSinceEpoch}.mp4';
      // Construir URL completa igual que en _init()
      final raw = widget.videoUrl;
      final fullUrl = raw.startsWith('http') ? raw : 'http://10.0.2.2:8000' + raw;
      await Dio().download(fullUrl, path);
      await Gal.putVideo(path);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Video guardado en galería'),
            backgroundColor: Color(0xFF00D4AA)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: BM.error));
    } finally { if (mounted) setState(() => _downloading = false); }
  }

  @override void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_err) return Container(height: 160,
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BM.error.withOpacity(0.3))),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.videocam_off_rounded, color: BM.textHint, size: 28),
        SizedBox(height: 6),
        Text('Video no disponible', style: TextStyle(color: BM.textSecondary, fontSize: 12)),
      ])));

    if (!_ready) return Container(height: 160,
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: CircularProgressIndicator(color: BM.accent)));

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BM.accent.withOpacity(0.25))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!)),
        Container(color: BM.card,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(children: [
            IconButton(icon: Icon(
              _ctrl!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: BM.accent), iconSize: 22,
              onPressed: () => setState(() =>
                  _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play())),
            Expanded(child: VideoProgressIndicator(_ctrl!, allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: BM.accent, bufferedColor: Colors.white24,
                backgroundColor: Colors.white10))),
            IconButton(
              icon: _downloading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: BM.accent, strokeWidth: 2))
                  : const Icon(Icons.download_rounded, color: BM.accent, size: 20),
              onPressed: _download, tooltip: 'Guardar en galería'),
          ])),
      ]));
  }
}

// ── SUMMARY TAB ───────────────────────────────────────────────────────────────
Future<Map<String, bool>?> _showPdfOptions(BuildContext context) async {
  final opts = <String, bool>{'resumen': true, 'reps': true, 'alertas': true, 'mejoras': true, 'ejercicios': false};
  return showModalBottomSheet<Map<String, bool>>(
    context: context, backgroundColor: BM.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Exportar informe PDF', style: TextStyle(color: BM.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Elige qué incluir:', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        ...['resumen','reps','alertas','mejoras','ejercicios'].map((k) {
          final labels = {
            'resumen': '📊 Resumen de técnica (siempre)',
            'reps': '🔢 Detalle de repeticiones',
            'alertas': '⚠️ Alertas de lesión',
            'mejoras': '💡 Puntos a mejorar',
            'ejercicios': '🎯 Recomendaciones de ejercicios',
          };
          final locked = k == 'resumen';
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: opts[k]!, activeColor: BM.primary,
            onChanged: locked ? null : (v) => setSt(() => opts[k] = v!),
            title: Text(labels[k]!, style: TextStyle(
              color: locked ? BM.textHint : BM.textPrimary, fontSize: 13)),
          );
        }),
        const SizedBox(height: 16),
        GBtn(text: 'Generar PDF', icon: Icons.picture_as_pdf_rounded,
          onTap: () => Navigator.pop(ctx2, Map<String,bool>.from(opts))),
        const SizedBox(height: 8),
      ]),
    )),
  );
}

// ── Recuperar contraseña ────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  String? _emailError;
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  @override void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(backgroundColor: BM.bg, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        const Text('Recuperar contraseña',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: BM.textPrimary))
            .animate().fadeIn(),
        const SizedBox(height: 8),
        const Text('Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(fontSize: 13, color: BM.textSecondary, height: 1.5))
            .animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 32),

        if (_sent) ...[
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: BM.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BM.accent.withOpacity(0.3))),
            child: Column(children: [
              const Icon(Icons.mark_email_read_rounded, color: BM.accent, size: 48),
              const SizedBox(height: 12),
              const Text('¡Correo enviado!',
                  style: TextStyle(color: BM.accent, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Revisa tu bandeja de entrada en ${_emailCtrl.text.trim()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
            ])).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),
          GBtn(text: 'Volver al inicio de sesión', icon: Icons.login_rounded,
              onTap: () => context.go('/login')),
        ] else ...[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: BM.textPrimary),
              onChanged: (v) => setState(() => _emailError =
                  v.isNotEmpty && !_emailRegex.hasMatch(v.trim()) ? 'Formato inválido' : null),
              onFieldSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined, size: 20))),
            if (_emailError != null) Padding(
              padding: const EdgeInsets.only(top: 5, left: 12),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: BM.error, size: 13),
                const SizedBox(width: 4),
                Text(_emailError!, style: const TextStyle(color: BM.error, fontSize: 11)),
              ])),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Consumer<AuthViewModel>(builder: (_, auth, __) => GBtn(
            text: 'Enviar enlace', icon: Icons.send_rounded,
            loading: auth.loading,
            onTap: auth.loading ? null : _send,
          )).animate().fadeIn(delay: 140.ms),
        ],
      ]))),
  );

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Formato de correo inválido');
      return;
    }
    final auth = context.read<AuthViewModel>();
    final ok = await auth.sendPasswordReset(email);
    if (ok && mounted) setState(() => _sent = true);
  }
}

// ── Cambiar contraseña (desde perfil) ───────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obs1 = true, _obs2 = true, _obs3 = true;
  String? _currentErr, _newErr, _confirmErr;
  int _strength = 0;
  bool _has8=false, _hasUpper=false, _hasNum=false, _hasSpec=false;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(_evalPass);
  }

  @override void dispose() {
    _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose();
  }

  void _evalPass() {
    final p = _newCtrl.text;
    setState(() {
      _has8    = p.length >= 8;
      _hasUpper = p.contains(RegExp(r'[A-Z]'));
      _hasNum  = p.contains(RegExp(r'[0-9]'));
      _hasSpec = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;]'));
      _strength = [_has8,_hasUpper,_hasNum,_hasSpec].where((b)=>b).length;
    });
  }

  Color get _sColor => [BM.textHint,BM.error,BM.warning,const Color(0xFF8BC34A),BM.accent][_strength];
  String get _sLabel => ['','Débil','Media','Fuerte','Muy fuerte ✓'][_strength];

  bool _validate() {
    bool ok = true;
    setState(() {
      _currentErr = _currentCtrl.text.isEmpty ? 'Ingresa tu contraseña actual' : null;
      _newErr     = _strength < 2 ? 'La contraseña no cumple los requisitos mínimos' : null;
      _confirmErr = _confirmCtrl.text != _newCtrl.text ? 'Las contraseñas no coinciden' : null;
      ok = _currentErr==null && _newErr==null && _confirmErr==null;
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Cambiar contraseña'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/profile'))),
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Error global
        Consumer<AuthViewModel>(builder: (_, auth, __) {
          if (auth.error == null) return const SizedBox.shrink();
          return Container(margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BM.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: BM.error, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error!, style: const TextStyle(color: BM.error, fontSize: 12))),
              GestureDetector(onTap: auth.clearError, child: const Icon(Icons.close, color: BM.error, size: 14)),
            ]));
        }),

        // Contraseña actual
        _passField(ctrl: _currentCtrl, label: 'Contraseña actual',
            obscure: _obs1, onToggle: ()=>setState(()=>_obs1=!_obs1), error: _currentErr,
            onChanged: (_)=>setState(()=>_currentErr=null)),
        const SizedBox(height: 16),

        // Nueva contraseña
        _passField(ctrl: _newCtrl, label: 'Nueva contraseña',
            obscure: _obs2, onToggle: ()=>setState(()=>_obs2=!_obs2), error: _newErr,
            onChanged: (_)=>setState(()=>_newErr=null)),
        if (_newCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _strength/4, minHeight: 5,
                backgroundColor: BM.elevated,
                valueColor: AlwaysStoppedAnimation(_sColor))),
          const SizedBox(height: 4),
          if (_sLabel.isNotEmpty) Text(_sLabel, style: TextStyle(color: _sColor, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...[(_has8,'8 caracteres mínimo'),(_hasUpper,'Una mayúscula'),
              (_hasNum,'Un número'),(_hasSpec,'Un carácter especial')].map((r)=>
            Padding(padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                Icon(r.$1?Icons.check_circle_rounded:Icons.radio_button_unchecked_rounded,
                    color: r.$1?BM.accent:BM.textHint, size: 14),
                const SizedBox(width: 6),
                Text(r.$2, style: TextStyle(color: r.$1?BM.accent:BM.textHint, fontSize: 11)),
              ]))),
        ],
        const SizedBox(height: 16),

        // Confirmar contraseña
        _passField(ctrl: _confirmCtrl, label: 'Confirmar nueva contraseña',
            obscure: _obs3, onToggle: ()=>setState(()=>_obs3=!_obs3), error: _confirmErr,
            onChanged: (_)=>setState(()=>_confirmErr=null),
            action: TextInputAction.done),
        const SizedBox(height: 28),

        Consumer<AuthViewModel>(builder: (_, auth, __) => GBtn(
          text: 'Cambiar contraseña', icon: Icons.lock_reset_rounded,
          loading: auth.loading,
          onTap: auth.loading ? null : () => _submit(auth),
        )),
        const SizedBox(height: 40),
      ]),
    )),
  );

  Widget _passField({required TextEditingController ctrl, required String label,
      required bool obscure, required VoidCallback onToggle, String? error,
      void Function(String)? onChanged, TextInputAction action=TextInputAction.next}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(controller: ctrl, obscureText: obscure,
        textInputAction: action, style: const TextStyle(color: BM.textPrimary),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: GestureDetector(onTap: onToggle,
            child: Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined,
                size: 20, color: BM.textHint)))),
      if (error != null) Padding(padding: const EdgeInsets.only(top:5,left:12),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: BM.error, size: 13),
          const SizedBox(width: 4),
          Expanded(child: Text(error, style: const TextStyle(color: BM.error, fontSize: 11))),
        ])),
    ]);
  }

  Future<void> _submit(AuthViewModel auth) async {
    if (!_validate()) return;
    final ok = await auth.changePassword(_currentCtrl.text, _newCtrl.text);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Contraseña cambiada exitosamente'),
          backgroundColor: Color(0xFF00D4AA)));
      context.go('/profile');
    }
  }
}

class _SummaryTab extends StatelessWidget {
  final AnalysisResultModel result;
  const _SummaryTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final reps = result.repetitions;
    final celebrate = result.techniqueScore >= 90;
    return Stack(children: [
      SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Score principal
        Center(child: ScoreGauge(score: result.techniqueScore, size: 160)
            .animate().scale(duration: 600.ms, curve: Curves.elasticOut)),
        const SizedBox(height: 6),
        Center(child: Text(
          DateFormat("d 'de' MMMM yyyy", 'es').format(result.sessionDate),
          style: const TextStyle(fontSize: 13, color: BM.textSecondary))),
        const SizedBox(height: 20),

        // Métricas rápidas
        Row(children: [
          Expanded(child: MetricCard(label:'Reps', value:'${result.totalReps}',
              icon: Icons.repeat_rounded, color: BM.primary, animDelay: 0)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(
              label:'Duración',
              value:'${result.durationSeconds?.toStringAsFixed(0) ?? '—'}s',
              icon: Icons.timer_outlined, color: BM.accent, animDelay: 60)),
          if (result.weightKg != null) ...[
            const SizedBox(width: 10),
            Expanded(child: MetricCard(
                label:'Peso',
                value:'${result.weightKg!.toStringAsFixed(0)} kg',
                icon: Icons.fitness_center_rounded,
                color: BM.warning, animDelay: 120)),
          ],
        ]),
        const SizedBox(height: 16),

        // Video anotado
        if (result.annotatedDownloadUrl != null) ...[
          const SectionHeader(title: '🎬 Video anotado con IA'),
          const SizedBox(height: 10),
          _VideoPlayerWidget(videoUrl: result.annotatedDownloadUrl!),
          const SizedBox(height: 20),
        ],

        // Semáforo técnico
        if (reps.isNotEmpty) ...[
          const SectionHeader(title: '📊 Tu técnica en resumen'),
          const SizedBox(height: 12),
          ..._semaphore(reps),
          const SizedBox(height: 20),
        ],

        // Fatiga
        if (result.fatigueDetected) ...[
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BM.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.warning.withOpacity(0.3))),
            child: Row(children: const [
              Icon(Icons.battery_alert_rounded, color: BM.warning, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Fatiga detectada — tu técnica bajó hacia el final de la sesión',
                style: TextStyle(color: BM.warning, fontSize: 12))),
            ])),
          const SizedBox(height: 16),
        ],

        // Clasificador IA
        if (result.classifierEnabled && reps.isNotEmpty &&
            reps.last.clfClass != null) ...[
          const SectionHeader(title: '🤖 Clasificador IA'),
          const SizedBox(height: 12),
          ClassifierCard(
            clfClass: reps.last.clfClass ?? 'aceptable',
            confidence: reps.last.clfConfidence ?? 0,
            topFactors: reps.last.clfTopFactors,
            version: reps.last.clfVersion,
          ).animate().fadeIn(),
          const SizedBox(height: 20),
        ],

        // Feedback riesgo (colapsable, abierto si hay riesgos)
        if (result.riskFeedback.isNotEmpty) ...[
          _CollapsibleSection(
            title: 'Alertas de lesión',
            emoji: '⚠️',
            count: result.riskFeedback.length,
            accent: BM.error,
            initiallyExpanded: true,
            children: result.riskFeedback.map((f) => _FeedbackCard(item: f)).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Feedback mejora (colapsable, cerrado por defecto)
        if (result.improveFeedback.isNotEmpty) ...[
          _CollapsibleSection(
            title: 'Puntos a mejorar',
            emoji: '💡',
            count: result.improveFeedback.length,
            accent: BM.warning,
            initiallyExpanded: false,
            children: result.improveFeedback.map((f) => _FeedbackCard(item: f)).toList(),
          ),
        ],

        // ── Botones de acción ─────────────────────────────────────────
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _ActionBtn(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Exportar PDF',
            color: const Color(0xFFFF8A65),
            onTap: () async {
              HapticService.medium();
              final opts = await _showPdfOptions(context);
              if (opts == null) return;
              try {
                await PdfService.generateAndShare(result, options: opts);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: BM.error));
              }
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionBtn(
            icon: Icons.sports_rounded,
            label: 'Enviar a coach',
            color: const Color(0xFF00D4AA),
            onTap: () => _showSendToCoach(context, result),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionBtn(
            icon: Icons.auto_fix_high_rounded,
            label: 'Plan de mejora',
            color: BM.primary,
            onTap: () {
              HapticService.select();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ImprovementPlanScreen(
                  feedback: result.riskFeedback.map((f) => {
                    'error_type': f.errorType,
                    'is_injury_risk': f.isInjuryRisk,
                    'severity': f.severity,
                  }).toList() + result.improveFeedback.map((f) => {
                    'error_type': f.errorType,
                    'is_injury_risk': f.isInjuryRisk,
                    'severity': f.severity,
                  }).toList(),
                ),
              ));
            },
          )),
        ]),
        const SizedBox(height: 20),

        if (result.riskFeedback.isEmpty && result.improveFeedback.isEmpty)
          GlassCard(child: Column(children: const [
            Icon(Icons.check_circle_rounded, color: BM.accent, size: 44),
            SizedBox(height: 12),
            Text('¡Técnica excelente!', style: TextStyle(
                color: BM.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 6),
            Text('Sin errores detectados. ¡Sigue así!',
                style: TextStyle(color: BM.textSecondary, fontSize: 13)),
          ])).animate().fadeIn(),

        const SizedBox(height: 40),
      ]),
      ),
      // Confeti de celebración para técnica excelente
      if (celebrate)
        const Positioned.fill(child: ConfettiBurst(active: true)),
    ]);
  }

  List<Widget> _semaphore(List<RepResultModel> reps) {
    double avg(double? Function(RepResultModel) fn) {
      final vals = reps.map(fn).whereType<double>().toList();
      return vals.isEmpty ? 0.0 : vals.reduce((a,b)=>a+b) / vals.length;
    }
    final knee   = avg((r) => r.kneeAngleMin);
    final valgusL= avg((r) => r.leftValgus);
    final valgusR= avg((r) => r.rightValgus);
    final trunk  = avg((r) => r.trunkLeanMax);
    final acl    = avg((r) => r.aclRiskScore);
    final lumbar = avg((r) => r.lumbarRiskScore);
    final asym   = avg((r) => r.kneeAsymmetryPct);
    final tempo  = avg((r) => r.eccentricDur);
    final avgValgus = (valgusL + valgusR) / 2;

    final items = <_SemData>[
      _SemData('Profundidad', Icons.height_rounded, '${knee.toStringAsFixed(0)}°',
        knee<=95?'Profundidad correcta ✓':knee<=110?'Falta un poco más':'Insuficiente — llega al paralelo',
        knee<=95?'good':knee<=110?'warn':'bad'),
      _SemData('Rodillas', Icons.airline_seat_legroom_extra_rounded, '${avgValgus.toStringAsFixed(0)}°',
        avgValgus<=5?'Rodillas en buena posición ✓':avgValgus<=10?'Leve colapso de rodillas':'Valgo severo — riesgo de lesión',
        avgValgus<=5?'good':avgValgus<=10?'warn':'bad'),
      _SemData('Postura del tronco', Icons.accessibility_new_rounded, '${trunk.toStringAsFixed(0)}°',
        trunk<=45?'Tronco bien erguido ✓':trunk<=55?'Tronco algo inclinado':'Demasiada inclinación',
        trunk<=45?'good':trunk<=55?'warn':'bad'),
      _SemData('Simetría', Icons.compare_arrows_rounded, '${asym.toStringAsFixed(0)}%',
        asym<=8?'Buena simetría bilateral ✓':asym<=15?'Asimetría moderada':'Desequilibrio entre piernas',
        asym<=8?'good':asym<=15?'warn':'bad'),
      _SemData('Control de bajada', Icons.timer_outlined, '${tempo.toStringAsFixed(1)}s',
        tempo>=2.0?'Excelente control excéntrico ✓':tempo>=1.5?'Baja un poco más lento':'Descenso muy rápido',
        tempo>=2.0?'good':tempo>=1.5?'warn':'bad'),
      _SemData('Riesgo de rodilla', Icons.warning_amber_rounded, '${acl.toStringAsFixed(0)}/100',
        acl<=25?'Bajo riesgo ✓':acl<=50?'Riesgo moderado — ten cuidado':'Alto riesgo — reduce el peso',
        acl<=25?'good':acl<=50?'warn':'bad'),
      _SemData('Riesgo lumbar', Icons.healing_rounded, '${lumbar.toStringAsFixed(0)}/100',
        lumbar<=25?'Espalda protegida ✓':lumbar<=50?'Riesgo lumbar moderado':'Alto riesgo lumbar',
        lumbar<=25?'good':lumbar<=50?'warn':'bad'),
    ];
    // Ordenar: rojo (bad) → ámbar (warn) → verde (good)
    const rank = {'bad':0,'warn':1,'good':2};
    items.sort((a,b) => rank[a.status]!.compareTo(rank[b.status]!));

    final widgets = <Widget>[];
    for (int i=0; i<items.length; i++) {
      final it = items[i];
      widgets.add(_SemCard(label:it.label, icon:it.icon, value:it.value, desc:it.desc, status:it.status));
      if (i < items.length-1) widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

class _SemData {
  final String label, value, desc, status; final IconData icon;
  _SemData(this.label, this.icon, this.value, this.desc, this.status);
}

// ── Sección colapsable (Alertas / Mejoras) ──────────────────────────────────
class _CollapsibleSection extends StatefulWidget {
  final String title, emoji;
  final int count;
  final Color accent;
  final bool initiallyExpanded;
  final List<Widget> children;
  const _CollapsibleSection({required this.title, required this.emoji,
    required this.count, required this.accent, required this.children,
    this.initiallyExpanded = false});
  @override State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}
class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _open;
  @override void initState() { super.initState(); _open = widget.initiallyExpanded; }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () { HapticService.light(); setState(() => _open = !_open); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accent.withOpacity(0.25)),
          ),
          child: Row(children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.title,
                style: TextStyle(color: widget.accent, fontSize: 15, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: widget.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.count}',
                  style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(turns: _open ? 0.5 : 0, duration: 200.ms,
              child: Icon(Icons.keyboard_arrow_down_rounded, color: widget.accent)),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(padding: const EdgeInsets.only(top: 10),
          child: Column(children: widget.children)),
        crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: 250.ms,
      ),
    ]);
  }
}

class _SemCard extends StatelessWidget {
  final String label, value, desc, status; final IconData icon;
  const _SemCard({required this.label, required this.icon,
      required this.value, required this.desc, required this.status});
  @override
  Widget build(BuildContext context) {
    final color = status=='good'?BM.accent:status=='warn'?BM.warning:BM.error;
    return Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      ])).animate().fadeIn().slideX(begin: 0.05);
  }
}

class _FeedbackCard extends StatefulWidget {
  final FeedbackItemModel item;
  const _FeedbackCard({required this.item});
  @override State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.item;
    final color = f.isInjuryRisk?BM.error:f.severity=='moderate'?BM.warning:BM.accent;
    return Container(margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        ListTile(
          leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(f.isInjuryRisk?Icons.warning_rounded:Icons.lightbulb_rounded,
                color: color, size: 18)),
          title: Text(f.message, style: const TextStyle(
              color: BM.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${f.frequencyPct}% de tus repeticiones',
              style: TextStyle(color: color, fontSize: 11)),
          trailing: Icon(_expanded?Icons.expand_less:Icons.expand_more, color: BM.textHint),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) Padding(padding: const EdgeInsets.fromLTRB(16,0,16,12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Corrección:', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(f.correction, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
            if (f.exerciseRecommendation?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Text('Ejercicios: ${f.exerciseRecommendation}',
                  style: const TextStyle(color: BM.textHint, fontSize: 11)),
            ],
          ])),
      ]));
  }
}


// ── Botón de acción reutilizable ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ])),
  );
}

void _showSendToCoach(BuildContext context, AnalysisResultModel result) {
  HapticService.select();
  showModalBottomSheet(context: context, backgroundColor: BM.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sports_rounded, color: BM.accent, size: 36),
        const SizedBox(height: 12),
        const Text('Enviar informe al entrenador',
            style: TextStyle(color: BM.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Tu entrenador recibirá el análisis completo de esta sesión.',
            style: TextStyle(color: BM.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        GBtn(text: 'Enviar', height: 50,
          onTap: () async {
            Navigator.pop(context);
            final jobId = result.jobId;
            if (jobId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se puede compartir esta sesión'),
                    backgroundColor: Color(0xFFFF5252)));
              return;
            }
            try {
              await ApiService().shareSessionWithCoach(jobId);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Informe enviado al entrenador'),
                    backgroundColor: Color(0xFF00D4AA)));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF5252)));
            }
          }),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
      ])));
}

// ── PARAMS TAB ────────────────────────────────────────────────────────────────
class _ParamsTab extends StatelessWidget {
  final AnalysisResultModel result;
  const _ParamsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final reps = result.repetitions;
    if (reps.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.videocam_off_rounded, color: BM.textHint, size: 40),
        SizedBox(height: 12),
        Text('No se detectaron repeticiones', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('Asegúrate que el cuerpo esté visible y la vista sea correcta',
            style: TextStyle(color: BM.textSecondary, fontSize: 13), textAlign: TextAlign.center),
      ])));

    double avg(double? Function(RepResultModel) fn) {
      final vals = reps.map(fn).whereType<double>().toList();
      return vals.isEmpty ? 0.0 : vals.reduce((a,b)=>a+b)/vals.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Gauges por zona
        const SectionHeader(title: 'Zonas clave'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _ZoneGauge(label:'Rodilla',
              value: avg((r)=>r.kneeAngleMin), max:180, unit:'°', invert:true, color:BM.primary)),
          const SizedBox(width: 10),
          Expanded(child: _ZoneGauge(label:'Cadera',
              value: avg((r)=>r.hipAngleMin), max:180, unit:'°', invert:true, color:BM.accent)),
          const SizedBox(width: 10),
          Expanded(child: _ZoneGauge(label:'Tronco',
              value: avg((r)=>r.trunkLeanMax), max:90, unit:'°', invert:false, color:BM.warning)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ZoneGauge(label:'Riesgo\nLCA',
              value: avg((r)=>r.aclRiskScore), max:100, unit:'', invert:false, color:BM.error)),
          const SizedBox(width: 10),
          Expanded(child: _ZoneGauge(label:'Riesgo\nLumbar',
              value: avg((r)=>r.lumbarRiskScore), max:100, unit:'', invert:false,
              color:const Color(0xFFFF8A65))),
          const SizedBox(width: 10),
          Expanded(child: _ZoneGauge(label:'Simetría',
              value:(100-avg((r)=>r.kneeAsymmetryPct).clamp(0,100)),
              max:100, unit:'%', invert:false, color:const Color(0xFF9C27B0))),
        ]),
        const SizedBox(height: 24),

        // Parámetros con barras
        const SectionHeader(title: 'Parámetros detallados'),
        const SizedBox(height: 12),
        _PBar('Valgo rodilla izq.', avg((r)=>r.leftValgus), 0, 20, '°', false),
        _PBar('Valgo rodilla der.', avg((r)=>r.rightValgus), 0, 20, '°', false),
        _PBar('Movilidad tobillo', avg((r)=>r.ankleDF), 0, 40, '°', true),
        _PBar('Control excéntrico', avg((r)=>r.eccConRatio), 0, 4, 'x', true),
        _PBar('Velocidad movim.', avg((r)=>r.barVelocityMs), 0, 1, 'm/s', true),
        _PBar('Desplazamiento lateral', avg((r)=>r.lateralHipShiftCm), 0, 10, 'cm', false),
        _PBar('Rotación pélvica', avg((r)=>r.pelvicRotationDeg), 0, 30, '°', false),
        _PBar('Elevación talón', avg((r)=>r.heelElevationLeft), 0, 5, 'cm', false),
        _PBar('Carga patellofemoral', avg((r)=>r.patellofemoralLoad), 0, 100, '', false),

        // Gráfico velocidad de barra
        if (reps.isNotEmpty && reps.any((r) => (r.barVelocityMs ?? 0) > 0)) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: '📈 Velocidad de barra por rep'),
          const SizedBox(height: 12),
          _VelocityChart(reps: reps),
        ],

        const SizedBox(height: 40),
      ]),
    );
  }
}

class _ZoneGauge extends StatelessWidget {
  final String label, unit; final double value, max; final bool invert; final Color color;
  const _ZoneGauge({required this.label, required this.value, required this.max,
      required this.unit, required this.invert, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    final displayPct = invert ? pct : 1.0 - pct;
    final c = displayPct > 0.6 ? BM.accent : displayPct > 0.3 ? BM.warning : BM.error;
    return GlassCard(padding: const EdgeInsets.all(12),
      child: Column(children: [
        CircularPercentIndicator(
          radius: 34, lineWidth: 6,
          percent: displayPct.clamp(0.0, 1.0),
          center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${value.toStringAsFixed(0)}', style: TextStyle(
                color: c, fontSize: 13, fontWeight: FontWeight.w800)),
            if (unit.isNotEmpty) Text(unit, style: const TextStyle(color: BM.textHint, fontSize: 9)),
          ]),
          progressColor: c, backgroundColor: Colors.white10,
          circularStrokeCap: CircularStrokeCap.round,
          animation: true, animationDuration: 800),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 10),
            textAlign: TextAlign.center),
      ]));
  }
}

class _PBar extends StatelessWidget {
  final String label, unit; final double value, min, max; final bool higherIsBetter;
  const _PBar(this.label, this.value, this.min, this.max, this.unit, this.higherIsBetter);
  @override
  Widget build(BuildContext context) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final good = higherIsBetter ? pct : 1.0 - pct;
    final color = good > 0.6 ? BM.accent : good > 0.3 ? BM.warning : BM.error;
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(1)}$unit',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 5),
        LinearPercentIndicator(lineHeight: 8, percent: pct.clamp(0.0,1.0),
          barRadius: const Radius.circular(4), backgroundColor: Colors.white10,
          linearGradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
          padding: EdgeInsets.zero, animation: true, animationDuration: 700),
      ]));
  }
}

class _VelocityChart extends StatelessWidget {
  final List<RepResultModel> reps;
  const _VelocityChart({required this.reps});
  @override
  Widget build(BuildContext context) {
    final spots = reps.asMap().entries
        .where((e) => (e.value.barVelocityMs ?? 0) > 0)
        .map((e) => FlSpot(e.key.toDouble()+1, e.value.barVelocityMs ?? 0))
        .toList();
    if (spots.isEmpty) return const SizedBox.shrink();
    return GlassCard(padding: const EdgeInsets.all(16),
      child: SizedBox(height: 160, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawHorizontalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
              getTitlesWidget: (v,_) => Text('${v.toStringAsFixed(1)}',
                  style: const TextStyle(color: BM.textHint, fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20,
              getTitlesWidget: (v,_) => Text('R${v.toInt()}',
                  style: const TextStyle(color: BM.textHint, fontSize: 9)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, color: BM.accent,
          barWidth: 2.5, dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true,
              color: BM.accent.withOpacity(0.1)))],
      ))));
  }
}

// ── REPS TAB ──────────────────────────────────────────────────────────────────
class _RepsTab extends StatelessWidget {
  final AnalysisResultModel result;
  const _RepsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final reps = result.repetitions;
    if (reps.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.videocam_off_rounded, color: BM.textHint, size: 40),
        SizedBox(height: 12),
        Text('No se detectaron repeticiones', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600)),
      ])));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reps.length,
      itemBuilder: (_, i) {
        final rep = reps[i]; final c = BM.scoreColor(rep.repScore);
        return GlassCard(margin: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Repetición ${rep.repNumber}',
                  style: const TextStyle(color: BM.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${rep.repScore.toStringAsFixed(0)}/100',
                    style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 13))),
            ]),
            const SizedBox(height: 10),
            LinearPercentIndicator(lineHeight: 7,
              percent: (rep.repScore/100).clamp(0.0,1.0),
              barRadius: const Radius.circular(4), backgroundColor: Colors.white10,
              linearGradient: LinearGradient(colors: [c.withOpacity(0.5), c]),
              padding: EdgeInsets.zero, animation: true, animationDuration: 700),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (rep.kneeAngleMin != null)
                _RepChip('Rodilla ${rep.kneeAngleMin!.toStringAsFixed(0)}°',
                    (rep.kneeAngleMin ?? 180) <= 95 ? 'good' : 'warn'),
              if ((rep.leftValgus ?? 0) > 0)
                _RepChip('Valgo ${rep.leftValgus!.toStringAsFixed(0)}°',
                    (rep.leftValgus ?? 0) <= 10 ? 'good' : 'bad'),
              if (rep.eccentricDur != null)
                _RepChip('Exc ${rep.eccentricDur!.toStringAsFixed(1)}s',
                    (rep.eccentricDur ?? 0) >= 2.0 ? 'good' : 'warn'),
              if (rep.depthAchieved) _RepChip('Profundidad ✓', 'good'),
              if (rep.hasInjuryRisk) _RepChip('⚠ Riesgo', 'bad'),
            ]),
            if (rep.errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...rep.errors.take(3).map((e) {
                final msg = e['message'] as String? ?? '';
                final correction = e['correction'] as String? ?? '';
                if (msg.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BM.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BM.error.withOpacity(0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: BM.error, size: 13),
                      const SizedBox(width: 5),
                      Expanded(child: Text(msg,
                          style: const TextStyle(color: BM.error, fontSize: 12, fontWeight: FontWeight.w600))),
                    ]),
                    if (correction.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(correction,
                          style: const TextStyle(color: BM.textSecondary, fontSize: 11, height: 1.4)),
                    ],
                  ]),
                );
              }),
            ],
          ])).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      });
  }
}

class _RepChip extends StatelessWidget {
  final String label; final String status;
  const _RepChip(this.label, this.status);
  @override
  Widget build(BuildContext context) {
    final color = status=='good'?BM.accent:status=='warn'?BM.warning:BM.error;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}

// ── AI TAB ────────────────────────────────────────────────────────────────────
class _AITab extends StatelessWidget {
  final AnalysisResultModel result;
  const _AITab({required this.result});

  @override
  Widget build(BuildContext context) {
    final ai       = result.aiComparison;
    final state    = ai['model_state'] as Map<String, dynamic>?;
    final phase    = state?['phase'] as String? ?? 'collecting';
    final baseReps = (state?['baseline_reps'] as num?)?.toInt() ?? 0;
    final totalReps= (state?['total_reps_collected'] as num?)?.toInt() ?? 0;
    final morpho   = state?['morphology'] as Map? ?? {};
    final trends   = state?['improvement_trends'] as Map? ?? {};
    final recs     = (ai['recommendations'] as List?)?.cast<Map>() ?? [];

    final progress = phase == 'collecting' ? baseReps / 10.0
        : phase == 'learning'              ? totalReps / 30.0
        : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Estado del modelo
        GlassCard(child: Column(children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_phaseTitle(phase), style: const TextStyle(
                  color: BM.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(_phaseSub(phase, baseReps, totalReps),
                  style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 16),
          LinearPercentIndicator(lineHeight: 13,
            percent: progress.clamp(0.0, 1.0),
            center: Text('${(progress*100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            barRadius: const Radius.circular(7), backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
            animation: true, animationDuration: 900),
          const SizedBox(height: 8),
          Text(_progressHint(phase, baseReps, totalReps),
              style: const TextStyle(color: BM.textHint, fontSize: 11), textAlign: TextAlign.center),
        ])),
        const SizedBox(height: 20),

        // Morfología
        if (morpho.isNotEmpty) ...[
          const SectionHeader(title: '🔬 Tu morfología detectada'),
          const SizedBox(height: 10),
          if (morpho['femur_note'] != null) ...[
            _InsightCard(
              icon: Icons.accessibility_new_rounded,
              color: const Color(0xFF9C27B0),
              title: morpho['femur_ratio'] == 'long' ? '💡 Fémur largo' : '✓ Morfología normal',
              message: morpho['femur_note'] as String),
            const SizedBox(height: 8),
          ],
          if (morpho['ankle_note'] != null) _InsightCard(
            icon: Icons.directions_walk_rounded,
            color: morpho['ankle_mobility'] == 'restricted' ? BM.warning : BM.accent,
            title: morpho['ankle_mobility'] == 'restricted'
                ? '🦶 Tobillo limitado' : '🦶 Movilidad de tobillo',
            message: morpho['ankle_note'] as String),
          const SizedBox(height: 20),
        ],

        // Tendencias
        if (trends.isNotEmpty && phase != 'collecting') ...[
          const SectionHeader(title: '📈 Cómo vas evolucionando'),
          const SizedBox(height: 10),
          ...trends.entries
              .where((e) => e.value != 'insufficient_data')
              .take(6)
              .map((e) => _TrendRow(param: e.key, trend: e.value.toString())),
          const SizedBox(height: 20),
        ],

        // Recomendaciones
        if (recs.isNotEmpty) ...[
          const SectionHeader(title: '🎯 Recomendaciones para ti'),
          const SizedBox(height: 10),
          ...recs.take(4).map((r) => _RecCard(rec: r)),
        ],

        // Guía si está en collecting
        if (phase == 'collecting') ...[
          const SizedBox(height: 10),
          GlassCard(child: Column(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: BM.accent, size: 32),
            const SizedBox(height: 10),
            const Text('¿Cómo funciona tu IA personal?',
                style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            ...[
              '📹 Sube videos con poco peso (≤50% de tu máximo)',
              '🔬 La IA aprende TU técnica — no te compara con otros',
              '📊 Con 10 reps detecta tu morfología y línea base personal',
              '💡 Con 30 reps recibes comparaciones sesión a sesión',
            ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [const SizedBox(width: 4),
                  Expanded(child: Text(t, style: const TextStyle(
                      color: BM.textSecondary, fontSize: 12)))]))),
            const SizedBox(height: 8),
            LinearPercentIndicator(lineHeight: 10,
              percent: (baseReps/10.0).clamp(0.0,1.0),
              barRadius: const Radius.circular(5), backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
              padding: EdgeInsets.zero, animation: true),
            const SizedBox(height: 6),
            Text('$baseReps / 10 reps registradas',
                style: const TextStyle(color: BM.textHint, fontSize: 11)),
          ])),
        ],

        // Percentil vs atletas
        if (result.paramsSummary['one_rm_average'] != null) ...[
          const SizedBox(height: 20),
          const SectionHeader(title: '🏆 Tu nivel vs atletas'),
          const SizedBox(height: 12),
          PercentileWidget(
            oneRm: (result.paramsSummary['one_rm_average'] as num).toDouble(),
            bodyWeight: 75.0,
            sex: 'M',
            exercise: result.exerciseType,
          ),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  String _phaseTitle(String p) => const {
    'collecting': '🌱 Construyendo tu perfil',
    'learning':   '🧠 Aprendiendo tu técnica',
    'active':     '✅ Tu IA personal activa',
    'optimizing': '🎯 Optimizando tu técnica',
  }[p] ?? 'Modelo IA';

  String _phaseSub(String p, int base, int total) {
    if (p == 'collecting') return '$base de 10 reps para activar';
    if (p == 'learning')   return '$total de 30 reps para análisis completo';
    if (p == 'active')     return '$total reps — recomendaciones personalizadas';
    return '$total reps — optimización avanzada';
  }

  String _progressHint(String p, int base, int total) {
    if (p == 'collecting')
      return 'Sube ${10-base} videos más para activar tu IA personal';
    if (p == 'learning')
      return 'Tu modelo está calibrando tus parámetros personales';
    return 'Tu IA compara cada sesión con tu baseline personal';
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon; final Color color; final String title, message;
  const _InsightCard({required this.icon, required this.color, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        Text(message, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
      ])),
    ]));
}

class _TrendRow extends StatelessWidget {
  final String param, trend;
  const _TrendRow({required this.param, required this.trend});
  static const _labels = {
    'rep_score':'Score técnico','knee_angle_min':'Profundidad de rodilla',
    'left_valgus':'Valgo izquierdo','right_valgus':'Valgo derecho',
    'trunk_lean_max':'Inclinación de tronco','acl_risk_score':'Riesgo de rodilla',
    'lumbar_risk_score':'Riesgo lumbar','knee_asymmetry_pct':'Simetría bilateral',
  };
  @override
  Widget build(BuildContext context) {
    final label  = _labels[param] ?? param.replaceAll('_',' ');
    final isGood = trend == 'improving';
    final isWarn = trend == 'worsening';
    final color  = isGood ? BM.accent : isWarn ? BM.error : BM.textSecondary;
    final icon   = isGood ? Icons.trending_up_rounded
        : isWarn ? Icons.trending_down_rounded : Icons.trending_flat_rounded;
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 13))),
        Text(isGood?'Mejorando ↑':isWarn?'Empeorando ↓':'Estable →',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]));
  }
}

class _RecCard extends StatelessWidget {
  final Map rec;
  const _RecCard({required this.rec});
  @override
  Widget build(BuildContext context) {
    final type  = rec['type'] as String? ?? '';
    final color = type.contains('risk') ? BM.error
        : type == 'mobility'            ? BM.warning
        :                                 BM.accent;
    return Container(margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rec['title'] ?? '', style: TextStyle(color: color,
            fontWeight: FontWeight.w700, fontSize: 13)),
        if ((rec['message'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(rec['message'], style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
        ],
        if ((rec['action'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.arrow_right_rounded, color: BM.accent, size: 16),
            Expanded(child: Text(rec['action'],
                style: const TextStyle(color: BM.accent, fontSize: 11))),
          ]),
        ],
      ]));
  }
}







class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = AnalysisRepository();
  List<WorkoutSessionModel> _items = [];
  bool _loading = true; String? _filter;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _items = []);
    setState(() => _loading = true);
    try {
      final d = await _repo.getWorkouts(page: 1, exerciseType: _filter);
      if (mounted) setState(() { _items = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Historial'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/dashboard'))),
    body: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _FChip('Todos', _filter==null, () { setState(()=>_filter=null); _load(reset:true); }),
          ...[('Sentadilla','squat'),('Peso muerto','deadlift'),('Press banca','bench_press')]
              .map((e) => Padding(padding: const EdgeInsets.only(left: 8),
                  child: _FChip(e.$1, _filter==e.$2, () { setState(()=>_filter=e.$2); _load(reset:true); }))),
        ])),
      Expanded(child: _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : _items.isEmpty ? const Center(child: Text('Sin sesiones', style: TextStyle(color: BM.textSecondary)))
        : RefreshIndicator(color: BM.primary, onRefresh: () => _load(reset: true),
            child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length,
              itemBuilder: (_, i) {
                final w = _items[i]; final ex = ExerciseInfo.fromId(w.exerciseType); final c = BM.scoreColor(w.techniqueScore);
                return GestureDetector(
                  onTap: w.jobId != null ? () async {
                    final vm = context.read<AnalysisViewModel>();
                    vm.reset();
                    try {
                      final result = await AnalysisRepository().getResults(w.jobId!);
                      vm.setResultFromHistory(result);
                      if (context.mounted) context.go('/results');
                    } catch (_) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo cargar el informe'), backgroundColor: Color(0xFFFF5252)));
                    }
                  } : null,
                  child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.04))),
                  child: Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(13)),
                        child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 22)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ex.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                      Text(DateFormat('EEEE d MMM yyyy','es').format(w.sessionDate), style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
                      Text('${w.totalSets}×${w.totalReps} reps${w.weightKg!=null?' · ${w.weightKg!.toStringAsFixed(0)} kg':''}', style: const TextStyle(fontSize: 12, color: BM.textHint)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${w.techniqueScore.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c)),
                      const Text('/100', style: TextStyle(fontSize: 10, color: BM.textHint)),
                    ]),
                  ])).animate().fadeIn(delay: Duration(milliseconds: i * 40)));
              }))),
    ]),
    bottomNavigationBar: BioBottomNav(current: 2, onTap: (i) {
      if (i==0) context.go('/dashboard'); if (i==1) context.go('/progression'); if (i==3) context.go('/calculator'); if (i==4) context.go('/profile');
    }));

  Widget _FChip(String l, bool a, VoidCallback t) => GestureDetector(onTap: t,
    child: AnimatedContainer(duration: 180.ms, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: a?BM.primary:BM.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: a?BM.primary:Colors.white.withOpacity(0.08))),
      child: Text(l, style: TextStyle(fontSize: 13, color: a?Colors.white:BM.textSecondary, fontWeight: FontWeight.w500))));
}

// ════════════════════════════════════════════════════════════════════════════
// CALCULATOR
// ════════════════════════════════════════════════════════════════════════════
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override State<CalculatorScreen> createState() => _CalculatorScreenState();
}
class _CalculatorScreenState extends State<CalculatorScreen> {
  final _repo = AnalysisRepository(); final _wCtrl = TextEditingController(); final _rCtrl = TextEditingController();
  String _ex = 'squat'; OneRMModel? _res; bool _loading = false; String? _err;
  @override void dispose() { _wCtrl.dispose(); _rCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Calculadora 1RM')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(18)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.calculate_rounded, color: Colors.white, size: 24), SizedBox(height: 8),
          Text('Calcula tu 1RM', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Fórmulas Epley (1985) y Brzycki (1993)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])).animate().fadeIn(),
      const SizedBox(height: 20),
      ...ExerciseInfo.all.map((ex) => GestureDetector(
        onTap: () => setState(() {
          _ex = ex.id;
          _res = null;
        }),
        child: AnimatedContainer(
          duration: 150.ms,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _ex == ex.id ? BM.primary.withOpacity(0.1) : BM.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _ex == ex.id
                  ? BM.primary
                  : Colors.white.withOpacity(0.05),
              width: _ex == ex.id ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                ex.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                ex.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ex == ex.id
                      ? BM.primary
                      : BM.textPrimary,
                ),
              ),
              const Spacer(),
              if (_ex == ex.id)
                const Icon(
                  Icons.check_circle_rounded,
                  color: BM.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      )).toList(),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: TextFormField(controller: _wCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: BM.textPrimary),
            decoration: const InputDecoration(labelText: 'Peso kg', suffixText: 'kg'), onChanged: (_)=>setState(()=>_res=null))),
        const SizedBox(width: 14),
        Expanded(child: TextFormField(controller: _rCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: BM.textPrimary),
            decoration: const InputDecoration(labelText: 'Reps'), onChanged: (_)=>setState(()=>_res=null))),
      ]),
      if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: BM.error, fontSize: 13))),
      const SizedBox(height: 20),
      GBtn(text: 'Calcular 1RM', icon: Icons.calculate_rounded, loading: _loading, onTap: _calc),
      if (_res != null) ...[
        const SizedBox(height: 24),
        GlassCard(borderColor: BM.primary.withOpacity(0.3), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('1RM estimado', style: TextStyle(color: BM.textSecondary, fontSize: 14)),
            Text('${_res!.oneRmAverage.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: BM.primary)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: BM.elevated, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Epley', style: TextStyle(fontSize: 11, color: BM.textSecondary)),
                Text('${_res!.oneRmEpley.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BM.textPrimary)),
              ]))),
            const SizedBox(width: 10),
            Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: BM.elevated, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Brzycki', style: TextStyle(fontSize: 11, color: BM.textSecondary)),
                Text('${_res!.oneRmBrzycki.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BM.textPrimary)),
              ]))),
          ]),
        ])).animate().fadeIn(),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Tabla de equivalencias'), const SizedBox(height: 12),
        GlassCard(child: Column(children: _res!.equivalences.entries.take(8).map((e) {
          final d  = e.value as Map<String,dynamic>;
          final wk = (d['weight_kg'] as num).toDouble();
          final rp = d['approx_reps'] as int;
          final pt = double.tryParse(e.key.replaceAll('%','')) ?? 0;
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
            SizedBox(width: 44, child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BM.primary))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pt/100, minHeight: 5, backgroundColor: BM.elevated,
                    valueColor: AlwaysStoppedAnimation(BM.primary.withOpacity(0.5+pt/200))))),
            const SizedBox(width: 10),
            SizedBox(width: 68, child: Text('${wk.toStringAsFixed(1)} kg', textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BM.textPrimary))),
            SizedBox(width: 32, child: Text('×$rp', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: BM.textHint))),
          ]));
        }).toList())).animate().fadeIn(),
      ],
      const SizedBox(height: 40),
    ])),
    bottomNavigationBar: BioBottomNav(current: 3, onTap: (i) {
      if (i==0) context.go('/dashboard'); if (i==1) context.go('/progression'); if (i==2) context.go('/history'); if (i==4) context.go('/profile');
    }));

  Future<void> _calc() async {
    final w = double.tryParse(_wCtrl.text); final r = int.tryParse(_rCtrl.text);
    if (w==null||w<=0) { setState(()=>_err='Ingresa un peso válido'); return; }
    if (r==null||r<=0||r>30) { setState(()=>_err='Reps debe ser entre 1 y 30'); return; }
    setState((){_loading=true;_err=null;});
    try { final res = await _repo.calculateOneRM(_ex,w,r); if(mounted) setState((){_res=res;_loading=false;}); }
    catch(e) { if(mounted) setState((){_err='Error de conexión. Verifica el backend.';_loading=false;}); }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROFILE
// ════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(backgroundColor: BM.bg,
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        Center(child: Column(children: [
          Container(width: 88, height: 88,
              decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0,8))]),
              child: Center(child: Text(auth.displayName.isNotEmpty?auth.displayName[0].toUpperCase():'U',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(height: 14),
          Text(auth.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BM.textPrimary)),
          const SizedBox(height: 4),
          Text(auth.user?.email ?? '', style: const TextStyle(fontSize: 13, color: BM.textSecondary)),
          const SizedBox(height: 8),
          RoleBadge(role: auth.role),
        ])),
        const SizedBox(height: 28),
        const SectionHeader(title: '📊 Mis patrones de error'), const SizedBox(height: 12),
        _ErrorPatternsCard(),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Configuración'), const SizedBox(height: 12),
        ...[
          (Icons.tune_rounded, 'Funciones opcionales', '/settings'),
          (Icons.psychology_rounded, 'Modelo IA personal', '/ai_model'),
          (Icons.history_rounded, 'Historial de sesiones', '/history'),
          (Icons.emoji_events_rounded, 'Mis logros', '/achievements'),
          if (!auth.isCoach && !auth.isAdmin)
            (Icons.school_rounded, 'Convertirme en entrenador', '/become-coach'),
          if (!auth.isCoach && !auth.isAdmin)
            (Icons.link_rounded, 'Vincular con entrenador', '/link-coach'),
          if (auth.isCoach) (Icons.school_rounded, 'Mi perfil de entrenador', '/become-coach'),
          if (auth.isCoach || auth.isAdmin) (Icons.people_rounded, 'Panel de entrenador', '/coach'),
          if (auth.isAdmin) (Icons.admin_panel_settings_rounded, 'Panel de administrador', '/admin'),
        ].map((e) => Container(margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(tileColor: BM.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: () => context.go(e.$3),
            leading: Icon(e.$1, color: BM.textSecondary, size: 20),
            title: Text(e.$2, style: const TextStyle(fontSize: 15, color: BM.textPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 14)))),
        const SizedBox(height: 20),
        const SizedBox(height: 4),
        GestureDetector(onTap: () async { await auth.signOut(); if (context.mounted) context.go('/login'); },
          child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BM.error.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BM.error.withOpacity(0.2))),
            child: const Row(children: [Icon(Icons.logout_rounded, color: BM.error, size: 20), SizedBox(width: 14),
              Text('Cerrar sesión', style: TextStyle(color: BM.error, fontSize: 15, fontWeight: FontWeight.w500))]))),
        const SizedBox(height: 16),
        const Text('BioMove v4.0.0 · 40 parámetros biomecánicos', style: TextStyle(fontSize: 11, color: BM.textHint)),
        const SizedBox(height: 40),
      ])),
      bottomNavigationBar: BioBottomNav(current: 4, onTap: (i) {
        if(i==0)context.go('/dashboard');if(i==1)context.go('/progression');if(i==2)context.go('/history');if(i==3)context.go('/calculator');
      }));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS, AI MODEL, ACHIEVEMENTS, LIVE — stubs con funcionalidad completa
// ════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _theme = ThemeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Funciones opcionales'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: ()=>context.go('/profile')),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _group('Apariencia'),
        _switchTile(
          icon: Icons.dark_mode_rounded, title: 'Modo oscuro',
          subtitle: 'Tema oscuro para cuidar tu vista',
          value: _theme.isDark,
          onChanged: (_) { HapticService.light(); _theme.toggle(); setState((){}); },
        ),
        const SizedBox(height: 20),

        _group('Análisis'),
        _selectTile(
          icon: Icons.speed_rounded, title: 'Calidad de análisis',
          value: _settings.analysisQuality == 'fast' ? 'Rápida' : 'Precisa',
          onTap: () => _pickOption('Calidad de análisis',
              {'fast':'Rápida (menos precisa)','precise':'Precisa (recomendada)'},
              _settings.analysisQuality, (v){ _settings.setAnalysisQuality(v); setState((){}); }),
        ),
        const SizedBox(height: 20),

        _group('Notificaciones y privacidad'),
        _switchTile(
          icon: Icons.notifications_rounded, title: 'Notificaciones',
          subtitle: 'Avisar cuando termine un análisis',
          value: _settings.notifications,
          onChanged: (v) { HapticService.light(); _settings.setNotifications(v); setState((){}); },
        ),
        _switchTile(
          icon: Icons.sports_rounded, title: 'Compartir con entrenador',
          subtitle: 'Enviar nuevas sesiones automáticamente',
          value: _settings.shareWithCoach,
          onChanged: (v) { HapticService.light(); _settings.setShareWithCoach(v); setState((){}); },
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 0),

        _group('Almacenamiento'),
        _actionTile(
          icon: Icons.cleaning_services_rounded, title: 'Limpiar caché de videos',
          subtitle: 'Liberar espacio de videos temporales',
          color: BM.warning,
          onTap: _clearCache,
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _group(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(title.toUpperCase(),
        style: const TextStyle(color: BM.textHint, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.0)),
  );

  Widget _switchTile({required IconData icon, required String title,
      required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: BM.primary, size: 22),
        title: Text(title, style: const TextStyle(color: BM.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
        value: value, onChanged: onChanged, activeColor: BM.primary,
      ),
    );
  }

  Widget _selectTile({required IconData icon, required String title,
      required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { HapticService.light(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(children: [
          Icon(icon, color: BM.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(color: BM.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
          const Icon(Icons.chevron_right_rounded, color: BM.textHint, size: 20),
        ]),
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String title,
      required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { HapticService.medium(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  void _pickOption(String title, Map<String,String> options, String current, ValueChanged<String> onSelect) {
    showModalBottomSheet(context: context, backgroundColor: BM.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: BM.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...options.entries.map((e) {
            final sel = e.key == current;
            return GestureDetector(
              onTap: () { HapticService.select(); onSelect(e.key); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? BM.primary.withOpacity(0.12) : BM.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? BM.primary : Colors.white.withOpacity(0.05))),
                child: Row(children: [
                  Expanded(child: Text(e.value, style: TextStyle(
                      color: sel ? BM.primary : BM.textPrimary, fontSize: 14,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400))),
                  if (sel) const Icon(Icons.check_circle_rounded, color: BM.primary, size: 20),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ])),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: BM.card,
      title: const Text('Limpiar caché', style: TextStyle(color: BM.textPrimary)),
      content: const Text('¿Eliminar los videos temporales del dispositivo? Esto no afecta tus análisis guardados.',
          style: TextStyle(color: BM.textSecondary)),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Cancelar')),
        TextButton(onPressed: ()=>Navigator.pop(context,true),
            child: const Text('Limpiar', style: TextStyle(color: BM.error))),
      ],
    ));
    if (confirm != true) return;
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        for (final f in dir.listSync()) {
          try { if (f.path.endsWith('.mp4')) f.deleteSync(); } catch (_) {}
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caché limpiado'), backgroundColor: BM.accent));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo limpiar el caché'), backgroundColor: BM.error));
    }
  }
}

class AIModelScreen extends StatefulWidget {
  const AIModelScreen({super.key});
  @override State<AIModelScreen> createState() => _AIModelScreenState();
}

// ── Historial de errores frecuentes ──────────────────────────────────────────
class _ErrorPatternsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = context.watch<AnalysisViewModel>().result;
    // Usar feedback del último resultado o mensaje vacío
    final feedback = history?.riskFeedback ?? [];
    if (feedback.isEmpty) return GlassCard(child: const Center(child: Padding(
      padding: EdgeInsets.all(12),
      child: Text('Analiza más sesiones para ver tus patrones de error',
          style: TextStyle(color: BM.textSecondary, fontSize: 13),
          textAlign: TextAlign.center))));

    return GlassCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...feedback.take(3).map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(
              color: f.isInjuryRisk ? BM.error : BM.warning,
              shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(f.message,
              style: const TextStyle(color: BM.textSecondary, fontSize: 12))),
          Text('${f.frequencyPct}%',
              style: TextStyle(
                color: f.isInjuryRisk ? BM.error : BM.warning,
                fontWeight: FontWeight.w700, fontSize: 12)),
        ]))),
    ]));
  }
}

class _AIModelScreenState extends State<AIModelScreen> {
  final _repo = AnalysisRepository(); AIModelStateModel? _m; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final m = await _repo.getAIModel(); if (mounted) setState((){_m=m;_loading=false;}); }
    catch (_) { if (mounted) setState(()=>_loading=false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Modelo IA personal'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: ()=>context.go('/profile'))),
    body: _loading ? const Center(child: CircularProgressIndicator(color: BM.primary))
      : RefreshIndicator(color: BM.primary, onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
          if (_m != null) ...[
            // ── Estado de fase con progreso ──────────────────────────
            GlassCard(borderColor: BM.primary.withOpacity(0.3), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(_m!.phaseEmoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_m!.phase.toUpperCase(), style: const TextStyle(fontSize: 10, color: BM.primary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  Text(_m!.phaseMessage, style: const TextStyle(fontSize: 13, color: BM.textPrimary, height: 1.4)),
                ]))]),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _m!.progress, minHeight: 8, backgroundColor: BM.elevated, valueColor: const AlwaysStoppedAnimation(BM.primary))),
              const SizedBox(height: 6),
              Text(_m!.nextMilestone, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
            ])).animate().fadeIn(),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: MetricCard(label: 'Reps totales', value: '${_m!.totalReps}', icon: Icons.repeat_rounded, color: BM.primary, animDelay: 0)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Sesiones', value: '${_m!.totalSessions}', icon: Icons.calendar_today_rounded, color: BM.accent, animDelay: 60)),
            ]),
            const SizedBox(height: 20),

            // ── Guía: cómo construir tu modelo ───────────────────────
            _AIGuideCard(model: _m!),
            const SizedBox(height: 20),

            // ── Lo que la IA sabe de ti (solo si hay datos) ──────────
            if (_m!.totalReps > 0) ...[
              const SectionHeader(title: '🔬 Lo que tu IA sabe de ti'),
              const SizedBox(height: 12),
              _AIKnowledgeCard(model: _m!),
              const SizedBox(height: 20),
            ],

            // ── Morfología detectada ─────────────────────────────────
            if (_m!.morphology.isNotEmpty) ...[
              const SectionHeader(title: '🧬 Tu morfología'),
              const SizedBox(height: 12),
              _MorphologyCard(morphology: _m!.morphology),
              const SizedBox(height: 20),
            ],

            // ── Tendencias por parámetro ─────────────────────────────
            if (_m!.improvementTrends.isNotEmpty) ...[
              const SectionHeader(title: '📈 Tus tendencias'),
              const SizedBox(height: 12),
              _TrendsCard(trends: _m!.improvementTrends),
              const SizedBox(height: 20),
            ],

            // ── Recomendaciones personalizadas ───────────────────────
            if (_m!.recommendations.isNotEmpty) ...[
              const SectionHeader(title: '🎯 Recomendaciones para ti'),
              const SizedBox(height: 12),
              ..._m!.recommendations.take(4).map((r) => _RecommendationCard(rec: r)),
            ],
          ] else const Center(child: Padding(padding: EdgeInsets.only(top: 60),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.psychology_outlined, color: BM.textHint, size: 48),
              SizedBox(height: 16),
              Text('Modelo IA en construcción', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              SizedBox(height: 8),
              Text('Analiza más sesiones para activar tu IA personal', style: TextStyle(color: BM.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ]))),
          const SizedBox(height: 40),
        ])));
}

// ── Guía interactiva de construcción del modelo IA ──────────────────────────
class _AIGuideCard extends StatefulWidget {
  final AIModelStateModel model;
  const _AIGuideCard({required this.model});
  @override State<_AIGuideCard> createState() => _AIGuideCardState();
}
class _AIGuideCardState extends State<_AIGuideCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final baselineDone = m.baselineReps.clamp(0, 10);
    final steps = [
      ('Sube videos con poco peso', '≤50% de tu 1RM para tu línea base', m.totalReps > 0),
      ('Acumula 10 reps base', '$baselineDone/10 reps registradas', m.baselineReps >= 10),
      ('La IA aprende tu técnica', 'Detecta tu morfología y patrones', m.phase != 'collecting'),
      ('Recibe recomendaciones', 'Comparaciones sesión a sesión (30+ reps)', m.isActive),
    ];
    return GestureDetector(
      onTap: () { HapticService.light(); setState(() => _open = !_open); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [BM.primary.withOpacity(0.12), BM.card]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BM.primary.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.school_rounded, color: BM.primary, size: 22),
            const SizedBox(width: 10),
            const Expanded(child: Text('¿Cómo construir tu IA personal?',
                style: TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
            AnimatedRotation(turns: _open ? 0.5 : 0, duration: 200.ms,
              child: const Icon(Icons.keyboard_arrow_down_rounded, color: BM.primary)),
          ]),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(padding: const EdgeInsets.only(top: 14),
              child: Column(children: steps.asMap().entries.map((e) {
                final i = e.key; final (title, desc, done) = e.value;
                return Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: done ? BM.accent : BM.elevated, shape: BoxShape.circle),
                      child: Center(child: done
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                        : Text('${i+1}', style: const TextStyle(color: BM.textHint, fontSize: 12, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(color: done ? BM.accent : BM.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(desc, style: const TextStyle(color: BM.textSecondary, fontSize: 11, height: 1.3)),
                    ])),
                  ]));
              }).toList())),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: 250.ms,
          ),
        ]),
      ),
    );
  }
}

// ── Lo que la IA sabe del usuario ───────────────────────────────────────────
class _AIKnowledgeCard extends StatelessWidget {
  final AIModelStateModel model;
  const _AIKnowledgeCard({required this.model});
  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, Color)>[];
    facts.add((Icons.repeat_rounded, 'He analizado ${model.totalReps} repeticiones tuyas en ${model.totalSessions} sesiones', BM.primary));
    if (model.classifierReady) {
      facts.add((Icons.verified_rounded, 'Mi clasificador (${model.classifierVersion}) está entrenado con tu técnica', BM.accent));
    }
    if (model.phase == 'collecting') {
      facts.add((Icons.hourglass_top_rounded, 'Aún estoy recopilando tu línea base — necesito 10 reps con poco peso', BM.warning));
    } else if (model.phase == 'learning') {
      facts.add((Icons.psychology_rounded, 'Estoy aprendiendo qué es normal en tu técnica personal', BM.info));
    } else if (model.isActive) {
      facts.add((Icons.check_circle_rounded, 'Ya conozco tu técnica — comparo cada sesión con tu propio estándar', BM.accent));
    }
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: facts.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(f.$1, color: f.$3, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(f.$2, style: const TextStyle(color: BM.textPrimary, fontSize: 13, height: 1.4))),
        ]))).toList()));
  }
}

// ── Morfología ──────────────────────────────────────────────────────────────
class _MorphologyCard extends StatelessWidget {
  final Map<String, dynamic> morphology;
  const _MorphologyCard({required this.morphology});
  @override
  Widget build(BuildContext context) {
    final labels = {
      'femur_length': 'Longitud de fémur',
      'ankle_mobility': 'Movilidad de tobillo',
      'torso_length': 'Longitud de torso',
      'hip_structure': 'Estructura de cadera',
    };
    final entries = morphology.entries.where((e) => labels.containsKey(e.key)).toList();
    if (entries.isEmpty) {
      return GlassCard(child: const Text('Sigue subiendo videos para que detecte tu morfología',
          style: TextStyle(color: BM.textSecondary, fontSize: 13)));
    }
    return GlassCard(child: Column(children: entries.map((e) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        const Icon(Icons.straighten_rounded, color: BM.accent, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(labels[e.key]!, style: const TextStyle(color: BM.textPrimary, fontSize: 13))),
        Text(e.value.toString(), style: const TextStyle(color: BM.accent, fontSize: 13, fontWeight: FontWeight.w600)),
      ]))).toList()));
  }
}

// ── Tendencias ──────────────────────────────────────────────────────────────
class _TrendsCard extends StatelessWidget {
  final Map<String, String> trends;
  const _TrendsCard({required this.trends});
  @override
  Widget build(BuildContext context) {
    final labels = {
      'knee_angle': 'Profundidad de rodilla',
      'trunk_lean': 'Postura del tronco',
      'valgus': 'Control de valgo',
      'symmetry': 'Simetría',
      'tempo': 'Control de tempo',
    };
    (IconData, Color, String) trendStyle(String t) {
      switch (t) {
        case 'improving': return (Icons.trending_up_rounded, BM.accent, 'Mejorando');
        case 'worsening': return (Icons.trending_down_rounded, BM.error, 'Empeorando');
        case 'stable':    return (Icons.trending_flat_rounded, BM.info, 'Estable');
        default:          return (Icons.remove_rounded, BM.textHint, 'Sin datos');
      }
    }
    final entries = trends.entries.where((e) => labels.containsKey(e.key)).toList();
    if (entries.isEmpty) {
      return GlassCard(child: const Text('Necesito más sesiones para detectar tendencias',
          style: TextStyle(color: BM.textSecondary, fontSize: 13)));
    }
    return GlassCard(child: Column(children: entries.map((e) {
      final (icon, color, label) = trendStyle(e.value);
      return Padding(padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(labels[e.key]!, style: const TextStyle(color: BM.textPrimary, fontSize: 13))),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]));
    }).toList()));
  }
}

// ── Recomendación ───────────────────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  const _RecommendationCard({required this.rec});
  @override
  Widget build(BuildContext context) {
    final title = rec['title']?.toString() ?? rec['message']?.toString() ?? 'Recomendación';
    final detail = rec['detail']?.toString() ?? rec['correction']?.toString() ?? '';
    final priority = rec['priority']?.toString() ?? 'normal';
    final color = priority == 'high' ? BM.error : priority == 'medium' ? BM.warning : BM.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lightbulb_rounded, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(detail, style: const TextStyle(color: BM.textSecondary, fontSize: 12, height: 1.4)),
          ],
        ])),
      ]),
    );
  }
}

class _Achievement {
  final String title, emoji, desc;
  final bool unlocked;
  final double progress; // 0..1 hacia desbloquear
  _Achievement(this.title, this.emoji, this.desc, this.unlocked, this.progress);
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override State<AchievementsScreen> createState() => _AchievementsScreenState();
}
class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = AnalysisRepository();
  List<_Achievement> _list = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final workouts = await _repo.getWorkouts();
      AIModelStateModel? ai;
      try { ai = await _repo.getAIModel(); } catch (_) {}

      final totalSessions = workouts.length;
      final totalReps = workouts.fold<int>(0, (s, w) => s + w.totalReps) +
                        (ai?.totalReps ?? 0);
      final bestScore = workouts.isEmpty ? 0.0
          : workouts.map((w) => w.techniqueScore).reduce((a, b) => a > b ? a : b);
      final aiActive = ai != null && (ai.phase == 'active' || ai.phase == 'optimizing');

      // Calcular racha de días consecutivos
      int streak = _calcStreak(workouts.map((w) => w.sessionDate).toList());

      _list = [
        _Achievement('Primera repetición', '🎯', 'Sube tu primer video',
            totalSessions >= 1, (totalSessions/1).clamp(0,1).toDouble()),
        _Achievement('10 sesiones', '💪', 'Realiza 10 sesiones',
            totalSessions >= 10, (totalSessions/10).clamp(0,1).toDouble()),
        _Achievement('Técnica perfecta', '⭐', 'Obtén un score de 90+',
            bestScore >= 90, (bestScore/90).clamp(0,1).toDouble()),
        _Achievement('100 repeticiones', '🔢', 'Acumula 100 reps',
            totalReps >= 100, (totalReps/100).clamp(0,1).toDouble()),
        _Achievement('Constancia', '📅', 'Completa 25 sesiones',
            totalSessions >= 25, (totalSessions/25).clamp(0,1).toDouble()),
        _Achievement('Modelo IA activo', '🧠', 'Alcanza la fase activa de tu IA',
            aiActive, aiActive ? 1.0 : ((ai?.totalReps ?? 0)/30).clamp(0,1).toDouble()),
        _Achievement('3 días de racha', '🔥', 'Entrena 3 días seguidos',
            streak >= 3, (streak/3).clamp(0,1).toDouble()),
        _Achievement('Atleta dedicado', '🏆', 'Acumula 300 reps analizadas',
            totalReps >= 300, (totalReps/300).clamp(0,1).toDouble()),
      ];
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _calcStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final days = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i+1]).inDays == 1) { streak++; } else { break; }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _list.where((a) => a.unlocked).length;
    return Scaffold(backgroundColor: BM.bg,
      appBar: AppBar(title: const Text('Logros'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: ()=>context.go('/profile'))),
      body: _loading
        ? ListView(padding: const EdgeInsets.all(20),
            children: List.generate(6, (i) => Padding(padding: const EdgeInsets.only(bottom:10),
                child: BioShimmer(width: double.infinity, height: 76, radius: 16))))
        : ListView(padding: const EdgeInsets.all(20), children: [
            // Resumen de progreso
            Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Text('🏅', style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$unlocked de ${_list.length} logros',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Sigue entrenando para desbloquear más',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ])).animate().fadeIn(),
            const SizedBox(height: 16),
            ..._list.asMap().entries.map((e) {
              final a = e.value;
              return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: a.unlocked ? BM.primary.withOpacity(0.08) : BM.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.unlocked ? BM.primary.withOpacity(0.35) : Colors.white.withOpacity(0.04)),
                  boxShadow: a.unlocked ? [BoxShadow(color: BM.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0,4))] : []),
                child: Column(children: [
                  Row(children: [
                    Text(a.emoji, style: TextStyle(fontSize: 30,
                        color: a.unlocked ? null : const Color(0xFF303048))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: a.unlocked ? BM.textPrimary : BM.textSecondary)),
                      Text(a.desc, style: TextStyle(fontSize: 12,
                          color: a.unlocked ? BM.textSecondary : BM.textHint)),
                    ])),
                    a.unlocked
                        ? const Icon(Icons.check_circle_rounded, color: BM.primary, size: 24)
                        : const Icon(Icons.lock_rounded, color: BM.textHint, size: 18),
                  ]),
                  if (!a.unlocked && a.progress > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: a.progress, minHeight: 5,
                          backgroundColor: BM.elevated,
                          valueColor: const AlwaysStoppedAnimation(BM.primaryLt))),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight,
                      child: Text('${(a.progress*100).toInt()}%',
                          style: const TextStyle(fontSize: 10, color: BM.textHint))),
                  ],
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: e.key*50));
            }),
            const SizedBox(height: 40),
          ]),
    );
  }
}

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});
  @override State<LiveScreen> createState() => _LiveScreenState();
}
class _LiveScreenState extends State<LiveScreen> {
  @override
  void initState() {
    super.initState();
    // Pantalla en construcción — redirigir al dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/dashboard');
    });
  }
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF07070F),
    body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// COACH + ADMIN screens
// ════════════════════════════════════════════════════════════════════════════
class AthleteDashboardScreen extends StatelessWidget {
  const AthleteDashboardScreen({super.key});
  @override Widget build(BuildContext context) => const _AthleteDashboardImpl();
}

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});
  @override State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}
class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  final _api = ApiService();
  List<dynamic> _athletes = [];
  bool _loading = true;
  String? _inviteCode;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getMyAthletes();
      if (mounted) setState(() { _athletes = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _generateCode() async {
    try {
      final code = await _api.generateInviteCode();
      setState(() => _inviteCode = code);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: BM.card,
        title: const Text('Código de invitación', style: TextStyle(color: BM.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Comparte este código con tu atleta:', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(color: BM.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BM.primary.withOpacity(0.4))),
            child: Text(_inviteCode ?? '', style: const TextStyle(color: BM.primary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 4))),
          const SizedBox(height: 8),
          const Text('Válido por 7 días', style: TextStyle(color: BM.textHint, fontSize: 11)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: BM.error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Panel del Entrenador'),
      leading: IconButton(
        icon: const Icon(Icons.home_rounded),
        onPressed: () => context.go('/dashboard'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_rounded, color: BM.accent),
          tooltip: 'Generar código de invitación',
          onPressed: _generateCode,
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : _athletes.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.group_outlined, color: BM.textHint, size: 56),
                const SizedBox(height: 16),
                const Text('Sin atletas vinculados', style: TextStyle(color: BM.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Genera un código y compártelo con tus atletas', style: TextStyle(color: BM.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                GBtn(text: 'Generar código', icon: Icons.qr_code_rounded, height: 48, onTap: _generateCode),
              ]))
            : RefreshIndicator(color: BM.primary, onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _athletes.length,
                  itemBuilder: (_, i) {
                    final a = _athletes[i];
                    final score = (a['last_score'] as num?)?.toDouble() ?? 0.0;
                    final c = BM.scoreColor(score);
                    final name = a['display_name'] ?? a['email'] ?? 'Atleta';
                    return GestureDetector(
                      onTap: () => context.go('/coach/athlete/${a['id']}?name=${Uri.encodeComponent(name)}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: Row(children: [
                          CircleAvatar(radius: 24, backgroundColor: BM.primary.withOpacity(0.15),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                style: const TextStyle(color: BM.primary, fontWeight: FontWeight.w700, fontSize: 18))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: const TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(a['email'] ?? '', style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
                            if (a['last_session_date'] != null)
                              Text('Última sesión: ${DateFormat('d MMM yyyy','es').format(DateTime.parse(a['last_session_date']))}',
                                  style: const TextStyle(color: BM.textHint, fontSize: 11)),
                          ])),
                          if (score > 0) Column(children: [
                            Text('${score.toStringAsFixed(0)}', style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('/100', style: const TextStyle(color: BM.textHint, fontSize: 10)),
                          ]),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: BM.textHint),
                        ]),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                    );
                  },
                )),
  );
}

class AthleteDetailScreen extends StatefulWidget {
  final String athleteId;
  const AthleteDetailScreen({super.key, required this.athleteId});
  @override State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}
class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  final _api = ApiService();
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getAthleteSessions(widget.athleteId);
      if (mounted) setState(() { _sessions = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final athleteName = GoRouterState.of(context).uri.queryParameters['name'] ?? 'Atleta';
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: Text(athleteName),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/coach')),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Enviar retroalimentación',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                otherUserId: widget.athleteId,
                otherUserName: athleteName,
                otherRole: 'athlete',
              ),
            )),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: BM.primary))
          : _sessions.isEmpty
              ? const Center(child: Text('Sin sesiones registradas', style: TextStyle(color: BM.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    final s = _sessions[i];
                    final score = (s['technique_score'] as num?)?.toDouble() ?? 0.0;
                    final c = BM.scoreColor(score);
                    final ex = ExerciseInfo.fromId(s['exercise_type'] ?? 'squat');
                    final jobId = s['job_id'];
                    return GestureDetector(
                      onTap: jobId != null ? () async {
                        try {
                          final result = await _api.getAthleteSessionResults(widget.athleteId, jobId);
                          context.read<AnalysisViewModel>().setResultFromHistory(result);
                          if (context.mounted) context.go('/results');
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo cargar: $e'), backgroundColor: const Color(0xFFFF5252)));
                        }
                      } : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.04))),
                        child: Row(children: [
                          Container(width: 42, height: 42,
                              decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 20)))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(ex.label, style: const TextStyle(color: BM.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            if (s['session_date'] != null)
                              Text(DateFormat('d MMM yyyy','es').format(DateTime.parse(s['session_date'])),
                                  style: const TextStyle(color: BM.textSecondary, fontSize: 11)),
                            Text('${s['total_reps'] ?? 0} reps', style: const TextStyle(color: BM.textHint, fontSize: 11)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${score.toStringAsFixed(0)}', style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w800)),
                            const Text('/100', style: TextStyle(color: BM.textHint, fontSize: 10)),
                          ]),
                          if (jobId != null) const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.chevron_right_rounded, color: BM.textHint, size: 18)),
                        ]),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                    );
                  },
                ),
    );
  }
}

// ── Admin Dashboard ────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();
  Map<String,dynamic>? _stats;
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final r = await _api.get('/admin/stats');
      if (mounted) setState(() { _stats = r; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Panel Administrador'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/dashboard'))),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: BM.primary))
      : RefreshIndicator(color: BM.primary, onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
          // Stats cards
          Row(children: [
            _StatCard('Usuarios', '${_stats?['total_users'] ?? 0}', Icons.people_rounded, BM.primary),
            const SizedBox(width: 12),
            _StatCard('Sesiones', '${_stats?['total_sessions'] ?? 0}', Icons.video_library_rounded, BM.accent),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _StatCard('Entrenadores', '${_stats?['total_coaches'] ?? 0}', Icons.sports_rounded, BM.warning),
            const SizedBox(width: 12),
            _StatCard('Hoy', '${_stats?['sessions_today'] ?? 0}', Icons.today_rounded, BM.info),
          ]),
          const SizedBox(height: 24),
          // Quick links
          _AdminTile(icon: Icons.manage_accounts_rounded, title: 'Gestión de usuarios',
              subtitle: 'Ver, suspender y cambiar roles',
              onTap: () => context.go('/admin/users')),
          const SizedBox(height: 10),
          _AdminTile(icon: Icons.psychology_rounded, title: 'Modelo IA global',
              subtitle: 'Ver estado y reentrenar el clasificador',
              onTap: () => context.go('/admin/model')),
          const SizedBox(height: 10),
          _AdminTile(icon: Icons.bar_chart_rounded, title: 'Estadísticas',
              subtitle: 'Métricas de uso de la app',
              color: BM.accent,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _AdminStatsScreen(stats: _stats)))),
        ])),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
    ])));
}

class _AdminTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  final Color color;
  const _AdminTile({required this.icon, required this.title, required this.subtitle,
      required this.onTap, this.color = BM.primary});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
      ])));
}

// ── Admin Users Screen ──────────────────────────────────────────────────────
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _api = ApiService();
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/admin/users');
      if (mounted) setState(() { _users = r is List ? r : (r['users'] ?? []); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty ? _users
        : _users.where((u) => (u['email'] ?? '').toLowerCase().contains(_search.toLowerCase())
            || (u['display_name'] ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(backgroundColor: BM.bg,
      appBar: AppBar(title: const Text('Gestión de usuarios'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: ()=>context.go('/admin'))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(hintText: 'Buscar por email o nombre',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _search = '')) : null),
            onChanged: (v) => setState(() => _search = v),
          )),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: BM.primary))
          : RefreshIndicator(color: BM.primary, onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,0,16,20),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final u = filtered[i];
                  final role = u['role'] ?? 'athlete';
                  final active = u['is_active'] ?? true;
                  final roleColor = role=='admin' ? BM.error : role=='coach' ? BM.warning : BM.primary;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: active ? Colors.white.withOpacity(0.05) : BM.error.withOpacity(0.2))),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: roleColor.withOpacity(0.15),
                          child: Text((u['display_name'] ?? u['email'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.w700))),
                      title: Text(u['display_name'] ?? u['email'] ?? 'Sin nombre',
                          style: const TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(u['email'] ?? '', style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(role, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 6),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: BM.textHint, size: 20),
                          color: BM.surface,
                          onSelected: (action) => _handleUserAction(u['id'], action, active, role),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'toggle', child: Text(active ? 'Suspender' : 'Activar',
                                style: TextStyle(color: active ? BM.error : BM.accent))),
                            const PopupMenuItem(value: 'athlete', child: Text('→ Atleta', style: TextStyle(color: BM.primary))),
                            const PopupMenuItem(value: 'coach', child: Text('→ Entrenador', style: TextStyle(color: BM.warning))),
                            const PopupMenuItem(value: 'admin', child: Text('→ Admin', style: TextStyle(color: BM.error))),
                          ],
                        ),
                      ]),
                    ),
                  );
                }))),
      ]),
    );
  }
  Future<void> _handleUserAction(String userId, String action, bool active, String role) async {
    // Confirmación para cambios de rol
    if (action == 'athlete' || action == 'coach' || action == 'admin') {
      final labels = {'athlete': 'Atleta', 'coach': 'Entrenador', 'admin': 'Admin'};
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: BM.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Cambiar rol', style: TextStyle(color: BM.textPrimary, fontSize: 16)),
          content: Text('¿Cambiar el rol de este usuario a ${labels[action]}?',
              style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(color: BM.textSecondary))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: BM.primary),
                child: const Text('Confirmar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      if (action == 'toggle') {
        // suspend/activate — endpoints dedicados
        await _api.post('/admin/users/$userId/${active ? 'suspend' : 'activate'}', {});
      } else {
        // Cambio de rol — usa el endpoint /action con change_role
        await _api.post('/admin/users/$userId/action',
            {'action': 'change_role', 'value': action});
      }
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Usuario actualizado'), backgroundColor: BM.accent));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: BM.error));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EJERCICIOS ADICIONALES (Peso muerto & Press banca — análisis básico)
// ════════════════════════════════════════════════════════════════════════════
class AdditionalExercisesScreen extends StatelessWidget {
  const AdditionalExercisesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Ejercicios adicionales'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/capture'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: BM.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BM.warning.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: BM.warning, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Análisis básico con reglas fijas. Sin clasificador IA — los parámetros se calculan con umbrales estándar de la literatura biomecánica.',
            style: TextStyle(color: BM.textSecondary, fontSize: 12, height: 1.4))),
        ])).animate().fadeIn(),
      const SizedBox(height: 20),
      _ExerciseCard(
        emoji: '🏋️',
        title: 'Peso muerto',
        subtitle: 'Deadlift — Vista lateral',
        params: const ['Ángulo de cadera', 'Posición lumbar', 'Extensión de rodilla',
            'Trayectoria de barra', 'Inclinación del tronco', 'Posición de la barra vs pies'],
        color: BM.primary,
        onTap: () => context.go('/capture?exercise=deadlift'),
      ).animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 14),
      _ExerciseCard(
        emoji: '🤸',
        title: 'Press de banca',
        subtitle: 'Bench press — Vista lateral',
        params: const ['Ángulo de codos', 'Posición de hombros', 'Trayectoria de barra',
            'Rango de movimiento', 'Posición de muñecas', 'Arco lumbar'],
        color: BM.accent,
        onTap: () => context.go('/capture?exercise=bench_press'),
      ).animate().fadeIn(delay: 160.ms),
      const SizedBox(height: 30),
      const Center(child: Text('Más ejercicios próximamente',
          style: TextStyle(color: BM.textHint, fontSize: 12))),
    ]),
  );
}

class _ExerciseCard extends StatelessWidget {
  final String emoji, title, subtitle; final List<String> params;
  final Color color; final VoidCallback onTap;
  const _ExerciseCard({required this.emoji, required this.title, required this.subtitle,
      required this.params, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.10), BM.card], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Analizar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 6,
          children: params.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2))),
            child: Text(p, style: TextStyle(color: color, fontSize: 11)),
          )).toList()),
      ])));
}

class AdminModelScreen extends StatefulWidget {
  const AdminModelScreen({super.key});
  @override State<AdminModelScreen> createState() => _AdminModelScreenState();
}
class _AdminModelScreenState extends State<AdminModelScreen> {
  final _api = ApiService();
  Map<String,dynamic>? _info;
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/admin/model/info');
      if (mounted) setState(() { _info = r; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Modelo IA Global'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: ()=>context.go('/admin'))),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: BM.primary))
      : RefreshIndicator(color: BM.primary, onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            // Estado del clasificador
            Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (_info?['ready'] == true ? BM.accent : BM.error).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (_info?['ready'] == true ? BM.accent : BM.error).withOpacity(0.3))),
              child: Row(children: [
                Icon(_info?['ready'] == true ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: _info?['ready'] == true ? BM.accent : BM.error, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_info?['ready'] == true ? 'Clasificador activo' : 'Sin clasificador cargado',
                      style: TextStyle(color: _info?['ready'] == true ? BM.accent : BM.error,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(_info?['ready'] == true
                      ? 'Versión: ${_info?['version'] ?? 'desconocida'}'
                      : 'Usando reglas fijas como fallback',
                      style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
                ])),
              ])).animate().fadeIn(),
            const SizedBox(height: 16),
            // Métricas del modelo
            if (_info?['ready'] == true) ...[ 
              _InfoCard('Muestras entrenamiento', '${_info?['n_samples'] ?? 0}', Icons.dataset_rounded, BM.primary),
              const SizedBox(height: 10),
              _InfoCard('Precisión', '${((_info?['accuracy'] ?? 0.0) * 100).toStringAsFixed(1)}%', Icons.analytics_rounded, BM.accent),
              const SizedBox(height: 10),
              // Clases del modelo
              if (_info?['classes'] != null) Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Clases del clasificador', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: (_info!['classes'] as List).map<Widget>((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: BM.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: BM.primary.withOpacity(0.3))),
                      child: Text(c.toString(), style: const TextStyle(color: BM.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    )).toList()),
                ])).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
            ],
            // Instrucción de entrenamiento
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: BM.warning.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BM.warning.withOpacity(0.25))),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.terminal_rounded, color: BM.warning, size: 16),
                  SizedBox(width: 8),
                  Text('Reentrenar el clasificador', style: TextStyle(color: BM.warning, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
                SizedBox(height: 8),
                Text('Para reentrenar con nuevas repeticiones, ejecuta en el servidor:',
                    style: TextStyle(color: BM.textSecondary, fontSize: 12)),
                SizedBox(height: 6),
                Text('python biomove_pc.py --train',
                    style: TextStyle(color: BM.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Requiere mínimo 10 repeticiones acumuladas en la base de datos.',
                    style: TextStyle(color: BM.textHint, fontSize: 11)),
              ])).animate().fadeIn(delay: 150.ms),
          ])),
  );
}

class _InfoCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _InfoCard(this.label, this.value, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 13))),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
    ])).animate().fadeIn();
}

// ── Admin Stats Screen ────────────────────────────────────────────────────────
class _AdminStatsScreen extends StatelessWidget {
  final Map<String,dynamic>? stats;
  const _AdminStatsScreen({this.stats});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Estadísticas'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _StatRow('Total usuarios',    '${stats?['total_users']    ?? 0}', Icons.people_rounded,         BM.primary),
      _StatRow('Total entrenadores','${stats?['total_coaches']  ?? 0}', Icons.sports_rounded,          BM.warning),
      _StatRow('Total sesiones',    '${stats?['total_sessions'] ?? 0}', Icons.video_library_rounded,   BM.accent),
      _StatRow('Sesiones hoy',      '${stats?['sessions_today'] ?? 0}', Icons.today_rounded,            BM.info),
    ]),
  );
}

class _StatRow extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatRow(this.label, this.value, this.icon, this.color);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Row(children: [
      Icon(icon, color: color, size: 24), const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 14))),
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
    ])).animate().fadeIn();
}

// ── Athlete Dashboard impl (inline) ──────────────────────────────────────────
class _AthleteDashboardImpl extends StatefulWidget {
  const _AthleteDashboardImpl();
  @override State<_AthleteDashboardImpl> createState() => _AthleteDashboardImplState();
}
class _AthleteDashboardImplState extends State<_AthleteDashboardImpl> with SingleTickerProviderStateMixin {
  final _repo = AnalysisRepository(); late AnimationController _pulse;
  List<WorkoutSessionModel> _workouts = []; bool _loading = true;
  @override void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: 2000.ms)..repeat(reverse: true); _load(); }
  @override void dispose() { _pulse.dispose(); super.dispose(); }
  Future<void> _load() async {
    try { final d = await _repo.getWorkouts(); if(mounted) setState((){_workouts=d;_loading=false;}); }
    catch (_) { if(mounted) setState(()=>_loading=false); }
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final name = auth.displayName.split(' ').first;
    return Scaffold(backgroundColor: BM.bg,
      body: Stack(children: [
        const Positioned.fill(child: ParticleBackground(count: 20)),
        RefreshIndicator(color: BM.primary, onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverAppBar(floating: true, backgroundColor: BM.bg,
            title: AnimatedBuilder(animation: _pulse, builder: (_,__)=>ShaderMask(
              shaderCallback: (b)=>LinearGradient(colors: [BM.primary,BM.accent,BM.primaryLt],
                  stops: [0,_pulse.value,1.0]).createShader(b),
              child: const Text('BioMove',style: TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w800)))),
            actions: [
              IconButton(icon: const Icon(Icons.psychology_rounded,color:BM.textSecondary), onPressed:()=>context.go('/ai_model')),
              IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded,color:BM.textSecondary), tooltip:'Mensajes', onPressed:()=>context.go('/chat')),
              GestureDetector(onTap:()=>context.go('/profile'), child: Padding(padding: const EdgeInsets.only(right:16),
                child: CircleAvatar(radius:17,backgroundColor:BM.primary.withOpacity(0.2),
                  child: Text(auth.displayName.isNotEmpty?auth.displayName[0].toUpperCase():'U',
                      style: const TextStyle(color:BM.primary,fontWeight:FontWeight.w700,fontSize:14)))))],
          ),
          SliverPadding(padding: const EdgeInsets.fromLTRB(20,0,20,100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Text('Hola, $name 💪', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: BM.textPrimary)).animate().fadeIn(),
              Text(DateFormat("EEEE d 'de' MMMM",'es').format(DateTime.now()), style: const TextStyle(fontSize:13,color:BM.textSecondary)).animate().fadeIn(delay:100.ms),
              const SizedBox(height: 20),
              GestureDetector(onTap:()=>context.go('/capture'), child: Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color:BM.primary.withOpacity(0.4),blurRadius:24,offset:const Offset(0,10))]),
                child: Row(children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('NUEVO ANÁLISIS', style: TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:1.2)),
                    SizedBox(height:8),
                    Text('Analiza tu técnica ahora', style: TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w800,height:1.2)),
                    SizedBox(height:5),
                    Text('40 parámetros biomecánicos', style: TextStyle(color:Colors.white70,fontSize:12)),
                  ])),
                  Container(width:64,height:64,decoration:BoxDecoration(color:Colors.white.withOpacity(0.12),borderRadius:BorderRadius.circular(18)),
                      child: const Icon(Icons.videocam_rounded,color:Colors.white,size:32)),
                ]))).animate().fadeIn(delay:150.ms),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Últimas sesiones'), const SizedBox(height: 12),
              if (_loading) ...List.generate(3,(i)=>Padding(padding: const EdgeInsets.only(bottom:8),child:BioShimmer(width:double.infinity,height:72,radius:16)))
              else if (_workouts.isEmpty) GlassCard(child: Column(children: [
                  const Icon(Icons.fitness_center_rounded,color:BM.textHint,size:44), const SizedBox(height:12),
                  const Text('Sin sesiones aún',style:TextStyle(color:BM.textPrimary,fontWeight:FontWeight.w600)),
                  const SizedBox(height:16),
                  GBtn(text:'Analizar ejercicio',height:44,onTap:()=>context.go('/capture'))]))
              else ..._workouts.take(5).toList().asMap().entries.map((e) {
                  final w=e.value; final ex=ExerciseInfo.fromId(w.exerciseType); final c=BM.scoreColor(w.techniqueScore);
                  return GestureDetector(
                    onTap: w.jobId != null ? () async {
                      final vm = context.read<AnalysisViewModel>();
                      try {
                        final result = await AnalysisRepository().getResults(w.jobId!);
                        vm.setResultFromHistory(result);
                        if (context.mounted) context.go('/results');
                      } catch (_) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo cargar el informe'), backgroundColor: Color(0xFFFF5252)));
                      }
                    } : null,
                    child: Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color:BM.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white.withOpacity(0.04)),
                      boxShadow:[BoxShadow(color:c.withOpacity(0.12),blurRadius:12,offset:const Offset(0,4))]),
                    child: Row(children: [
                      Container(width:42,height:42,decoration:BoxDecoration(gradient:BM.grad1,borderRadius:BorderRadius.circular(12)),child:Center(child:Text(ex.emoji,style:const TextStyle(fontSize:20)))),
                      const SizedBox(width:12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ex.label,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:BM.textPrimary)),
                        Text('${w.totalSets}×${w.totalReps} reps${w.weightKg!=null?' · ${w.weightKg!.toStringAsFixed(0)} kg':''}',style:const TextStyle(fontSize:12,color:BM.textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${w.techniqueScore.toStringAsFixed(0)}',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:c)),
                        Text(DateFormat('d MMM').format(w.sessionDate),style:const TextStyle(fontSize:10,color:BM.textHint)),
                      ]),
                    ]))).animate().fadeIn(delay:Duration(milliseconds:e.key*50));
                }),
              const SizedBox(height: 20),
            ]))),
        ])),
      ]),
      bottomNavigationBar: BioBottomNav(current: 0, onTap: (i) {
        if(i==1)context.go('/progression');if(i==2)context.go('/history');if(i==3)context.go('/calculator');if(i==4)context.go('/profile');
      }),
      floatingActionButton: GestureDetector(onTap:()=>context.go('/capture'),
        child: AnimatedBuilder(animation:_pulse,builder:(_,child)=>Transform.translate(offset:Offset(0,-2*_pulse.value),child:child),
          child: Container(margin: const EdgeInsets.only(bottom:6),
            decoration: BoxDecoration(gradient:BM.grad1,borderRadius:BorderRadius.circular(20),
                boxShadow:[BoxShadow(color:BM.primary.withOpacity(0.5),blurRadius:20,offset:const Offset(0,6))]),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal:26,vertical:14),
              child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.add_rounded,color:Colors.white,size:22),SizedBox(width:8),Text('Analizar',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:15))]))))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BECOME COACH SCREEN
// ════════════════════════════════════════════════════════════════════════════
class BecomeCoachScreen extends StatefulWidget {
  const BecomeCoachScreen({super.key});
  @override State<BecomeCoachScreen> createState() => _BecomeCoachScreenState();
}

class _BecomeCoachScreenState extends State<BecomeCoachScreen> {
  bool _loading = false;
  String? _inviteCode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isCoach = auth.isCoach;

    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: Text(isCoach ? 'Mi perfil de entrenador' : 'Convertirme en entrenador'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: BM.gradCoach, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isCoach ? '¡Ya eres entrenador!' : 'Modo entrenador',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                Text(isCoach
                    ? 'Genera tu código de invitación para vincular atletas'
                    : 'Accede a las funciones de supervisión de atletas',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ])),
            ]),
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          if (!isCoach) ...[
            // What coach gets
            const SectionHeader(title: '¿Qué obtienes como entrenador?'),
            const SizedBox(height: 12),
            ...[
              (Icons.analytics_rounded, 'Acceso a los informes biomecánicos de tus atletas'),
              (Icons.error_outline_rounded, 'Ver solo los errores detectados (datos protegidos)'),
              (Icons.people_rounded, 'Gestionar múltiples atletas desde tu panel'),
              (Icons.link_rounded, 'Vincular atletas mediante código de invitación'),
            ].asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(e.value.$1, color: BM.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(e.value.$2, style: const TextStyle(color: BM.textPrimary, fontSize: 13))),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60))),
            const SizedBox(height: 16),

            // Privacy notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: BM.warning.withOpacity(0.07), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BM.warning.withOpacity(0.25))),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shield_outlined, color: BM.warning, size: 16),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Privacidad protegida: como entrenador solo puedes ver los errores técnicos detectados. Los datos biomecánicos numéricos y el video del atleta permanecen privados y bajo su control.',
                  style: TextStyle(color: BM.warning, fontSize: 12, height: 1.4),
                )),
              ]),
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 24),

            if (_error != null) ...[
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: BM.error, fontSize: 13))),
            ],

            GBtn(
              text: 'Activar modo entrenador',
              icon: Icons.school_rounded,
              colors: const [Color(0xFF005C45), BM.accentDk],
              loading: _loading,
              onTap: _loading ? null : () => _activate(auth),
            ).animate().fadeIn(delay: 320.ms),
          ] else ...[
            // Coach is already activated — show invite code section
            const SectionHeader(title: 'Código de invitación'),
            const SizedBox(height: 12),
            P('Comparte este código con tus atletas para que se vinculen contigo. Ellos deberán aprobarlo desde su app.'),
            const SizedBox(height: 16),

            if (_inviteCode != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BM.accent.withOpacity(0.4))),
                child: Column(children: [
                  const Text('Tu código de invitación', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(_inviteCode!, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                      color: BM.accent, letterSpacing: 8)),
                  const SizedBox(height: 8),
                  const Text('Válido por 7 días — el atleta lo ingresa en Vincular con entrenador',
                      textAlign: TextAlign.center, style: TextStyle(color: BM.textSecondary, fontSize: 11)),
                ]),
              ).animate().scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 12),
              GBtn(text: 'Generar nuevo código', icon: Icons.refresh_rounded, height: 48,
                  loading: _loading, onTap: _loading ? null : () => _generateCode(context)),
            ] else
              GBtn(text: 'Generar código de invitación', icon: Icons.link_rounded,
                  colors: const [Color(0xFF005C45), BM.accentDk],
                  loading: _loading, onTap: _loading ? null : () => _generateCode(context)),

            const SizedBox(height: 24),
            GBtn(text: 'Ir al panel de entrenador', icon: Icons.people_rounded, height: 48,
                onTap: () => context.go('/coach')),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // Simple P helper
  Widget P(String text) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(color: BM.textSecondary, fontSize: 13, height: 1.5)));

  Future<void> _activate(AuthViewModel auth) async {
    setState(() { _loading = true; _error = null; });
    final ok = await auth.becomeCoach();
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) setState(() => _error = auth.error ?? 'Error al activar');
    }
  }

  Future<void> _generateCode(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final code = await UserRepository().generateInviteCode();
      if (mounted) setState(() { _inviteCode = code; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LINK COACH SCREEN — Atleta ingresa código para vincularse con su entrenador
// ════════════════════════════════════════════════════════════════════════════
class LinkCoachScreen extends StatefulWidget {
  const LinkCoachScreen({super.key});
  @override State<LinkCoachScreen> createState() => _LinkCoachScreenState();
}

class _LinkCoachScreenState extends State<LinkCoachScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMsg;

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Vincular con entrenador'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/profile')),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.link_rounded, color: Colors.white, size: 24),
            SizedBox(height: 10),
            Text('Vincular con tu entrenador', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('Ingresa el código que te dio tu entrenador. Deberás aprobar el acceso antes de que pueda ver tus informes.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 24),

        // Privacy notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BM.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BM.primary.withOpacity(0.2))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.shield_rounded, color: BM.primary, size: 15),
              SizedBox(width: 8),
              Text('Tu privacidad está protegida', style: TextStyle(color: BM.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            SizedBox(height: 6),
            Text('Tu entrenador solo podrá ver:\n• Los errores técnicos detectados en tu sentadilla\n• Tu score de técnica por sesión\n\nNO tendrá acceso a:\n• Tus videos\n• Tus datos biomecánicos numéricos completos\n• Tu información personal',
                style: TextStyle(color: BM.textSecondary, fontSize: 12, height: 1.5)),
          ]),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),

        if (_error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(_error!, style: const TextStyle(color: BM.error, fontSize: 13))),

        if (_successMsg != null) ...[
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              color: BM.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BM.accent.withOpacity(0.3))),
            child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: BM.accent, size: 32),
              const SizedBox(height: 8),
              Text(_successMsg!, textAlign: TextAlign.center,
                  style: const TextStyle(color: BM.accent, fontSize: 14, fontWeight: FontWeight.w600)),
            ])),
          const SizedBox(height: 16),
          GBtn(text: 'Volver al perfil', height: 48, onTap: () => context.go('/profile')),
        ] else ...[
          TextFormField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: BM.textPrimary, fontSize: 28, fontWeight: FontWeight.w700,
                letterSpacing: 6),
            textAlign: TextAlign.center,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Código del entrenador',
              counterText: '',
              prefixIcon: Icon(Icons.tag_rounded, size: 20),
            ),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 24),
          GBtn(
            text: 'Vincular con entrenador',
            icon: Icons.link_rounded,
            loading: _loading,
            onTap: _loading ? null : () => _link(context.read<AuthViewModel>()),
          ).animate().fadeIn(delay: 220.ms),
        ],

        const SizedBox(height: 40),
      ]),
    ),
  );

  Future<void> _link(AuthViewModel auth) async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) { setState(() => _error = 'Ingresa el código de tu entrenador'); return; }
    setState(() { _loading = true; _error = null; });
    final ok = await auth.linkCoachCode(code);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        setState(() => _successMsg = '¡Vinculado exitosamente!\nTu entrenador ahora puede ver tus informes de errores técnicos.');
      } else {
        setState(() => _error = auth.error ?? 'Código inválido o expirado. Pide uno nuevo a tu entrenador.');
      }
    }
  }
}
