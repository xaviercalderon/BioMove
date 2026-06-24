// view/screens/capture/capture_screen.dart
// ISO/IEC 25010:2023 — Operabilidad + Aprendizabilidad — Patrón MVVM
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../../viewmodel/analysis_viewmodel.dart';
import '../../../viewmodel/camera_viewmodel.dart';
import '../../../model/analysis_model.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker     = ImagePicker();
  final _weightCtrl = TextEditingController();
  late final CameraViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = CameraViewModel();
    _vm.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _vm.removeListener(_rebuild);
    _vm.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisViewModel>(builder: (ctx, analysis, _) {
      if (analysis.step == AnalysisStep.completed && analysis.result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/results');
        });
      }
      if (analysis.isLoading) return _AnalyzingView(analysis: analysis);

      return Scaffold(
        backgroundColor: BM.bg,
        appBar: AppBar(
          title: const Text('Nuevo análisis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/dashboard'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: BM.primary),
              tooltip: 'Guía de análisis',
              onPressed: () => _showParamsGuide(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Error con retry prominente — ISO Operabilidad
            if (analysis.error != null)
              _ErrorBanner(message: analysis.error!, onDismiss: analysis.reset,
                  onRetry: () => _analyze(analysis))
                  .animate().fadeIn().slideY(begin: -0.1),

            // ── Selector de video ──────────────────────────────────────
            _VideoSelector(vm: _vm,
              onPickGallery: () => _pickGallery(analysis),
              onRecord: () => _showPreRecordGuide(context, analysis)),
            const SizedBox(height: 20),

            // ── Ejercicio ──────────────────────────────────────────────
            const SectionHeader(title: 'Ejercicio'),
            const SizedBox(height: 10),
            // Solo sentadilla — 40 parámetros biomecánicos validados
            _ExerciseTile(ex: ExerciseInfo.squat, selected: true,
                onTap: () {}, delay: 80),
            const SizedBox(height: 18),

            // ── Vista del video ────────────────────────────────────────
            Row(children: [
              const Expanded(child: SectionHeader(title: 'Vista del video')),
              GestureDetector(
                onTap: () => _showViewGuide(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BM.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BM.primary.withOpacity(0.25)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.help_outline_rounded, color: BM.primary, size: 13),
                    SizedBox(width: 4),
                    Text('¿Cuál usar?', style: TextStyle(color: BM.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ViewTile(
                label: 'Lateral', icon: Icons.person_outline_rounded,
                badge: '${_vm.lateralParams.length} params',
                recommended: _vm.recommendedView == 'lateral',
                selected: _vm.view == 'lateral',
                onTap: () => _vm.setView('lateral'))),
              const SizedBox(width: 12),
              Expanded(child: _ViewTile(
                label: 'Frontal', icon: Icons.face_rounded,
                badge: '${_vm.frontalParams.length} params',
                recommended: _vm.recommendedView == 'frontal',
                selected: _vm.view == 'frontal',
                onTap: () => _vm.setView('frontal'))),
            ]).animate().fadeIn(delay: 240.ms),

            if (!_vm.viewMatchesExercise) ...[
              const SizedBox(height: 8),
              _ViewMismatchBanner(recommended: _vm.recommendedView),
            ],
            const SizedBox(height: 18),

            // ── Peso con info expandible ───────────────────────────────
            Row(children: [
              const Expanded(child: SectionHeader(title: 'Peso utilizado')),
              GestureDetector(
                onTap: _vm.toggleWeightInfo,
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _vm.showWeightInfo ? BM.warning.withOpacity(0.12) : BM.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _vm.showWeightInfo ? BM.warning.withOpacity(0.35) : BM.elevated),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.help_outline_rounded,
                        color: _vm.showWeightInfo ? BM.warning : BM.textSecondary, size: 13),
                    const SizedBox(width: 4),
                    Text('¿Para qué sirve?', style: TextStyle(
                        color: _vm.showWeightInfo ? BM.warning : BM.textSecondary, fontSize: 11)),
                  ]),
                ),
              ),
            ]),

            AnimatedCrossFade(
              duration: 250.ms,
              crossFadeState: _vm.showWeightInfo
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _WeightInfoPanel(),
              secondChild: const SizedBox(height: 8),
            ),

            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: BM.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              onChanged: _vm.setWeight,
              decoration: const InputDecoration(
                labelText: 'Peso en kg (opcional)',
                prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
                suffixText: 'kg',
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),
            _AnalyzeButton(vm: _vm, onTap: () => _analyze(analysis)).animate().fadeIn(delay: 360.ms),
            const SizedBox(height: 40),
          ]),
        ),
      );
    });
  }

  Future<void> _pickGallery(AnalysisViewModel analysis) async {
    analysis.reset();
    final f = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 10));
    if (f != null && mounted) await _vm.setVideoFile(f.path);
  }

  Future<void> _analyze(AnalysisViewModel analysis) async {
    if (!_vm.canAnalyze) return;
    // Si el validador detectó un plano distinto al seleccionado → alertar
    if (_vm.viewMismatch && _vm.detectedView != null) {
      final proceed = await _showViewMismatchAlert(_vm.detectedView!);
      if (!proceed) return;
    }
    final ok = await _confirmView();
    if (!ok) return;
    await analysis.analyze(filePath: _vm.filePath!, exerciseType: _vm.exercise,
        videoView: _vm.view, weightKg: _vm.weightKg);
  }

  Future<bool> _showViewMismatchAlert(String detected) async {
    final detectedLabel = detected == 'lateral' ? 'lateral (de lado)' : 'frontal (de frente)';
    final selectedLabel = _vm.view == 'lateral'  ? 'lateral (de lado)' : 'frontal (de frente)';
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: BM.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: BM.warning, size: 22),
          SizedBox(width: 8),
          Text('Vista incorrecta', style: TextStyle(color: BM.textPrimary, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'El video fue grabado en vista $detectedLabel, pero tienes seleccionada la vista $selectedLabel.',
            style: const TextStyle(color: BM.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: BM.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BM.warning.withOpacity(0.3))),
            child: const Text(
              'Si continúas con la vista incorrecta, los parámetros calculados no serán precisos.',
              style: TextStyle(color: BM.warning, fontSize: 12, height: 1.4),
            ),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BM.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13)),
            onPressed: () { _vm.setView(detected); Navigator.pop(context, true); },
            child: Text('Cambiar a $detectedLabel',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar con la vista actual',
                style: TextStyle(color: BM.textSecondary, fontSize: 12)),
          )),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: BM.textHint, fontSize: 12)),
          )),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmView() async {
    final isLat = _vm.view == 'lateral';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BM.card,
        title: Text(isLat ? '📐 Vista lateral' : '🎯 Vista frontal',
            style: const TextStyle(color: BM.textPrimary, fontSize: 16)),
        content: Text(isLat
            ? 'Asegúrate de que la persona esté de perfil. Si el video es de frente, cambia a "Frontal".'
            : 'Asegúrate de que la persona esté de frente. Si el video es de lado, cambia a "Lateral".',
            style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cambiar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuar')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showPreRecordGuide(BuildContext ctx, AnalysisViewModel analysis) async {
    // Mostrar dialog solo si el usuario no dijo "no mostrar"
    final proceed = await showPreRecordGuideIfNeeded(ctx);
    if (!proceed || !mounted) return;
    // Si el usuario confirmó, abrir cámara directamente
    final f = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 5));
    if (f != null && mounted) await _vm.setVideoFile(f.path);
  }

  void _showViewGuide(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _ViewGuideSheet(vm: _vm));
  }

  void _showParamsGuide(BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => _ParamsGuideScreen(vm: _vm)));
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message; final VoidCallback onDismiss, onRetry;
  const _ErrorBanner({required this.message, required this.onDismiss, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BM.error.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.error_outline_rounded, color: BM.error, size: 17),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: BM.error, fontSize: 13))),
        GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, color: BM.error, size: 15)),
      ]),
      const SizedBox(height: 10),
      GestureDetector(onTap: onRetry,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: BM.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BM.error.withOpacity(0.35))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded, color: BM.error, size: 15),
            SizedBox(width: 6),
            Text('Intentar de nuevo', style: TextStyle(color: BM.error, fontSize: 13, fontWeight: FontWeight.w600)),
          ]))),
    ]));
}

// ── Video Selector + Semáforo ISO ─────────────────────────────────────────────
class _VideoSelector extends StatelessWidget {
  final CameraViewModel vm; final VoidCallback onPickGallery, onRecord;
  const _VideoSelector({required this.vm, required this.onPickGallery, required this.onRecord});

  @override
  Widget build(BuildContext context) => Column(children: [
    GestureDetector(
      onTap: onPickGallery,
      child: AnimatedContainer(duration: 250.ms, height: 150, width: double.infinity,
        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor(vm.validation.status), width: vm.hasVideo ? 2 : 1)),
        child: vm.hasVideo ? _VideoReady(vm: vm) : const _VideoEmpty()),
    ).animate().fadeIn().slideY(begin: 0.08),
    if (vm.hasVideo) ...[const SizedBox(height: 8), _Semaphore(v: vm.validation)],
    const SizedBox(height: 8),
    GestureDetector(onTap: onRecord,
      child: Container(padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: const Row(children: [
          Icon(Icons.videocam_rounded, color: BM.error, size: 20),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Grabar con la cámara', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            Text('Ver guía de posición antes de grabar', style: TextStyle(color: BM.textSecondary, fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 13),
        ])),
    ).animate().fadeIn(delay: 70.ms),
  ]);

  Color _borderColor(VideoValidationStatus s) {
    switch (s) {
      case VideoValidationStatus.valid:      return BM.accent;
      case VideoValidationStatus.invalid:    return BM.error;
      case VideoValidationStatus.validating: return BM.warning;
      default: return Colors.white.withOpacity(0.07);
    }
  }
}

class _VideoReady extends StatelessWidget {
  final CameraViewModel vm;
  const _VideoReady({required this.vm});
  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    AnimatedSwitcher(duration: 300.ms, child: vm.validation.status == VideoValidationStatus.validating
      ? const CircularProgressIndicator(color: BM.warning, strokeWidth: 2)
      : Icon(vm.validation.allPassed ? Icons.check_circle_rounded : Icons.warning_rounded,
             color: vm.validation.allPassed ? BM.accent : BM.error, size: 30)),
    const SizedBox(height: 6),
    Text(vm.validation.status == VideoValidationStatus.validating ? 'Verificando...' :
         vm.validation.allPassed ? 'Video listo' : 'Video con problemas',
        style: TextStyle(color: vm.validation.allPassed ? BM.accent : BM.error, fontWeight: FontWeight.w700, fontSize: 14),
        overflow: TextOverflow.ellipsis, maxLines: 1),
    if (vm.validation.fileSizeMb != null)
      Text('${vm.validation.fileSizeMb!.toStringAsFixed(1)} MB',
          style: const TextStyle(color: BM.textSecondary, fontSize: 11),
          overflow: TextOverflow.ellipsis),
    const Text('Toca para cambiar', style: TextStyle(color: BM.textHint, fontSize: 11),
        overflow: TextOverflow.ellipsis),
  ]);
}

class _VideoEmpty extends StatelessWidget {
  const _VideoEmpty();
  @override
  Widget build(BuildContext context) => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.cloud_upload_outlined, color: BM.primary, size: 30),
    SizedBox(height: 8),
    Text('Seleccionar video de galería', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
    Text('MP4 · MOV · máx 500 MB · máx 10 min', style: TextStyle(color: BM.textSecondary, fontSize: 11)),
  ]);
}

// Semáforo visual — ISO Operabilidad
class _Semaphore extends StatelessWidget {
  final VideoValidationModel v;
  const _Semaphore({required this.v});
  @override
  Widget build(BuildContext context) {
    if (v.status == VideoValidationStatus.validating)
      return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: BM.warning.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: BM.warning)),
          SizedBox(width: 10),
          Text('Verificando video...', style: TextStyle(color: BM.warning, fontSize: 12)),
        ]));
    if (v.mainIssue != null)
      return Container(padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: BM.error.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BM.error.withOpacity(0.25))),
        child: Row(children: [
          const Icon(Icons.cancel_rounded, color: BM.error, size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(v.mainIssue!, style: const TextStyle(color: BM.error, fontSize: 12, fontWeight: FontWeight.w500))),
        ]));
    final viewLabel = v.detectedView == 'lateral' ? '📐 Vista lateral detectada'
                    : v.detectedView == 'frontal' ? '🎯 Vista frontal detectada'
                    : null;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: BM.accent.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BM.accent.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: BM.accent, shape: BoxShape.circle))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 700.ms),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('✓ Video listo para análisis',
              style: TextStyle(color: BM.accent, fontSize: 12, fontWeight: FontWeight.w600)),
          if (viewLabel != null)
            Text(viewLabel, style: const TextStyle(color: BM.accent, fontSize: 10)),
        ])),
        if (v.framesTotal > 0)
          Text('${v.framesOk}/${v.framesTotal} frames',
              style: const TextStyle(color: BM.accent, fontSize: 10)),
      ]));
  }
}

// ── Exercise Tile ──────────────────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final ExerciseInfo ex; final bool selected; final VoidCallback onTap; final int delay;
  const _ExerciseTile({required this.ex, required this.selected, required this.onTap, required this.delay});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: 180.ms, margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: selected ? BM.primary.withOpacity(0.1) : BM.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: selected ? BM.primary : Colors.white.withOpacity(0.05), width: selected ? 1.5 : 1),
      ),
      child: Row(children: [
        Text(ex.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ex.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? BM.primary : BM.textPrimary)),
          Text(ex.description, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
        ])),
        if (selected) const Icon(Icons.check_circle_rounded, color: BM.primary, size: 18)
        else const Icon(Icons.radio_button_unchecked, color: BM.textHint, size: 18),
      ]),
    )).animate().fadeIn(delay: Duration(milliseconds: delay));
}

// ── View Tile ─────────────────────────────────────────────────────────────────
class _ViewTile extends StatelessWidget {
  final String label, badge; final IconData icon;
  final bool selected, recommended; final VoidCallback onTap;
  const _ViewTile({required this.label, required this.icon, required this.badge,
      required this.selected, required this.recommended, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: 180.ms, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? BM.primary.withOpacity(0.1) : BM.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? BM.primary : Colors.transparent, width: 1.5),
      ),
      child: Column(children: [
        if (recommended) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
          child: const Text('Recomendado', style: TextStyle(color: BM.accent, fontSize: 9, fontWeight: FontWeight.w700))),
        Icon(icon, color: selected ? BM.primary : BM.textSecondary, size: 22),
        const SizedBox(height: 5),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? BM.primary : BM.textSecondary)),
        const SizedBox(height: 2),
        Text(badge, style: const TextStyle(fontSize: 10, color: BM.textHint)),
      ])));
}

// ── View Mismatch Banner ──────────────────────────────────────────────────────
class _ViewMismatchBanner extends StatelessWidget {
  final String recommended;
  const _ViewMismatchBanner({required this.recommended});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: BM.warning.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BM.warning.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.info_rounded, color: BM.warning, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text('Para este ejercicio se recomienda vista ${recommended == 'lateral' ? 'lateral (de lado)' : 'frontal (de frente)'}.',
          style: const TextStyle(color: BM.warning, fontSize: 11, height: 1.4))),
    ])).animate().fadeIn().slideY(begin: -0.1);
}

// ── Weight Info Panel ─────────────────────────────────────────────────────────
class _WeightInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: BM.warning.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BM.warning.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Para qué sirve el peso?',
          style: TextStyle(color: BM.warning, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      ...[
        '📊 Calcula tu 1RM estimado (fórmulas Epley y Brzycki)',
        '⚖️ Evalúa la carga relativa respecto a tu capacidad',
        '🦵 Ajusta los scores de riesgo articular según carga',
        '📈 Registra tu progreso de fuerza en el historial',
      ].map((t) => Padding(padding: const EdgeInsets.only(bottom: 4),
          child: Text(t, style: const TextStyle(color: BM.textSecondary, fontSize: 12, height: 1.4)))),
      const SizedBox(height: 4),
      const Text('Es opcional — sin este dato el análisis de postura funciona igual.',
          style: TextStyle(color: BM.textHint, fontSize: 11, fontStyle: FontStyle.italic)),
    ])).animate().fadeIn().slideY(begin: -0.05);
}

// ── Analyze Button ────────────────────────────────────────────────────────────
class _AnalyzeButton extends StatelessWidget {
  final CameraViewModel vm; final VoidCallback onTap;
  const _AnalyzeButton({required this.vm, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(children: [
    GBtn(
      text: vm.canAnalyze ? 'Analizar movimiento' : vm.analyzeBlockedReason,
      icon: vm.canAnalyze ? Icons.analytics_rounded : Icons.block_rounded,
      onTap: vm.canAnalyze ? onTap : null,
      colors: vm.canAnalyze ? const [BM.primary, BM.primaryDk] : const [Color(0xFF2A2A3E), Color(0xFF1E1E30)],
    ),
    if (!vm.canAnalyze && !vm.hasVideo) ...[
      const SizedBox(height: 8),
      const Text('Selecciona un video o grábalo con la cámara',
          textAlign: TextAlign.center, style: TextStyle(color: BM.textHint, fontSize: 12)),
    ],
  ]);
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOG: Guía pre-grabación — recordatorio con "No volver a mostrar"
// ════════════════════════════════════════════════════════════════════════════

/// Muestra el recordatorio PRE-grabación una sola vez (o hasta que el usuario diga "no mostrar")
/// Usa SharedPreferences para persistir la preferencia
Future<bool> showPreRecordGuideIfNeeded(BuildContext context) async {
  // Verificar si el usuario ya dijo "no mostrar"
  try {
    final prefs = await SharedPreferences.getInstance();
    final skip  = prefs.getBool('skip_pre_record_guide') ?? false;
    if (skip) return true; // ir directo a grabar
  } catch (_) {}

  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PreRecordDialog(),
  );
  return result ?? false;
}

class _PreRecordDialog extends StatefulWidget {
  const _PreRecordDialog();
  @override State<_PreRecordDialog> createState() => _PreRecordDialogState();
}

class _PreRecordDialogState extends State<_PreRecordDialog> {
  bool _neverShow = false;

  Future<void> _confirm(bool proceed) async {
    if (_neverShow) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('skip_pre_record_guide', true);
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context, proceed);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: BM.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Semáforo visual informativo
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 18, height: 18, decoration: const BoxDecoration(color: BM.error, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Container(width: 18, height: 18, decoration: const BoxDecoration(color: BM.warning, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Container(width: 18, height: 18, decoration: const BoxDecoration(color: BM.accent, shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 16),
        const Text('Antes de grabar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BM.textPrimary)),
        const SizedBox(height: 6),
        const Text('Verifica estas condiciones para un buen análisis:',
            textAlign: TextAlign.center, style: TextStyle(color: BM.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),

        // Las 3 condiciones en un solo recuadro
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(children: [
            _CondRow(icon: Icons.accessibility_new_rounded, text: 'Tu cuerpo completo es visible en la cámara'),
            const Divider(color: Color(0xFF1E1E30), height: 16),
            _CondRow(icon: Icons.wb_sunny_rounded, text: 'Hay buena iluminación, sin contraluces'),
            const Divider(color: Color(0xFF1E1E30), height: 16),
            _CondRow(icon: Icons.straighten_rounded, text: 'La cámara está a la altura de tu cadera'),
          ]),
        ),
        const SizedBox(height: 16),

        // No volver a mostrar
        GestureDetector(
          onTap: () => setState(() => _neverShow = !_neverShow),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: _neverShow ? BM.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _neverShow ? BM.primary : BM.elevated, width: 1.5)),
              child: _neverShow ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null),
            const SizedBox(width: 8),
            const Text('No volver a mostrar',
                style: TextStyle(color: BM.textSecondary, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 18),

        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _confirm(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BM.elevated)),
              child: const Center(child: Text('Cancelar', style: TextStyle(color: BM.textSecondary, fontWeight: FontWeight.w500)))),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => _confirm(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [BM.error.withOpacity(0.9), const Color(0xFFB71C1C)]),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Grabar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]))),
          )),
        ]),
      ]),
    ),
  );
}

class _CondRow extends StatelessWidget {
  final IconData icon; final String text;
  const _CondRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: BM.accent, size: 18),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(color: BM.textPrimary, fontSize: 12, height: 1.4))),
  ]);
}

class _ViewGuideSheet extends StatefulWidget {
  final CameraViewModel vm;
  const _ViewGuideSheet({required this.vm});
  @override State<_ViewGuideSheet> createState() => _ViewGuideSheetState();
}
class _ViewGuideSheetState extends State<_ViewGuideSheet> with SingleTickerProviderStateMixin {
  late AnimationController _anim; int _sel = 0;
  @override void initState() { super.initState(); _anim = AnimationController(vsync: this, duration: 2000.ms)..repeat(); }
  @override void dispose() { _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: BM.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 36, height: 4, decoration: BoxDecoration(color: BM.elevated, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      const Text('¿Vista lateral o frontal?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: BM.textPrimary)),
      const SizedBox(height: 6),
      const Text('Depende del ejercicio y qué quieres analizar', style: TextStyle(color: BM.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => setState(() => _sel = 0),
          child: AnimatedContainer(duration: 200.ms, padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: _sel==0?BM.primary.withOpacity(0.12):BM.card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _sel==0?BM.primary:BM.elevated)),
            child: const Column(children: [Icon(Icons.person_outline_rounded, size: 20, color: BM.primary), SizedBox(height: 3),
              Text('Lateral', style: TextStyle(color: BM.primary, fontSize: 12, fontWeight: FontWeight.w600))])))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: () => setState(() => _sel = 1),
          child: AnimatedContainer(duration: 200.ms, padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: _sel==1?BM.accent.withOpacity(0.12):BM.card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _sel==1?BM.accent:BM.elevated)),
            child: const Column(children: [Icon(Icons.face_rounded, size: 20, color: BM.accent), SizedBox(height: 3),
              Text('Frontal', style: TextStyle(color: BM.accent, fontSize: 12, fontWeight: FontWeight.w600))])))),
      ]),
      const SizedBox(height: 14),
      AnimatedBuilder(animation: _anim, builder: (_, __) => SizedBox(height: 110,
        child: CustomPaint(size: const Size(double.infinity, 110),
            painter: _ViewDiagram(t: _anim.value, isLateral: _sel == 0)))),
      const SizedBox(height: 14),
      Flexible(child: SingleChildScrollView(child: Wrap(spacing: 6, runSpacing: 6,
        children: (_sel == 0 ? widget.vm.lateralParams : widget.vm.frontalParams).map((p) =>
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: (_sel==0?BM.primary:BM.accent).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(p, style: TextStyle(color: _sel==0?BM.primary:BM.accent, fontSize: 11, fontWeight: FontWeight.w500)))).toList()))),
      const SizedBox(height: 16),
      GBtn(text: 'Entendido', icon: Icons.check_rounded, height: 48, onTap: () => Navigator.pop(context)),
    ]));
}

class _ViewDiagram extends CustomPainter {
  final double t; final bool isLateral;
  _ViewDiagram({required this.t, required this.isLateral});
  @override void paint(Canvas canvas, Size size) {
    final cx=size.width/2, cy=size.height/2;
    final bp=Paint()..color=BM.primary.withOpacity(0.7)..strokeWidth=2.5..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    canvas.drawCircle(Offset(cx,cy-36),10,Paint()..color=BM.accent..style=PaintingStyle.fill);
    canvas.drawLine(Offset(cx,cy-26),Offset(cx,cy-5),bp);
    canvas.drawLine(Offset(cx-15,cy-20),Offset(cx+15,cy-20),bp);
    canvas.drawLine(Offset(cx-9,cy-5),Offset(cx-12,cy+22),bp);
    canvas.drawLine(Offset(cx+9,cy-5),Offset(cx+12,cy+22),bp);
    final co = math.sin(t*math.pi*2)*4;
    if (isLateral) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx+55,cy+co),width:22,height:16),const Radius.circular(4)),
          Paint()..color=BM.primary.withOpacity(0.85)..style=PaintingStyle.fill);
      canvas.drawLine(
        Offset(cx + 12, cy),
        Offset(cx + 44, cy + co),
        Paint()
          ..color = BM.primary.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      _t(canvas,'Vista lateral\n(de lado)',cx+55,cy+26,BM.primary);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy+52+co),width:22,height:16),const Radius.circular(4)),
          Paint()..color=BM.accent.withOpacity(0.85)..style=PaintingStyle.fill);
      canvas.drawLine(
        Offset(cx, cy + 25),
        Offset(cx, cy + 44 + co),
        Paint()
          ..color = BM.accent.withOpacity(0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
       _t(canvas,'Vista frontal\n(de frente)',cx,cy+78,BM.accent);
    }
  }
  void _t(Canvas c, String text, double x, double y, Color col) {
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:col,fontSize:10,fontWeight:FontWeight.w600,height:1.4)),textDirection:TextDirection.ltr)..layout();
    tp.paint(c,Offset(x-tp.width/2,y));
  }
  @override bool shouldRepaint(_ViewDiagram o) => o.t!=t||o.isLateral!=isLateral;
}

// ════════════════════════════════════════════════════════════════════════════
// PANTALLA: Guía de parámetros — ISO Aprendizabilidad
// ════════════════════════════════════════════════════════════════════════════
class _ParamsGuideScreen extends StatefulWidget {
  final CameraViewModel vm;
  const _ParamsGuideScreen({required this.vm});
  @override State<_ParamsGuideScreen> createState() => _ParamsGuideScreenState();
}
class _ParamsGuideScreenState extends State<_ParamsGuideScreen> {
  int _tab = 0;

  static const _criteria = [
    ('🦵','Profundidad','Rodilla debe bajar a ≤90° (muslo paralelo al suelo)','Sin profundidad hay sobrecarga patelofemoral — riesgo de lesión de rodilla'),
    ('🦶','Tobillo','Dorsiflexión mínima 25°. Talones en el suelo','Talones levantados = restricción de tobillo que aumenta el riesgo lumbar'),
    ('🔵','Rodillas','Siguen la dirección del pie. Valgo <10°','Valgo >10° bajo carga aumenta el riesgo de lesión del LCA'),
    ('🧍','Tronco','Inclinación controlada. Espalda baja neutra','Inclinación >55° bajo carga — riesgo de lesión lumbar'),
    ('⚖️','Simetría','Asimetría bilateral <8%','Asimetría crónica causa desequilibrios musculares y lesiones por acumulación'),
    ('⏱️','Velocidad','Excéntrica 2–3 segundos de descenso','Descenso rápido reduce estímulo muscular y aumenta riesgo articular'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Guía de análisis'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _TabPill(label: 'Sentadilla perfecta', active: _tab==0, onTap: ()=>setState(()=>_tab=0)),
          const SizedBox(width: 8),
          _TabPill(label: 'Vista lateral (${widget.vm.lateralParams.length} params)', active: _tab==1, color: BM.primary, onTap: ()=>setState(()=>_tab=1)),
          const SizedBox(width: 8),
          _TabPill(label: 'Vista frontal (${widget.vm.frontalParams.length} params)', active: _tab==2, color: BM.accent, onTap: ()=>setState(()=>_tab=2)),
        ]))),
      Expanded(child: _tab == 0
        ? _CriteriaTab(criteria: _criteria)
        : _ParamsTab(
            params: _tab==1 ? widget.vm.lateralParams : widget.vm.frontalParams,
            color: _tab==1 ? BM.primary : BM.accent,
            viewName: _tab==1 ? 'Vista lateral' : 'Vista frontal')),
    ]),
  );
}

class _TabPill extends StatelessWidget {
  final String label; final bool active; final Color color; final VoidCallback onTap;
  const _TabPill({required this.label, required this.active, required this.onTap, this.color = BM.warning});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: 180.ms, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: active ? color.withOpacity(0.15) : BM.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : BM.elevated)),
      child: Text(label, style: TextStyle(color: active ? color : BM.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))));
}

class _CriteriaTab extends StatelessWidget {
  final List<(String,String,String,String)> criteria;
  const _CriteriaTab({required this.criteria});
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: criteria.length,
    itemBuilder: (_, i) {
      final c = criteria[i];
      return Container(margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: ExpansionTile(
          leading: Text(c.$1, style: const TextStyle(fontSize: 24)),
          title: Text(c.$2, style: const TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(c.$3, style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
          iconColor: BM.primary, collapsedIconColor: BM.textHint,
          children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: BM.error.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, color: BM.error, size: 13),
                const SizedBox(width: 8),
                Expanded(child: Text(c.$4, style: const TextStyle(color: BM.error, fontSize: 11, height: 1.4))),
              ])))],
        )).animate().fadeIn(delay: Duration(milliseconds: i * 55));
    });
}

class _ParamsTab extends StatelessWidget {
  final List<String> params; final Color color; final String viewName;
  const _ParamsTab({required this.params, required this.color, required this.viewName});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22))),
      child: Row(children: [
        Icon(Icons.analytics_rounded, color: color, size: 20), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$viewName — ${params.length} parámetros', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const Text('Parámetros que el sistema analiza con esta vista', style: TextStyle(color: BM.textSecondary, fontSize: 11)),
        ])),
      ])),
    ...params.asMap().entries.map((e) => Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 22, height: 22, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('${e.key+1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)))),
        const SizedBox(width: 12),
        Expanded(child: Text(e.value, style: const TextStyle(color: BM.textPrimary, fontSize: 13))),
      ])).animate().fadeIn(delay: Duration(milliseconds: e.key * 40))),
  ]);
}

// ════════════════════════════════════════════════════════════════════════════
// VISTA DE ANÁLISIS EN PROGRESO
// ════════════════════════════════════════════════════════════════════════════
class _AnalyzingView extends StatefulWidget {
  final AnalysisViewModel analysis;
  const _AnalyzingView({required this.analysis});
  @override State<_AnalyzingView> createState() => _AnalyzingViewState();
}
class _AnalyzingViewState extends State<_AnalyzingView> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  @override void initState() { super.initState(); _pulse = AnimationController(vsync: this, duration: 1000.ms)..repeat(reverse: true); }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isUp = widget.analysis.step == AnalysisStep.uploading;
    final steps = [
      ('Extrayendo frames del video',   Icons.video_file_rounded),
      ('Detectando pose con MediaPipe', Icons.accessibility_new_rounded),
      ('Calculando 40 parámetros',      Icons.analytics_rounded),
      ('Evaluando técnica y riesgo',    Icons.health_and_safety_rounded),
      ('Actualizando modelo IA',        Icons.psychology_rounded),
    ];
    return Scaffold(backgroundColor: BM.bg,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 92, height: 92,
            decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.35+_pulse.value*0.25),
                    blurRadius: 28+_pulse.value*12, offset: const Offset(0, 10))]),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 44))),
          const SizedBox(height: 24),
          Text(isUp ? 'Subiendo video...' : 'Analizando con IA',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: BM.textPrimary)),
          const SizedBox(height: 5),
          Text(widget.analysis.statusMessage, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
          const Text('Esto puede tomar entre 1 y 3 minutos', style: TextStyle(fontSize: 11, color: BM.textHint)),
          const SizedBox(height: 24),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
              value: isUp
                  ? widget.analysis.uploadPct
                  : widget.analysis.totalProgressPct >= 30
                      ? widget.analysis.totalProgressPct / 100.0
                      : null,
              backgroundColor: BM.elevated,
              valueColor: const AlwaysStoppedAnimation(BM.primary), minHeight: 6)),
          Padding(padding: const EdgeInsets.only(top: 5),
            child: Text(
              isUp
                  ? '${(widget.analysis.uploadPct * 100).toInt()}% subido'
                  : widget.analysis.totalProgressPct >= 30
                      ? '${widget.analysis.totalProgressPct}% completado'
                      : 'Iniciando análisis...',
              style: const TextStyle(color: BM.textHint, fontSize: 11))),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((e) {
            final done = !isUp && e.key < 3; final active = !isUp && e.key == 3;
            return AnimatedContainer(duration: 300.ms, margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: done?BM.accent.withOpacity(0.06):active?BM.primary.withOpacity(0.08):Colors.transparent,
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedSwitcher(duration: 200.ms, child: Icon(
                    done?Icons.check_circle_rounded:active?Icons.radio_button_checked:Icons.radio_button_unchecked,
                    key: ValueKey(done?'d':active?'a':'i'),
                    color: done?BM.accent:active?BM.primary:BM.textHint, size: 14)),
                const SizedBox(width: 7),
                Icon(e.value.$2, color: done?BM.accent:active?BM.primary:BM.textHint, size: 13),
                const SizedBox(width: 6),
                Text(e.value.$1, style: TextStyle(color: done?BM.accent:active?BM.primary:BM.textHint,
                    fontSize: 12, fontWeight: (done||active)?FontWeight.w600:FontWeight.w400)),
              ]));
          }),
          if (!isUp) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BM.accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BM.accent.withOpacity(0.25)),
              ),
              child: Row(children: const [
                Icon(Icons.notifications_active_rounded, color: BM.accent, size: 16),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Puedes salir de esta pantalla — te avisaremos cuando el análisis termine',
                  style: TextStyle(color: BM.accent, fontSize: 12),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.home_rounded, size: 16),
                label: const Text('Inicio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BM.textSecondary,
                  side: BorderSide(color: BM.textHint.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.go('/dashboard'),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BM.error,
                  side: BorderSide(color: BM.error.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.analysis.cancel();
                  context.go('/capture');
                },
              )),
            ]),
          ],
        ]))));
  }
}
