// view/widgets/percentile_widget.dart — Comparación con atletas de referencia
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';

// Records mundiales de referencia (IPF 2024)
const _references = {
  'squat': {
    'M': [
      {'weight': 59,  'elite': 180.0, 'advanced': 140.0, 'intermediate': 100.0},
      {'weight': 66,  'elite': 205.0, 'advanced': 160.0, 'intermediate': 115.0},
      {'weight': 74,  'elite': 230.0, 'advanced': 180.0, 'intermediate': 130.0},
      {'weight': 83,  'elite': 255.0, 'advanced': 200.0, 'intermediate': 145.0},
      {'weight': 93,  'elite': 280.0, 'advanced': 220.0, 'intermediate': 160.0},
      {'weight': 105, 'elite': 305.0, 'advanced': 240.0, 'intermediate': 175.0},
      {'weight': 120, 'elite': 335.0, 'advanced': 265.0, 'intermediate': 195.0},
    ],
    'F': [
      {'weight': 47,  'elite': 120.0, 'advanced': 90.0,  'intermediate': 65.0},
      {'weight': 52,  'elite': 135.0, 'advanced': 100.0, 'intermediate': 72.0},
      {'weight': 57,  'elite': 148.0, 'advanced': 112.0, 'intermediate': 80.0},
      {'weight': 63,  'elite': 162.0, 'advanced': 122.0, 'intermediate': 88.0},
      {'weight': 72,  'elite': 175.0, 'advanced': 133.0, 'intermediate': 96.0},
      {'weight': 84,  'elite': 188.0, 'advanced': 143.0, 'intermediate': 105.0},
    ],
  },
};

class PercentileWidget extends StatelessWidget {
  final double oneRm;
  final double bodyWeight;
  final String sex;  // 'M' o 'F'
  final String exercise;

  const PercentileWidget({super.key, required this.oneRm,
      required this.bodyWeight, required this.sex, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final ref = _getReference();
    if (ref == null) return const SizedBox.shrink();

    final elite        = ref['elite'] as double;
    final advanced     = ref['advanced'] as double;
    final intermediate = ref['intermediate'] as double;
    final ratio        = oneRm / bodyWeight;

    String level; Color levelColor; double pct;
    if (oneRm >= elite) {
      level = 'Elite'; levelColor = const Color(0xFFFFD700);
      pct = 1.0;
    } else if (oneRm >= advanced) {
      level = 'Avanzado'; levelColor = const Color(0xFF00D4AA);
      pct = 0.7 + (oneRm - advanced) / (elite - advanced) * 0.3;
    } else if (oneRm >= intermediate) {
      level = 'Intermedio'; levelColor = BM.primary;
      pct = 0.4 + (oneRm - intermediate) / (advanced - intermediate) * 0.3;
    } else {
      level = 'Principiante'; levelColor = BM.warning;
      pct = (oneRm / intermediate * 0.4).clamp(0.0, 0.4);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.leaderboard_rounded, color: levelColor, size: 20),
          const SizedBox(width: 8),
          Text('Comparación con atletas',
              style: TextStyle(color: levelColor,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: levelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(level, style: TextStyle(color: levelColor,
                fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 12),
        Text('Tu 1RM: ${oneRm.toStringAsFixed(1)}kg  ·  '
            '${ratio.toStringAsFixed(2)}× tu peso corporal',
            style: const TextStyle(color: BM.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        LinearPercentIndicator(
          lineHeight: 14, percent: pct.clamp(0.0, 1.0),
          center: Text('${(pct * 100).toInt()}%',
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w700)),
          barRadius: const Radius.circular(7),
          backgroundColor: Colors.white10,
          linearGradient: LinearGradient(colors: [
            levelColor.withOpacity(0.6), levelColor]),
          animation: true, animationDuration: 1000,
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _RefMark('Intermedio', intermediate, BM.warning),
          _RefMark('Avanzado', advanced, BM.primary),
          _RefMark('Elite', elite, const Color(0xFFFFD700)),
        ]),
        const SizedBox(height: 8),
        Text('Referencia: categoría ${sex == 'M' ? 'masculina' : 'femenina'} '
            '${_nearestWeight()}kg (IPF 2024)',
            style: const TextStyle(color: BM.textHint, fontSize: 10)),
      ]),
    ).animate().fadeIn();
  }

  Map<String, dynamic>? _getReference() {
    final exData = _references[exercise];
    if (exData == null) return null;
    final sexData = (exData[sex] as List?)?.cast<Map<String, dynamic>>();
    if (sexData == null || sexData.isEmpty) return null;
    return sexData.reduce((a, b) =>
        ((a['weight'] as num) - bodyWeight).abs() <
        ((b['weight'] as num) - bodyWeight).abs()
            ? a
            : b);
  }

  int _nearestWeight() {
    final ref = _getReference();
    return ((ref?['weight'] as num?) ?? 0).toInt();
  }
}

class _RefMark extends StatelessWidget {
  final String label; final double value; final Color color;
  const _RefMark(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('${value.toStringAsFixed(0)}kg',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    Text(label, style: const TextStyle(color: BM.textHint, fontSize: 9)),
  ]);
}
