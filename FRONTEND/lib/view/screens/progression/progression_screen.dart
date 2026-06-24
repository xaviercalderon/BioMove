// view/screens/progression/progression_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../viewmodel/progression_viewmodel.dart';
import '../../../viewmodel/analysis_viewmodel.dart';
import '../../../repository/analysis_repository.dart';
import '../../../model/progression_model.dart';
import '../../../model/analysis_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../view/widgets/common_widgets.dart';
import 'package:video_player/video_player.dart';

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});
  @override State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressionViewModel>().loadActivePlan();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Mi Progresión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showRPEGuide(context),
            tooltip: '¿Qué es @RPE?',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: BM.primary,
          labelColor: BM.primary,
          unselectedLabelColor: BM.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded, size: 16), text: 'Hoy'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 16), text: 'Plan'),
            Tab(icon: Icon(Icons.show_chart_rounded, size: 16), text: 'Historial'),
          ],
        ),
      ),
      body: Consumer<ProgressionViewModel>(
        builder: (ctx, vm, _) {
          if (vm.isLoading) return const Center(
              child: CircularProgressIndicator(color: BM.accent));
          if (vm.error != null) return _ErrorState(
              error: vm.error!, onRetry: () => vm.loadActivePlan());
          return TabBarView(controller: _tabs, children: [
            _TodayTab(vm: vm),
            _PlanTab(vm: vm),
            _HistoryTab(vm: vm),
          ]);
        },
      ),
      floatingActionButton: Consumer<ProgressionViewModel>(
        builder: (ctx, vm, _) => vm.hasPlan
            ? FloatingActionButton.extended(
                backgroundColor: BM.primary,
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Analizar sesión'),
                onPressed: () => context.go('/capture'),
              )
            : FloatingActionButton.extended(
                backgroundColor: BM.accent,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear plan'),
                onPressed: () => _showCreatePlan(context, vm),
              ),
      ),
    );
  }

  void _showRPEGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BM.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _RPEGuideSheet(),
    );
  }

  void _showCreatePlan(BuildContext context, ProgressionViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BM.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatePlanSheet(vm: vm),
    );
  }
}

// ── Tab Hoy ───────────────────────────────────────────────────────────────────
class _TodayTab extends StatefulWidget {
  final ProgressionViewModel vm;
  const _TodayTab({required this.vm});
  @override State<_TodayTab> createState() => _TodayTabState();
}
class _TodayTabState extends State<_TodayTab> {
  WorkoutSessionModel? _lastSession;
  bool _loadingSession = false;

  @override void initState() { super.initState(); _loadLastSession(); }

  Future<void> _loadLastSession() async {
    setState(() => _loadingSession = true);
    try {
      final sessions = await AnalysisRepository().getWorkouts(page: 1);
      if (sessions.isNotEmpty && mounted) {
        setState(() { _lastSession = sessions.first; _loadingSession = false; });
      } else {
        if (mounted) setState(() => _loadingSession = false);
      }
    } catch (_) { if (mounted) setState(() => _loadingSession = false); }
  }

  void _openVideo(BuildContext context, String url) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _VideoModal(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    if (!vm.hasPlan) return _NoPlanState();
    final today = vm.todaySession;
    if (today == null) return _NoPlanState();

    final block  = today.blockLabel;
    final blockColor = _blockColor(today.block);

    // Verificación de peso
    final targetWeight = today.weightKg;
    final sessionWeight = _lastSession?.weightKg;
    final bool? weightOk = sessionWeight != null
        ? (sessionWeight >= targetWeight * 0.9)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Tarjeta principal del día
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [blockColor.withOpacity(0.8), BM.primary.withOpacity(0.6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
                child: Text('Semana ${today.weekNumber} · $block',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600))),
              const Spacer(),
              if (widget.vm.coachApproved)
                const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
            ]),
            const SizedBox(height: 16),
            Text(today.prescription,
                style: const TextStyle(color: Colors.white,
                    fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${today.sets} series × ${today.reps} reps',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
            const SizedBox(height: 4),
            Text(today.note ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ]),
        ).animate().fadeIn().slideY(begin: -0.05),

        const SizedBox(height: 16),

        // ── Verificación de cumplimiento ─────────────────────────────
        if (!_loadingSession) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _lastSession == null
                  ? BM.card
                  : (weightOk == true ? BM.accent.withOpacity(0.08) : BM.error.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _lastSession == null
                  ? Colors.white.withOpacity(0.06)
                  : (weightOk == true ? BM.accent.withOpacity(0.3) : BM.error.withOpacity(0.3))),
            ),
            child: Row(children: [
              Icon(
                _lastSession == null ? Icons.upload_rounded
                    : (weightOk == true ? Icons.check_circle_rounded : Icons.warning_rounded),
                color: _lastSession == null ? BM.textHint
                    : (weightOk == true ? BM.accent : BM.error), size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _lastSession == null ? 'Sube el video de hoy para verificar'
                      : (weightOk == true
                          ? '¡Cumpliste con el entrenamiento!'
                          : 'Peso insuficiente — hoy debías usar ${targetWeight.toStringAsFixed(1)} kg'),
                  style: TextStyle(
                    color: _lastSession == null ? BM.textSecondary
                        : (weightOk == true ? BM.accent : BM.error),
                    fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (_lastSession != null && sessionWeight != null)
                  Text('Subiste con ${sessionWeight.toStringAsFixed(1)} kg · Plan: ${targetWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: BM.textSecondary, fontSize: 11)),
              ])),
              // Botón ver video
              if (_lastSession?.jobId != null)
                GestureDetector(
                  onTap: () {
                    final url = 'http://10.0.2.2:8000/exports/annotated/${_lastSession!.jobId}_annotated.mp4';
                    _openVideo(context, url);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: BM.grad1, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text('Ver video', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 16),
        ],

        // RPE Target con explicación
        GlassCard(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Intensidad objetivo',
                style: TextStyle(color: BM.textSecondary, fontSize: 13)),
            _RPEBadge(rpe: today.rpeTarget),
          ]),
          const SizedBox(height: 14),
          LinearPercentIndicator(
            lineHeight: 14,
            percent: (today.rpeTarget / 10.0).clamp(0.0, 1.0),
            center: Text('${today.rpeTarget}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700)),
            barRadius: const Radius.circular(7),
            backgroundColor: Colors.white10,
            linearGradient: LinearGradient(colors: [
              blockColor.withOpacity(0.6), blockColor]),
            animation: true, animationDuration: 800,
          ),
          const SizedBox(height: 10),
          Text(_rpeExplanation(today.rpeTarget),
              style: const TextStyle(color: BM.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
        ])).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Métricas del día
        Row(children: [
          Expanded(child: MetricCard(
            label: 'Peso', value: '${today.weightKg}kg',
            icon: Icons.fitness_center_rounded, color: BM.primary, animDelay: 0)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(
            label: '% del 1RM', value: '${today.pctOnerm}%',
            icon: Icons.percent_rounded, color: BM.accent, animDelay: 60)),
          const SizedBox(width: 10),
          Expanded(child: MetricCard(
            label: 'Vel. objetivo',
            value: '~${_targetVelocity(today.rpeTarget)}m/s',
            icon: Icons.speed_rounded, color: BM.warning, animDelay: 120)),
        ]),

        // Ajuste de coach si hay
        if (widget.vm.coachNotes != null && widget.vm.coachNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.sports_rounded, color: Color(0xFF00D4AA), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Nota de tu entrenador',
                    style: TextStyle(color: Color(0xFF00D4AA),
                        fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.vm.coachNotes!,
                    style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
              ])),
            ])),
        ],

        const SizedBox(height: 16),

        // Descripción del bloque
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: blockColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Bloque: $block',
                style: TextStyle(color: blockColor,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(today.blockDescription ?? '',
              style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
        ])).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 80),
      ]),
    );
  }

  String _targetVelocity(double rpe) {
    if (rpe >= 9.5) return '0.2';
    if (rpe >= 9)   return '0.3';
    if (rpe >= 8.5) return '0.4';
    if (rpe >= 8)   return '0.5';
    if (rpe >= 7.5) return '0.6';
    if (rpe >= 7)   return '0.7';
    return '0.9';
  }

  String _rpeExplanation(double rpe) {
    if (rpe >= 9.5) return 'Sin repeticiones en reserva — esfuerzo máximo';
    if (rpe >= 9)   return '1 repetición en reserva — muy difícil';
    if (rpe >= 8.5) return '1-2 repeticiones en reserva — difícil';
    if (rpe >= 8)   return '2 repeticiones en reserva — moderado-alto';
    if (rpe >= 7.5) return '2-3 repeticiones en reserva — moderado';
    if (rpe >= 7)   return '3 repeticiones en reserva — puedes hablar';
    return '4+ repeticiones en reserva — ligero';
  }

  Color _blockColor(String block) {
    switch (block) {
      case 'accumulation':    return const Color(0xFF6C63FF);
      case 'intensification': return const Color(0xFFFF8A65);
      case 'realization':     return const Color(0xFFFF5252);
      case 'deload':          return const Color(0xFF00D4AA);
      default:                return BM.primary;
    }
  }
}

// ── Tab Plan — Calendario 4 semanas ──────────────────────────────────────────
class _PlanTab extends StatelessWidget {
  final ProgressionViewModel vm;
  const _PlanTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (!vm.hasPlan) return _NoPlanState();
    final weeks = vm.allWeeks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Progreso general del plan
        GlassCard(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Progreso del ciclo',
                style: TextStyle(color: BM.textSecondary, fontSize: 13)),
            Text('Semana ${vm.currentWeek}/11',
                style: const TextStyle(color: BM.accent,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: (vm.currentWeek / 11.0).clamp(0.0, 1.0),
            barRadius: const Radius.circular(5),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
            padding: EdgeInsets.zero, animation: true),
        ])),
        const SizedBox(height: 20),

        // Semanas agrupadas por bloque
        ...vm.blocks.map((block) => _BlockSection(
          block: block,
          currentWeek: vm.currentWeek,
          onWeekTap: (w) => _showWeekDetail(context, w),
        )),

        const SizedBox(height: 80),
      ]),
    );
  }

  void _showWeekDetail(BuildContext context, WeekModel week) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BM.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WeekDetailSheet(week: week),
    );
  }
}

class _BlockSection extends StatelessWidget {
  final BlockModel block;
  final int currentWeek;
  final void Function(WeekModel) onWeekTap;
  const _BlockSection({required this.block, required this.currentWeek,
      required this.onWeekTap});

  @override
  Widget build(BuildContext context) {
    final color = _blockColor(block.key);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(block.label, style: TextStyle(color: color,
              fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(child: Text(block.description,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: BM.textHint, fontSize: 11))),
        ]),
      ),
      ...block.weeks.map((w) => _WeekTile(
        week: w, isCurrent: w.weekNumber == currentWeek,
        color: color, onTap: () => onWeekTap(w))),
      const SizedBox(height: 16),
    ]);
  }

  Color _blockColor(String b) {
    switch (b) {
      case 'accumulation':    return const Color(0xFF6C63FF);
      case 'intensification': return const Color(0xFFFF8A65);
      case 'realization':     return const Color(0xFFFF5252);
      case 'deload':          return const Color(0xFF00D4AA);
      default:                return BM.primary;
    }
  }
}

class _WeekTile extends StatelessWidget {
  final WeekModel week;
  final bool isCurrent;
  final Color color;
  final VoidCallback onTap;
  const _WeekTile({required this.week, required this.isCurrent,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? color.withOpacity(0.12) : BM.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? color : Colors.white.withOpacity(0.06),
            width: isCurrent ? 1.5 : 1)),
        child: Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: isCurrent ? color : Colors.white10,
              shape: BoxShape.circle),
            child: Center(child: Text('${week.weekNumber}',
                style: TextStyle(color: isCurrent ? Colors.white : BM.textHint,
                    fontSize: 12, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(week.prescription,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isCurrent ? color : BM.textPrimary,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            if (week.note?.isNotEmpty ?? false)
              Text(week.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: BM.textHint, fontSize: 10)),
          ])),
          const SizedBox(width: 6),
          _RPEBadge(rpe: week.rpeTarget, small: true),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, color: BM.textHint, size: 18),
        ])),
    );
  }
}

// ── Tab Historial ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final ProgressionViewModel vm;
  const _HistoryTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final history = vm.history;
    if (history.isEmpty) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.show_chart_rounded, color: BM.textHint, size: 48),
        SizedBox(height: 16),
        Text('Sin historial aún',
            style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('Sube videos y analiza tus sesiones',
            style: TextStyle(color: BM.textSecondary, fontSize: 13)),
      ]));

    final best = vm.personalBest ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Récord personal
        GlassCard(child: Row(children: [
          Container(width: 48, height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Récord personal', style: TextStyle(
                color: BM.textSecondary, fontSize: 12)),
            Text('${best.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Color(0xFFFFD700),
                    fontSize: 26, fontWeight: FontWeight.w800)),
          ])),
          if (vm.improvementPct != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: vm.improvementPct > 0
                    ? BM.accent.withOpacity(0.15) : BM.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${vm.improvementPct > 0 ? '+' : ''}${vm.improvementPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: vm.improvementPct > 0 ? BM.accent : BM.error,
                  fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ])).animate().fadeIn(),
        const SizedBox(height: 20),

        // Gráfico de progresión
        const SectionHeader(title: '📈 Evolución del 1RM estimado'),
        const SizedBox(height: 12),
        GlassCard(padding: const EdgeInsets.all(16),
          child: SizedBox(height: 180, child: LineChart(LineChartData(
            gridData: FlGridData(show: true,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.white10, strokeWidth: 1),
              getDrawingVerticalLine: (_) =>
                  FlLine(color: Colors.white10, strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v,_) => Text('${v.toInt()}kg',
                      style: const TextStyle(color: BM.textHint, fontSize: 9)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  reservedSize: 20,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                    return Text('S${idx+1}',
                        style: const TextStyle(color: BM.textHint, fontSize: 9));
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
              spots: history.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), e.value.oneRmAverage)).toList(),
              isCurved: true,
              color: BM.accent, barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, pct, bar, idx) =>
                    FlDotCirclePainter(radius: 3, color: BM.accent,
                        strokeWidth: 0, strokeColor: Colors.transparent)),
              belowBarData: BarAreaData(show: true,
                  color: BM.accent.withOpacity(0.08)),
            )],
          )))).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 20),

        // Lista de sesiones
        const SectionHeader(title: 'Sesiones registradas'),
        const SizedBox(height: 12),
        ...history.reversed.take(10).map((r) => _HistoryTile(record: r)),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final StrengthRecordModel record;
  const _HistoryTile({required this.record});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06))),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${record.weightKg}kg × ${record.reps} reps',
            style: const TextStyle(color: BM.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 13)),
        Text(record.formattedDate,
            style: const TextStyle(color: BM.textHint, fontSize: 11)),
      ]),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('1RM ~${record.oneRmAverage.toStringAsFixed(1)}kg',
            style: const TextStyle(color: BM.accent,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ]),
  );
}

// ── RPE Badge ─────────────────────────────────────────────────────────────────
class _RPEBadge extends StatelessWidget {
  final double rpe;
  final bool small;
  const _RPEBadge({required this.rpe, this.small = false});
  @override
  Widget build(BuildContext context) {
    final color = rpe >= 9 ? BM.error : rpe >= 8 ? BM.warning : BM.accent;
    return GestureDetector(
      onTap: () => showDialog(context: context,
          builder: (_) => _RPEDialog(rpe: rpe)),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 8 : 12, vertical: small ? 3 : 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4))),
        child: Text('@${rpe}',
            style: TextStyle(color: color,
                fontSize: small ? 11 : 13,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ── RPE Dialog / Guide ────────────────────────────────────────────────────────
class _RPEDialog extends StatelessWidget {
  final double rpe;
  const _RPEDialog({required this.rpe});
  @override
  Widget build(BuildContext context) {
    final label = rpe >= 10 ? 'Máximo absoluto — no puedes hacer ni 1 rep más'
        : rpe >= 9.5 ? 'Sin reserva — si hicieras otra rep fallarías'
        : rpe >= 9   ? '1 repetición en reserva'
        : rpe >= 8.5 ? '1-2 repeticiones en reserva'
        : rpe >= 8   ? '2 repeticiones en reserva'
        : rpe >= 7.5 ? '2-3 repeticiones en reserva'
        : rpe >= 7   ? '3 repeticiones en reserva'
        : '4+ repeticiones en reserva — bastante fácil';
    final color = rpe >= 9 ? BM.error : rpe >= 8 ? BM.warning : BM.accent;
    return Dialog(backgroundColor: BM.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('@${rpe}', style: TextStyle(color: color,
              fontSize: 48, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: BM.textPrimary,
              fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text(
            'RPE (Rate of Perceived Exertion) es una escala del 1 al 10 '
            'que mide qué tan difícil se sintió el ejercicio basándose en '
            'cuántas repeticiones más podrías haber hecho.',
            style: TextStyle(color: BM.textSecondary, fontSize: 12),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GBtn(text: 'Entendido', height: 46,
              onTap: () => Navigator.pop(context)),
        ])));
  }
}

class _RPEGuideSheet extends StatelessWidget {
  const _RPEGuideSheet();
  @override
  Widget build(BuildContext context) {
    const rpeData = [
      (10.0, 'Máximo', 'No puedes más — fallo muscular', BM.error),
      (9.5,  '@9.5',  'Sin reserva — última rep muy dura', BM.error),
      (9.0,  '@9',    '1 rep en reserva', Color(0xFFFF8A65)),
      (8.5,  '@8.5',  '1-2 reps en reserva', BM.warning),
      (8.0,  '@8',    '2 reps en reserva — moderado-alto', BM.warning),
      (7.5,  '@7.5',  '2-3 reps en reserva — moderado', Color(0xFFFFD700)),
      (7.0,  '@7',    '3 reps en reserva — puedes hablar', BM.accent),
      (6.0,  '@6',    '4+ reps en reserva — ligero', BM.accent),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.only(bottom: 16),
          child: Text('Escala @RPE', style: TextStyle(
              color: BM.textPrimary, fontWeight: FontWeight.w700, fontSize: 18))),
        Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16),
          children: rpeData.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: d.$4.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: d.$4.withOpacity(0.2))),
            child: Row(children: [
              Text(d.$2, style: TextStyle(color: d.$4,
                  fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 12),
              Expanded(child: Text(d.$3,
                  style: const TextStyle(color: BM.textSecondary, fontSize: 12))),
            ]))).toList())),
      ]),
    );
  }
}

// ── Sheets auxiliares ─────────────────────────────────────────────────────────
class _WeekDetailSheet extends StatelessWidget {
  final WeekModel week;
  const _WeekDetailSheet({required this.week});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Semana ${week.weekNumber} — ${week.blockLabel}',
          style: const TextStyle(color: BM.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 16),
      _DetailRow('Prescripción', week.prescription),
      _DetailRow('Peso', '${week.weightKg} kg'),
      _DetailRow('Series × Reps', '${week.sets}×${week.reps}'),
      _DetailRow('RPE objetivo', '@${week.rpeTarget}'),
      _DetailRow('% del 1RM', '${week.pctOnerm}%'),
      if (week.note?.isNotEmpty ?? false)
        _DetailRow('Nota', week.note!),
      const SizedBox(height: 20),
      GBtn(text: 'Cerrar', height: 46,
          onTap: () => Navigator.pop(context)),
    ]));
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(color: BM.textPrimary,
          fontWeight: FontWeight.w600, fontSize: 13)),
    ]));
}

class _CreatePlanSheet extends StatefulWidget {
  final ProgressionViewModel vm;
  const _CreatePlanSheet({required this.vm});
  @override State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  final _ctrl = TextEditingController();
  String _exercise = 'squat';

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24),
    child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Crear plan de progresión',
          style: TextStyle(color: BM.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Ingresa tu 1RM actual o lo calculamos del historial',
          style: TextStyle(color: BM.textSecondary, fontSize: 12)),
      const SizedBox(height: 20),
      // Solo sentadilla — análisis de 40 parámetros validado
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: BM.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BM.primary.withOpacity(0.3))),
        child: const Row(children: [
          Text('🏋️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text('Sentadilla', style: TextStyle(color: BM.primary,
              fontWeight: FontWeight.w700, fontSize: 14)),
          Spacer(),
          Icon(Icons.check_circle_rounded, color: BM.primary, size: 18),
        ]),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: '1RM actual (kg) — opcional',
          hintText: 'Dejar vacío para usar el historial',
          suffixText: 'kg'),
      ),
      const SizedBox(height: 20),
      GBtn(text: 'Generar plan', height: 50, loading: widget.vm.isLoading,
        onTap: () async {
          const exercise = 'squat';
          final oneRm = _ctrl.text.isNotEmpty ? double.tryParse(_ctrl.text) : null;
          await widget.vm.createPlan(exercise: exercise, oneRm: oneRm);
          if (mounted) Navigator.pop(context);
        }),
      const SizedBox(height: 20),
    ]));
}

// ── Modal de video ──────────────────────────────────────────────────────────
class _VideoModal extends StatefulWidget {
  final String url;
  const _VideoModal({required this.url});
  @override State<_VideoModal> createState() => _VideoModalState();
}
class _VideoModalState extends State<_VideoModal> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() { _ready = true; _ctrl.play(); });
      }).catchError((_) { if (mounted) setState(() => _ready = true); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.75;
    return Container(
      height: h,
      decoration: const BoxDecoration(color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Expanded(child: _ready && _ctrl.value.isInitialized
          ? GestureDetector(
              onTap: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
              child: AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)))
          : const Center(child: CircularProgressIndicator(color: BM.accent))),
        if (_ready && _ctrl.value.isInitialized) ...[
          VideoProgressIndicator(_ctrl, allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: BM.accent, backgroundColor: Colors.white12)),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconButton(
              icon: Icon(_ctrl.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36),
              onPressed: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()))),
        ],
      ]),
    );
  }
}

// ── Estado sin plan ───────────────────────────────────────────────────────────
class _NoPlanState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.calendar_today_rounded, color: BM.textHint, size: 60)
            .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text('Sin plan activo',
            style: TextStyle(color: BM.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        const Text(
          'Toca el botón "Crear plan" para generar tu plan de progresión '
          'personalizado de 11 semanas con pesos y @RPE calculados para ti.',
          style: TextStyle(color: BM.textSecondary, fontSize: 13),
          textAlign: TextAlign.center),
      ])));
}

class _ErrorState extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: BM.error, size: 48),
      const SizedBox(height: 16),
      Text(error, style: const TextStyle(color: BM.textSecondary, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GBtn(text: 'Reintentar', height: 46, onTap: onRetry),
    ]));
}
