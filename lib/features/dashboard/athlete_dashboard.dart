import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/utils/constants.dart';
import '../../core/models/models.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';

class AthleteDashboard extends StatefulWidget {
  const AthleteDashboard({super.key});
  @override
  State<AthleteDashboard> createState() => _AthleteDashboardState();
}

class _AthleteDashboardState extends State<AthleteDashboard> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late AnimationController _pulseCtrl;
  List<WorkoutSummary> _workouts = [];
  AIModelState? _aiModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: 2000.ms)..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getWorkouts(page: 1),
        _api.getAIModel(),
      ]);
      if (mounted) setState(() {
        _workouts = results[0] as List<WorkoutSummary>;
        _aiModel  = results[1] as AIModelState;
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName.split(' ').first;

    return Scaffold(
      backgroundColor: BM.bg,
      body: RefreshIndicator(
        color: BM.primary, backgroundColor: BM.surface,
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // App bar
          SliverAppBar(
            floating: true, backgroundColor: BM.bg,
            title: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [BM.primary, BM.accent, BM.primaryLt],
                  stops: [0, _pulseCtrl.value, 1],
                ).createShader(b),
                child: const Text('BioMove', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.psychology_rounded, color: BM.textSecondary),
                onPressed: () => context.go('/ai_model'),
              ),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 17, backgroundColor: BM.primary.withOpacity(0.2),
                    child: Text(auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: BM.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Greeting
              Text('Hola, $name 💪', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: BM.textPrimary))
                  .animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
              Text(DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now()),
                  style: const TextStyle(fontSize: 13, color: BM.textSecondary))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),

              // Main CTA
              _MainCTA().animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              const SizedBox(height: 12),

              // Live shortcut
              GestureDetector(
                onTap: () => context.go('/live'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BM.error.withOpacity(0.25))),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                        decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.radio_button_checked, color: BM.error, size: 22)
                            .animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.4, end: 1.0, duration: 800.ms)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Análisis en vivo', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Ángulos en pantalla mientras entrenas', style: TextStyle(color: BM.textSecondary, fontSize: 12)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 14),
                  ]),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),

              // AI Model status
              if (_aiModel != null) ...[
                const SectionHeader(title: 'Modelo IA personal'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/ai_model'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: BM.primary.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(_aiModel!.phaseEmoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_aiModel!.phaseMessage,
                            style: const TextStyle(fontSize: 13, color: BM.textPrimary, height: 1.4))),
                        if (_aiModel!.classifierReady)
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text('IA v${_aiModel!.classifierVersion}',
                                  style: const TextStyle(color: BM.accent, fontSize: 10, fontWeight: FontWeight.w700))),
                        const Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 13),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: _aiModel!.progress, minHeight: 6,
                                backgroundColor: BM.elevated, valueColor: const AlwaysStoppedAnimation(BM.primary)))),
                        const SizedBox(width: 10),
                        Text('${_aiModel!.totalReps} reps', style: const TextStyle(fontSize: 11, color: BM.textHint)),
                      ]),
                    ]),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 24),
              ],

              // Stats
              const SectionHeader(title: 'Tu progreso'),
              const SizedBox(height: 14),
              _loading
                  ? GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
                      children: List.generate(4, (_) => BioShimmer(width: double.infinity, height: 90, radius: 16)))
                  : _StatsGrid(workouts: _workouts),
              const SizedBox(height: 24),

              // Recent workouts
              SectionHeader(title: 'Últimas sesiones', action: 'Ver todo', onAction: () => context.go('/history')),
              const SizedBox(height: 14),
              if (_loading)
                Column(children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BioShimmer(width: double.infinity, height: 72, radius: 16))))
              else if (_workouts.isEmpty)
                _EmptyCard()
              else
                ..._workouts.take(5).toList().asMap().entries.map((e) =>
                    _WorkoutTile(w: e.value).animate().fadeIn(delay: Duration(milliseconds: e.key * 60))),
            ])),
          ),
        ]),
      ),
      bottomNavigationBar: BioBottomNav(current: 0, onTap: (i) {
        switch (i) {
          case 2: context.go('/history'); break;
          case 3: context.go('/calculator'); break;
          case 4: context.go('/profile'); break;
        }
      }),
      floatingActionButton: _AnalyzeFAB(pulse: _pulseCtrl),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _MainCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go('/capture'),
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: BM.gradHero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.4), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('NUEVO ANÁLISIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
          const SizedBox(height: 10),
          const Text('Analiza tu\ntécnica ahora', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 6),
          const Text('40 parámetros biomecánicos\ncon modelo IA personal', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ])),
        const SizedBox(width: 16),
        Container(width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 34))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 1500.ms),
      ]),
    ),
  );
}

class _StatsGrid extends StatelessWidget {
  final List<WorkoutSummary> workouts;
  const _StatsGrid({required this.workouts});
  @override
  Widget build(BuildContext context) {
    final avgScore = workouts.isEmpty ? 0.0
        : workouts.map((w) => w.techniqueScore).reduce((a, b) => a + b) / workouts.length;
    final reps = workouts.fold(0, (s, w) => s + w.totalReps);
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
      children: [
        MetricCard(label: 'Sesiones', value: '${workouts.length}', icon: Icons.calendar_today_rounded, color: BM.primary, animDelay: 0),
        MetricCard(label: 'Score promedio', value: avgScore.toStringAsFixed(0), unit: '/100', icon: Icons.analytics_rounded, color: BM.accent, animDelay: 60),
        MetricCard(label: 'Reps totales', value: '$reps', icon: Icons.repeat_rounded, color: BM.warning, animDelay: 120),
        MetricCard(label: 'Con fatiga', value: '${workouts.where((w) => w.fatigueDetected).length}', icon: Icons.battery_alert_rounded, color: BM.error, animDelay: 180),
      ],
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutSummary w;
  const _WorkoutTile({required this.w});
  @override
  Widget build(BuildContext context) {
    final ex = ExerciseInfo.fromId(w.exerciseType);
    final c  = BM.scoreColor(w.techniqueScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(ex.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
            if (w.classifierEnabled) ...[const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text('IA', style: TextStyle(fontSize: 9, color: BM.accent, fontWeight: FontWeight.w700)))],
            if (w.fatigueDetected) const Text('  ⚠️', style: TextStyle(fontSize: 11)),
          ]),
          Text('${w.totalSets}×${w.totalReps} reps${w.weightKg != null ? ' · ${w.weightKg!.toStringAsFixed(0)} kg' : ''}',
              style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${w.techniqueScore.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          Text(DateFormat('d MMM').format(w.sessionDate),
              style: const TextStyle(fontSize: 10, color: BM.textHint)),
        ]),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GlassCard(child: Column(children: [
    const Icon(Icons.fitness_center_rounded, color: BM.textHint, size: 44),
    const SizedBox(height: 12),
    const Text('Sin sesiones aún', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
    const SizedBox(height: 6),
    const Text('Sube tu primer video para comenzar', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
    const SizedBox(height: 16),
    GBtn(text: 'Analizar ejercicio', height: 44, onTap: () => context.go('/capture')),
  ]));
}

class _AnalyzeFAB extends StatelessWidget {
  final AnimationController pulse;
  const _AnalyzeFAB({required this.pulse});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, child) => Transform.translate(offset: Offset(0, -2 * pulse.value), child: child),
    child: GestureDetector(
      onTap: () => context.go('/capture'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 6))]),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Analizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      ),
    ),
  );
}
