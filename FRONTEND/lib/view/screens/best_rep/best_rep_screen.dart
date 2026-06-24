// view/screens/best_rep/best_rep_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../viewmodel/best_rep_viewmodel.dart';
import '../../../model/best_rep_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../view/widgets/common_widgets.dart';

class BestRepsScreen extends StatefulWidget {
  const BestRepsScreen({super.key});
  @override State<BestRepsScreen> createState() => _BestRepsScreenState();
}

class _BestRepsScreenState extends State<BestRepsScreen> {
  String _exercise = 'squat';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BestRepViewModel>().load(_exercise);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Mejor vs Peor Rep'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            color: BM.card,
            onSelected: (v) {
              setState(() => _exercise = v);
              context.read<BestRepViewModel>().load(v);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'squat',       child: Text('Sentadilla')),
              const PopupMenuItem(value: 'deadlift',    child: Text('Peso muerto')),
              const PopupMenuItem(value: 'bench_press', child: Text('Press banca')),
            ],
          ),
        ],
      ),
      body: Consumer<BestRepViewModel>(
        builder: (ctx, vm, _) {
          if (vm.isLoading) return const Center(
              child: CircularProgressIndicator(color: BM.accent));
          if (vm.error != null) return _ErrorState(vm);
          if (vm.best == null && vm.worst == null) return _EmptyState();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Tarjeta de récord personal
              if (vm.best != null) _RecordCard(rep: vm.best!, type: 'best'),
              const SizedBox(height: 16),
              if (vm.worst != null) _RecordCard(rep: vm.worst!, type: 'worst'),
              const SizedBox(height: 24),

              // Comparación lado a lado
              if (vm.best != null && vm.worst != null) ...[
                const SectionHeader(title: '⚖️ Comparación lado a lado'),
                const SizedBox(height: 12),
                _SideBySideComparison(best: vm.best!, worst: vm.worst!),
                const SizedBox(height: 24),

                // Diferencias clave
                const SectionHeader(title: '📊 Diferencias clave'),
                const SizedBox(height: 12),
                _DiffTable(best: vm.best!, worst: vm.worst!),
              ],
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }
}

// ── Tarjeta de récord ─────────────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final BestRepModel rep;
  final String type;
  const _RecordCard({required this.rep, required this.type});

  @override
  Widget build(BuildContext context) {
    final isBest = type == 'best';
    final color  = isBest ? const Color(0xFFFFD700) : BM.error;
    final label  = isBest ? '🏆 Mejor repetición histórica' : '📉 Peor repetición histórica';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(color: color,
              fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
            child: Text('${rep.repScore.toStringAsFixed(0)}/100',
                style: TextStyle(color: color,
                    fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 12),
        LinearPercentIndicator(
          lineHeight: 10,
          percent: (rep.repScore / 100).clamp(0.0, 1.0),
          barRadius: const Radius.circular(5),
          backgroundColor: Colors.white10,
          linearGradient: LinearGradient(
              colors: [color.withOpacity(0.5), color]),
          padding: EdgeInsets.zero, animation: true),
        const SizedBox(height: 12),
        Row(children: [
          _RepStat('Rodilla', '${rep.kneeAngle?.toStringAsFixed(0) ?? '—'}°'),
          _RepStat('Valgo', '${rep.valgus?.toStringAsFixed(0) ?? '—'}°'),
          _RepStat('Exc.', '${rep.eccentricDur?.toStringAsFixed(1) ?? '—'}s'),
          _RepStat('Peso', '${rep.weightKg?.toStringAsFixed(0) ?? '—'}kg'),
        ]),
        const SizedBox(height: 10),
        Text(rep.recordedAt ?? '', style: const TextStyle(
            color: BM.textHint, fontSize: 11)),

        // Video del clip si está disponible
        if (rep.clipUrl != null) ...[
          const SizedBox(height: 12),
          _ClipPlayer(url: rep.clipUrl!, color: color),
        ],
      ]),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}

class _RepStat extends StatelessWidget {
  final String label, value;
  const _RepStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(color: BM.textPrimary,
          fontWeight: FontWeight.w700, fontSize: 14)),
      Text(label, style: const TextStyle(color: BM.textHint, fontSize: 10)),
    ]));
}

// ── Reproductor de clip ───────────────────────────────────────────────────────
class _ClipPlayer extends StatefulWidget {
  final String url; final Color color;
  const _ClipPlayer({required this.url, required this.color});
  @override State<_ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<_ClipPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl!.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return Container(height: 120,
      decoration: BoxDecoration(color: BM.card,
          borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator(
          color: BM.accent, strokeWidth: 2)));

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withOpacity(0.3))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        AspectRatio(aspectRatio: _ctrl!.value.aspectRatio,
            child: VideoPlayer(_ctrl!)),
        Container(color: BM.card,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(iconSize: 20,
              icon: Icon(_ctrl!.value.isPlaying
                  ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: widget.color),
              onPressed: () => setState(() =>
                  _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play())),
            Expanded(child: VideoProgressIndicator(_ctrl!, allowScrubbing: true,
              colors: VideoProgressColors(playedColor: widget.color,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10))),
          ])),
      ]));
  }
}

// ── Comparación lado a lado ───────────────────────────────────────────────────
class _SideBySideComparison extends StatelessWidget {
  final BestRepModel best, worst;
  const _SideBySideComparison({required this.best, required this.worst});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('🏆 MEJOR',
              style: TextStyle(color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800, fontSize: 12)))),
        const SizedBox(height: 8),
        if (best.clipUrl != null)
          _ClipPlayer(url: best.clipUrl!, color: const Color(0xFFFFD700))
        else
          _NoClip(color: const Color(0xFFFFD700)),
      ])),
      const SizedBox(width: 10),
      Expanded(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: BM.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('📉 PEOR',
              style: TextStyle(color: BM.error,
                  fontWeight: FontWeight.w800, fontSize: 12)))),
        const SizedBox(height: 8),
        if (worst.clipUrl != null)
          _ClipPlayer(url: worst.clipUrl!, color: BM.error)
        else
          _NoClip(color: BM.error),
      ])),
    ]);
  }
}

class _NoClip extends StatelessWidget {
  final Color color;
  const _NoClip({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    decoration: BoxDecoration(color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.videocam_off_rounded, color: color.withOpacity(0.4), size: 24),
      const SizedBox(height: 6),
      Text('Video no disponible', style: TextStyle(
          color: color.withOpacity(0.6), fontSize: 10)),
    ])));
}

// ── Tabla de diferencias ──────────────────────────────────────────────────────
class _DiffTable extends StatelessWidget {
  final BestRepModel best, worst;
  const _DiffTable({required this.best, required this.worst});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DiffRow('Score técnico',    best.repScore,        worst.repScore,        '', true,  false),
      _DiffRow('Rodilla (°)',       best.kneeAngle,       worst.kneeAngle,       '°', false, true),
      _DiffRow('Valgo (°)',         best.valgus,          worst.valgus,          '°', false, false),
      _DiffRow('Bajada excéntrica', best.eccentricDur,    worst.eccentricDur,    's', true,  true),
      _DiffRow('Riesgo LCA',        best.aclRisk,         worst.aclRisk,         '', false, false),
    ];

    return GlassCard(
      child: Column(children: [
        // Header
        Row(children: const [
          Expanded(flex: 2, child: Text('Parámetro',
              style: TextStyle(color: BM.textHint, fontSize: 11,
                  fontWeight: FontWeight.w700))),
          Expanded(child: Center(child: Text('Mejor',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 11,
                  fontWeight: FontWeight.w700)))),
          Expanded(child: Center(child: Text('Peor',
              style: TextStyle(color: BM.error, fontSize: 11,
                  fontWeight: FontWeight.w700)))),
          Expanded(child: Center(child: Text('Dif.',
              style: TextStyle(color: BM.textHint, fontSize: 11,
                  fontWeight: FontWeight.w700)))),
        ]),
        const Divider(color: Colors.white12, height: 16),
        ...rows,
      ]),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label, unit;
  final double? bestVal, worstVal;
  final bool higherIsBetter, lowerKneeIsBetter;

  const _DiffRow(this.label, this.bestVal, this.worstVal, this.unit,
      this.higherIsBetter, this.lowerKneeIsBetter);

  @override
  Widget build(BuildContext context) {
    if (bestVal == null || worstVal == null) return const SizedBox.shrink();
    final diff = bestVal! - worstVal!;
    final isImproved = higherIsBetter ? diff > 0 : diff < 0;
    final diffColor = isImproved ? BM.accent : BM.error;
    final diffSign  = diff > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label,
            style: const TextStyle(color: BM.textSecondary, fontSize: 12))),
        Expanded(child: Center(child: Text(
          '${bestVal!.toStringAsFixed(1)}$unit',
          style: const TextStyle(color: Color(0xFFFFD700),
              fontWeight: FontWeight.w600, fontSize: 12)))),
        Expanded(child: Center(child: Text(
          '${worstVal!.toStringAsFixed(1)}$unit',
          style: const TextStyle(color: BM.error,
              fontWeight: FontWeight.w600, fontSize: 12)))),
        Expanded(child: Center(child: Text(
          '$diffSign${diff.toStringAsFixed(1)}$unit',
          style: TextStyle(color: diffColor,
              fontWeight: FontWeight.w700, fontSize: 12)))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.compare_arrows_rounded, color: BM.textHint, size: 60)
          .animate().scale(duration: 400.ms),
      const SizedBox(height: 20),
      const Text('Sin reps registradas aún',
          style: TextStyle(color: BM.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 10),
      const Text('Analiza al menos 2 videos para ver la comparación',
          style: TextStyle(color: BM.textSecondary, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GBtn(text: 'Analizar video', height: 48,
          onTap: () => context.go('/capture')),
    ]));
}

class _ErrorState extends StatelessWidget {
  final BestRepViewModel vm;
  const _ErrorState(this.vm);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: BM.error, size: 48),
      const SizedBox(height: 16),
      Text(vm.error ?? 'Error', style: const TextStyle(color: BM.textSecondary)),
      const SizedBox(height: 20),
      GBtn(text: 'Reintentar', height: 46,
          onTap: () => vm.load('squat')),
    ]));
}
