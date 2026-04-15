import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/utils/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/analysis_provider.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker    = ImagePicker();
  final _weightCtrl = TextEditingController();
  String? _filePath;
  String _exercise = 'squat';
  String _view     = 'lateral';

  @override
  void dispose() { _weightCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(builder: (ctx, analysis, _) {
      // Redirect when completed
      if (analysis.step == AnalysisStep.completed && analysis.result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/results'));
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Error
            if (analysis.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BM.error.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: BM.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(analysis.error!, style: const TextStyle(color: BM.error, fontSize: 13))),
                  GestureDetector(onTap: analysis.reset, child: const Icon(Icons.close, color: BM.error, size: 16)),
                ]),
              ).animate().fadeIn().slideY(begin: -0.1),

            // Video selector
            GestureDetector(
              onTap: _pickFromGallery,
              child: AnimatedContainer(
                duration: 200.ms, height: 170, width: double.infinity,
                decoration: BoxDecoration(
                  color: BM.card, borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _filePath != null ? BM.accent : Colors.white.withOpacity(0.07),
                      width: _filePath != null ? 2 : 1),
                ),
                child: _filePath != null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 52, height: 52,
                            decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.check_circle_rounded, color: BM.accent, size: 26)),
                        const SizedBox(height: 10),
                        const Text('Video listo', style: TextStyle(color: BM.accent, fontWeight: FontWeight.w600, fontSize: 16)),
                        const Text('Toca para cambiar', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 52, height: 52,
                            decoration: BoxDecoration(color: BM.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.cloud_upload_outlined, color: BM.primary, size: 26)),
                        const SizedBox(height: 10),
                        const Text('Seleccionar video', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                        const Text('MP4 · MOV · máx 500 MB', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
                      ]),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _recordCamera,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06))),
                child: const Row(children: [
                  Icon(Icons.videocam_rounded, color: BM.error, size: 22),
                  SizedBox(width: 12),
                  Text('Grabar con la cámara ahora', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 14),
                ]),
              ),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 24),

            // Exercise selection
            const SectionHeader(title: 'Ejercicio'),
            const SizedBox(height: 12),
            ...ExerciseInfo.all.asMap().entries.map((e) {
              final ex = e.value; final sel = _exercise == ex.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _exercise = ex.id;
                  _view = ex.id == 'bench_press' ? 'frontal' : 'lateral';
                }),
                child: AnimatedContainer(
                  duration: 180.ms, margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? BM.primary.withOpacity(0.1) : BM.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? BM.primary : Colors.white.withOpacity(0.05), width: sel ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Text(ex.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ex.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: sel ? BM.primary : BM.textPrimary)),
                      Text(ex.description, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
                    ])),
                    if (sel) const Icon(Icons.check_circle_rounded, color: BM.primary, size: 20)
                    else const Icon(Icons.radio_button_unchecked, color: BM.textHint, size: 20),
                  ]),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 + e.key * 60));
            }),
            const SizedBox(height: 20),

            // Video view
            const SectionHeader(title: 'Vista del video'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ViewTile('lateral', 'Vista lateral', Icons.person_outline_rounded,
                  '~28 parámetros', sel: _view == 'lateral', onTap: () => setState(() => _view = 'lateral'))),
              const SizedBox(width: 10),
              Expanded(child: _ViewTile('frontal', 'Vista frontal', Icons.face_rounded,
                  '~18 parámetros', sel: _view == 'frontal', onTap: () => setState(() => _view = 'frontal'))),
            ]).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 20),

            // Weight
            const SectionHeader(title: 'Peso utilizado (opcional)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: BM.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'Peso en kg', prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20), suffixText: 'kg'),
            ).animate().fadeIn(delay: 320.ms),
            const SizedBox(height: 28),

            GBtn(
              text: _filePath != null ? 'Analizar movimiento' : 'Selecciona un video primero',
              icon: Icons.analytics_rounded,
              onTap: _filePath != null ? () => _analyze(analysis) : null,
            ).animate().fadeIn(delay: 380.ms),
            const SizedBox(height: 40),
          ]),
        ),
      );
    });
  }

  Widget _ViewTile(String value, String label, IconData icon, String desc,
      {required bool sel, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 180.ms, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sel ? BM.primary.withOpacity(0.1) : BM.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sel ? BM.primary : Colors.transparent, width: 1.5),
      ),
      child: Column(children: [
        Icon(icon, color: sel ? BM.primary : BM.textSecondary, size: 22),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: sel ? BM.primary : BM.textSecondary)),
        const SizedBox(height: 2),
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: BM.textHint)),
      ]),
    ),
  );

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (f != null && mounted) setState(() => _filePath = f.path);
  }

  Future<void> _recordCamera() async {
    final f = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 3));
    if (f != null && mounted) setState(() => _filePath = f.path);
  }

  Future<void> _analyze(AnalysisProvider analysis) async {
    await analysis.analyze(
      filePath: _filePath!, exerciseType: _exercise,
      videoView: _view, weightKg: double.tryParse(_weightCtrl.text) ?? 0.0,
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  final AnalysisProvider analysis;
  const _AnalyzingView({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final isUploading = analysis.step == AnalysisStep.uploading;
    final steps = ['Extrayendo frames del video','Detectando pose con MediaPipe',
                   'Calculando 40 parámetros','Evaluando técnica y riesgo','Actualizando modelo IA'];
    return Scaffold(
      backgroundColor: BM.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100,
                decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))]),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 48))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms),
            const SizedBox(height: 28),
            Text(isUploading ? 'Subiendo video...' : 'Analizando con IA',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BM.textPrimary)),
            const SizedBox(height: 8),
            Text(analysis.statusMessage, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: BM.textSecondary)),
            const SizedBox(height: 28),
            ClipRRect(borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: isUploading ? analysis.uploadPct : null,
                    backgroundColor: BM.elevated,
                    valueColor: const AlwaysStoppedAnimation(BM.primary), minHeight: 6)),
            const SizedBox(height: 28),
            ...steps.asMap().entries.map((e) {
              final done = !isUploading && e.key < 3;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: done ? BM.accent : BM.textHint, size: 15),
                  const SizedBox(width: 8),
                  Text(e.value, style: TextStyle(color: done ? BM.accent : BM.textHint, fontSize: 12)),
                ]),
              );
            }),
          ]),
        ),
      ),
    );
  }
}
