import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/utils/constants.dart';
import '../../core/models/models.dart';
import '../../core/providers/analysis_provider.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';


class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final result = context.watch<AnalysisProvider>().result;
    if (result == null) {
      return Scaffold(
        backgroundColor: BM.bg,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, color: BM.error, size: 48),
          const SizedBox(height: 16),
          const Text('Sin resultados disponibles', style: TextStyle(color: BM.textSecondary)),
          const SizedBox(height: 16),
          GBtn(text: 'Volver', height: 48, onTap: () => context.go('/dashboard')),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: Text(ExerciseInfo.fromId(result.exerciseType).label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () { context.read<AnalysisProvider>().reset(); context.go('/dashboard'); },
        ),
        actions: [
          if (result.annotatedDownloadUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: BM.accent),
              tooltip: 'Descargar video anotado',
              onPressed: () => _downloadVideo(result.annotatedDownloadUrl!),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: BM.primary,
          labelColor: BM.primary,
          unselectedLabelColor: BM.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: '40 Params'),
            Tab(text: 'Reps'),
            Tab(text: 'Modelo IA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(result: result),
          _ParamsTab(result: result),
          _RepsTab(result: result),
          _AITab(result: result),
        ],
      ),
    );
  }

  Future<void> _downloadVideo(String url) async {
    try {
      // Descargar el video a un archivo temporal
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/biomove_annotated.mp4';

      await dio.download(url, filePath);

      // Guardar en galería con gal
      await Gal.putVideo(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video guardado en tu galería'),
            backgroundColor: BM.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    }
  }
}

// ── SUMMARY TAB ───────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final AnalysisResult result;
  const _SummaryTab({required this.result});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Score gauge
      Center(child: ScoreGauge(score: result.techniqueScore, size: 160)
          .animate().scale(duration: 600.ms, curve: Curves.elasticOut)),
      const SizedBox(height: 8),
      Center(child: Text(DateFormat("d 'de' MMMM yyyy", 'es').format(result.sessionDate),
          style: const TextStyle(fontSize: 13, color: BM.textSecondary))),
      const SizedBox(height: 20),

      // Stats row
      Row(children: [
        Expanded(child: _StatChip('Reps', '${result.totalReps}', Icons.repeat_rounded, BM.primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatChip('Duración', '${result.durationSeconds?.toStringAsFixed(0) ?? '—'}s', Icons.timer_outlined, BM.accent)),
        const SizedBox(width: 10),
        if (result.weightKg != null)
          Expanded(child: _StatChip('Peso', '${result.weightKg!.toStringAsFixed(0)} kg', Icons.fitness_center_rounded, BM.warning))
        else
          Expanded(child: _StatChip('1RM est.', '${result.oneRmEpley?.toStringAsFixed(0) ?? '—'} kg', Icons.trending_up_rounded, BM.warning)),
      ]).animate().fadeIn(),
      const SizedBox(height: 8),
      Row(children: [
        if (result.fatigueDetected)
          Expanded(child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: BM.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BM.warning.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.battery_alert_rounded, color: BM.warning, size: 16),
                const SizedBox(width: 8),
                const Text('Fatiga técnica detectada', style: TextStyle(color: BM.warning, fontSize: 12, fontWeight: FontWeight.w600)),
              ]))),
      ]),

      // Video annotated download
      if (result.annotatedDownloadUrl != null) ...[
        const SizedBox(height: 16),
        GBtn(
          text: 'Descargar video anotado',
          icon: Icons.download_rounded,
          colors: const [BM.accentDk, Color(0xFF005C45)],
          height: 50,
          onTap: () async {
            final uri = Uri.parse(result.annotatedDownloadUrl!);
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ).animate().fadeIn(delay: 150.ms),
      ],
      const SizedBox(height: 24),

  // Classifier result
  if (result.classifierEnabled && result.repetitions.isNotEmpty) ...[
  if (result.repetitions.last.hasClassifier) ...[
  const SectionHeader(title: 'Clasificador IA'),
  const SizedBox(height: 12),
  ClassifierCard(
  clfClass: result.repetitions.last.clfClass!,
  confidence: result.repetitions.last.clfConfidence ?? 0,
  topFactors: result.repetitions.last.clfTopFactors,
  version: result.repetitions.last.clfVersion,
  ).animate().fadeIn(),
  const SizedBox(height: 20),
  ],
  ],

      // Report sections
      const SectionHeader(title: 'Informe biomecánico'),
      const SizedBox(height: 14),

      // Riesgo
      if (result.riskFeedback.isNotEmpty) ...[
        _SectionLabel('🔴 Riesgo de lesión', BM.error),
        const SizedBox(height: 8),
        ...result.riskFeedback.map((f) => _FeedbackCard(item: f)),
        const SizedBox(height: 16),
      ],

      // Mejora
      if (result.improveFeedback.isNotEmpty) ...[
        _SectionLabel('🟡 Puede mejorar', BM.warning),
        const SizedBox(height: 8),
        ...result.improveFeedback.map((f) => _FeedbackCard(item: f)),
        const SizedBox(height: 16),
      ],

      // Correcto
      if (result.riskFeedback.isEmpty && result.improveFeedback.isEmpty)
        GlassCard(child: const Column(children: [
          Icon(Icons.check_circle_rounded, color: BM.accent, size: 44),
          SizedBox(height: 12),
          Text('¡Técnica excelente!', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 6),
          Text('Sin errores detectados. Sigue así.', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
        ])).animate().fadeIn(),

      const SizedBox(height: 40),
    ].whereType<Widget>().toList()),
  );
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
  );
}

class _FeedbackCard extends StatefulWidget {
  final FeedbackItem item;
  const _FeedbackCard({required this.item});
  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.isInjuryRisk ? BM.error : BM.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.item.isInjuryRisk ? BM.error.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              SeverityBadge(severity: widget.item.severity),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.item.message,
                  style: const TextStyle(fontSize: 13, color: BM.textPrimary, fontWeight: FontWeight.w500))),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: BM.textHint, size: 20),
            ]),
          ),
        ),
        if (_expanded) Container(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              const Text('Corrección:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BM.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Text(widget.item.correction, style: const TextStyle(fontSize: 12, color: BM.textPrimary, height: 1.5)),
            if (widget.item.exerciseRecommendation != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.fitness_center_rounded, color: BM.primary, size: 14),
                const SizedBox(width: 6),
                const Text('Ejercicios correctivos:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BM.textSecondary)),
              ]),
              const SizedBox(height: 4),
              Text(widget.item.exerciseRecommendation!, style: const TextStyle(fontSize: 12, color: BM.textPrimary, height: 1.5)),
            ],
            const SizedBox(height: 6),
            Text('Presente en ${widget.item.frequency} de ${widget.item.priorityRank} reps',
                style: const TextStyle(fontSize: 11, color: BM.textHint)),
          ]),
        ),
      ]),
    );
  }
}

// ── PARAMS TAB ────────────────────────────────────────────────────────────────
class _ParamsTab extends StatelessWidget {
  final AnalysisResult result;
  const _ParamsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.repetitions.isEmpty) return const Center(
        child: Text('Sin repeticiones detectadas', style: TextStyle(color: BM.textSecondary)));

    // Calculate averages across reps
    double avg(double? Function(RepResult) fn) {
      final vals = result.repetitions.map(fn).whereType<double>().toList();
      return vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
            color: BM.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BM.primary.withOpacity(0.2))),
          child: Text('Promedios de ${result.totalReps} repeticiones',
              style: const TextStyle(color: BM.primary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),

        _ParamSection('🦵 Ángulos articulares', [
          _P('Rodilla mínima', avg((r) => r.kneeAngleMin), '°', good: (70, 100), risk: (115, 200)),
          _P('Cadera mínima', avg((r) => r.hipAngleMin), '°', good: (45, 75), risk: (90, 180)),
          _P('Tronco máximo', avg((r) => r.trunkLeanMax), '°', good: (0, 45), risk: (55, 90)),
          _P('Valgo rodilla izq', avg((r) => r.leftValgus), '°', good: (0, 5), risk: (10, 45), lowerBetter: true),
          _P('Valgo rodilla der', avg((r) => r.rightValgus), '°', good: (0, 5), risk: (10, 45), lowerBetter: true),
          _P('Dorsiflexión tobillo', avg((r) => r.ankleDF), '°', good: (25, 60), risk: (0, 15)),
        ]),

        _ParamSection('⏱️ Tiempo y velocidad', [
          _P('Duración excéntrica', avg((r) => r.eccentricDur), 's', good: (1.5, 3.5), risk: (0, 1.0)),
          _P('Duración concéntrica', avg((r) => r.concentricDur), 's', good: (1.0, 2.5), risk: (0, 0.5)),
          _P('Ratio exc/con', avg((r) => r.eccConRatio), 'x', good: (1.2, 2.5), risk: (0, 0.5)),
          _P('Velocidad de barra', avg((r) => r.barVelocityMs), 'm/s', good: (0.3, 0.8), risk: (0, 0.15)),
        ]),

        _ParamSection('⚖️ Simetría', [
          _P('Asimetría rodilla', avg((r) => r.kneeAsymmetryPct), '%', good: (0, 8), risk: (15, 100), lowerBetter: true),
          _P('Desplazamiento cadera', avg((r) => r.lateralHipShiftCm), 'cm', good: (0, 2), risk: (4, 20), lowerBetter: true),
          _P('Rotación pélvica', avg((r) => r.pelvicRotationDeg), '°', good: (0, 10), risk: (20, 60), lowerBetter: true),
        ]),

        _ParamSection('⚠️ Scores de riesgo', [
          _P('Riesgo LCA', avg((r) => r.aclRiskScore), '/100', good: (0, 25), risk: (50, 100), lowerBetter: true),
          _P('Carga patelofemoral', avg((r) => r.patellofemoralLoad), '/100', good: (0, 30), risk: (60, 100), lowerBetter: true),
          _P('Riesgo lumbar', avg((r) => r.lumbarRiskScore), '/100', good: (0, 25), risk: (50, 100), lowerBetter: true),
        ]),

        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _ParamSection(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
      const SizedBox(height: 10),
      GlassCard(padding: const EdgeInsets.all(14), child: Column(children: rows)),
      const SizedBox(height: 16),
    ],
  );

  Widget _P(String label, double value, String unit,
      {required (double, double) good, required (double, double) risk, bool lowerBetter = false}) {
    final inGood = value >= good.$1 && value <= good.$2;
    final inRisk = lowerBetter ? value >= risk.$1 : value >= risk.$1;
    final color  = inGood ? BM.accent : (inRisk ? BM.error : BM.warning);
    final section = inGood ? null : (inRisk ? 'riesgo' : 'mejora');
    return ParamRow(
      label: label,
      value: value.toStringAsFixed(1),
      unit: unit,
      section: section,
    );
  }
}

// ── REPS TAB ──────────────────────────────────────────────────────────────────
class _RepsTab extends StatelessWidget {
  final AnalysisResult result;
  const _RepsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.repetitions.isEmpty) return const Center(
        child: Text('Sin repeticiones detectadas', style: TextStyle(color: BM.textSecondary)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: result.repetitions.length,
      itemBuilder: (_, i) {
        final rep = result.repetitions[i];
        final color = BM.scoreColor(rep.repScore);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rep.hasInjuryRisk ? BM.error.withOpacity(0.3) : Colors.white.withOpacity(0.04))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${rep.repNumber}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Repetición ${rep.repNumber}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                Row(children: [
                  if (rep.depthAchieved) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Profundidad ✓', style: TextStyle(color: BM.accent, fontSize: 10, fontWeight: FontWeight.w600)))
                  else Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: BM.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Sin profundidad', style: TextStyle(color: BM.warning, fontSize: 10))),
                  if (rep.hasInjuryRisk) ...[
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: BM.error.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: const Text('⚠️ Riesgo', style: TextStyle(color: BM.error, fontSize: 10, fontWeight: FontWeight.w600))),
                  ],
                ]),
              ]),
              const Spacer(),
              Text('${rep.repScore.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            ]),

            // Key metrics for this rep
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (rep.kneeAngleMin != null) _Tag('Rodilla: ${rep.kneeAngleMin!.toStringAsFixed(0)}°'),
              if (rep.leftValgus != null && rep.leftValgus! > 5) _Tag('Valgo: ${rep.leftValgus!.toStringAsFixed(0)}°', isError: rep.leftValgus! > 10),
              if (rep.eccentricDur != null) _Tag('Exc: ${rep.eccentricDur!.toStringAsFixed(1)}s'),
              if (rep.barVelocityMs != null) _Tag('Vel: ${rep.barVelocityMs!.toStringAsFixed(2)} m/s'),
            ]),

            // Classifier result for this rep
            if (rep.hasClassifier) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: BM.clfColor(rep.clfClass!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Text('Modelo IA: ', style: TextStyle(fontSize: 12, color: BM.textSecondary)),
                    Text(rep.clfClass!.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: BM.clfColor(rep.clfClass!))),
                    const Spacer(),
                    Text('${((rep.clfConfidence ?? 0)*100).toStringAsFixed(0)}% conf.',
                        style: const TextStyle(fontSize: 11, color: BM.textHint)),
                  ])),
            ],
          ]),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }

  Widget _Tag(String text, {bool isError = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isError ? BM.error.withOpacity(0.1) : BM.elevated,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: isError ? BM.error : BM.textSecondary)),
  );
}

// ── AI TAB ────────────────────────────────────────────────────────────────────
class _AITab extends StatelessWidget {
  final AnalysisResult result;
  const _AITab({required this.result});

  @override
  Widget build(BuildContext context) {
    final ai = result.aiComparison;
    if (ai.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.psychology_outlined, color: BM.textHint, size: 48),
      const SizedBox(height: 12),
      const Text('Modelo IA personal', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Sube más sesiones para activar el modelo personal', textAlign: TextAlign.center,
          style: TextStyle(color: BM.textSecondary, fontSize: 13)),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GBtn(text: 'Ver modelo IA', height: 48, onTap: () => context.go('/ai_model'))),
    ]));

    final phase     = ai['phase'] as String? ?? '';
    final msg       = ai['phase_message'] as String? ?? '';
    final recs      = (ai['recommendations'] as List? ?? []).cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassCard(borderColor: BM.primary.withOpacity(0.3), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(_phaseEmoji(phase), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: BM.textPrimary, height: 1.4))),
            ]),
          ],
        )).animate().fadeIn(),
        const SizedBox(height: 16),

        if (recs.isNotEmpty) ...[
          const SectionHeader(title: 'Recomendaciones personales'),
          const SizedBox(height: 12),
          ...recs.asMap().entries.map((e) {
            final r = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['title']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                const SizedBox(height: 4),
                Text(r['message']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: BM.textSecondary, height: 1.4)),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60));
          }),
        ],

        const SizedBox(height: 20),
        GBtn(text: 'Ver modelo IA completo', icon: Icons.psychology_rounded,
            height: 50, onTap: () => context.go('/ai_model')),
        const SizedBox(height: 40),
      ]),
    );
  }

  String _phaseEmoji(String phase) {
    switch (phase) {
      case 'learning':   return '🧠';
      case 'active':     return '✅';
      case 'optimizing': return '🎯';
      default:           return '📊';
    }
  }
}
