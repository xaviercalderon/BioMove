// view/screens/improvement/improvement_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../view/widgets/common_widgets.dart';

// Datos de ejercicios correctivos con animaciones SVG-like usando CustomPainter
const _exercises = {
  'knee_valgus': _ExerciseData(
    name: 'Sentadilla con banda elástica',
    muscle: 'Glúteo medio · Abductores',
    sets: '3×12', duration: '3 veces/semana',
    tip: 'Coloca la banda por encima de las rodillas. Empuja activamente hacia afuera durante todo el movimiento.',
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFFFF5252),
    steps: ['Coloca banda sobre rodillas', 'Pies al ancho de caderas', 'Baja controlando las rodillas', 'Empuja rodillas afuera al subir'],
  ),
  'trunk_lean': _ExerciseData(
    name: 'Goblet Squat con kettlebell',
    muscle: 'Core · Espalda alta · Cuádriceps',
    sets: '3×10', duration: '3 veces/semana',
    tip: 'Sujeta el peso frente al pecho. Esto te fuerza a mantener el tronco erguido.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFFB74D),
    steps: ['Sujeta peso frente al pecho', 'Pies separados', 'Baja manteniendo pecho arriba', 'Codos tocan rodillas al fondo'],
  ),
  'heel_elevation': _ExerciseData(
    name: 'Dorsiflexión con banda',
    muscle: 'Sóleo · Gemelos',
    sets: '3×15 cada pie', duration: 'Diario',
    tip: 'Ancla la banda al suelo. Flexiona el tobillo contra la resistencia. Mantén el talón en el suelo.',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFF64B5F6),
    steps: ['Ancla banda al suelo', 'Rodilla sobre el pie', 'Empuja rodilla hacia adelante', 'Mantén talón pegado'],
  ),
  'butt_wink': _ExerciseData(
    name: '90/90 Hip Stretch',
    muscle: 'Rotadores externos · Psoas',
    sets: '2 min cada lado', duration: 'Diario',
    tip: 'Siéntate con ambas piernas en 90°. Mantén la espalda recta. No fuerces el dolor.',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF9C27B0),
    steps: ['Siéntate con piernas en 90/90', 'Inclínate sobre pierna delantera', 'Mantén espalda recta', 'Respira y relaja la cadera'],
  ),
  'asymmetry': _ExerciseData(
    name: 'Bulgarian Split Squat',
    muscle: 'Cuádriceps · Glúteo · Equilibrio',
    sets: '3×8 cada pierna', duration: '2 veces/semana',
    tip: 'Trabaja cada pierna por separado para corregir desequilibrios. Empieza con tu pierna débil.',
    icon: Icons.airline_seat_legroom_extra_rounded,
    color: Color(0xFF00D4AA),
    steps: ['Pie trasero en banco', 'Pie delantero al frente', 'Baja rodilla trasera al suelo', 'Sube empujando con pie delantero'],
  ),
  'lateral_hip_shift': _ExerciseData(
    name: 'Caminata con banda lateral',
    muscle: 'Glúteo medio · Abductores',
    sets: '3×15 pasos cada lado', duration: '3 veces/semana',
    tip: 'Mantén las rodillas ligeramente flexionadas. Pasos laterales controlados sin que la banda te jale.',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFFFF8A65),
    steps: ['Banda sobre rodillas', 'Posición de sentadilla parcial', 'Paso lateral sin arrastrar pies', 'Mantén tensión en la banda'],
  ),
};

class _ExerciseData {
  final String name, muscle, sets, duration, tip;
  final IconData icon;
  final Color color;
  final List<String> steps;
  const _ExerciseData({required this.name, required this.muscle,
      required this.sets, required this.duration, required this.tip,
      required this.icon, required this.color, required this.steps});
}

class ImprovementPlanScreen extends StatelessWidget {
  final List<Map<String, dynamic>> feedback;
  const ImprovementPlanScreen({super.key, this.feedback = const []});

  @override
  Widget build(BuildContext context) {
    // Obtener errores del resultado del análisis o usar ejemplos
    final errors = feedback.isNotEmpty ? feedback : _mockFeedback();

    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Plan de mejora'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          GlassCard(child: Column(children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFD700), size: 36),
            const SizedBox(height: 10),
            const Text('Tu plan de mejora personalizado',
                style: TextStyle(color: BM.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('${errors.length} puntos de mejora identificados',
                style: const TextStyle(color: BM.textSecondary, fontSize: 13)),
          ])).animate().fadeIn(),
          const SizedBox(height: 20),

          // Ejercicios correctivos
          ...errors.asMap().entries.map((entry) {
            final i   = entry.key;
            final err = entry.value;
            final key = err['error_type'] as String? ?? '';
            final ex  = _exercises[key] ?? _exercises['trunk_lean']!;
            return _ExerciseCard(exercise: ex, priority: i + 1,
                isRisk: err['is_injury_risk'] == true)
                .animate().fadeIn(delay: Duration(milliseconds: i * 100))
                .slideX(begin: 0.05);
          }),

          const SizedBox(height: 20),

          // Plan semanal
          const SectionHeader(title: '📅 Tu semana de corrección'),
          const SizedBox(height: 12),
          _WeeklyPlan(errors: errors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _mockFeedback() => [
    {'error_type': 'knee_valgus',     'is_injury_risk': true,  'severity': 'severe'},
    {'error_type': 'trunk_lean',      'is_injury_risk': false, 'severity': 'moderate'},
    {'error_type': 'heel_elevation',  'is_injury_risk': false, 'severity': 'mild'},
  ];
}

class _ExerciseCard extends StatefulWidget {
  final _ExerciseData exercise;
  final int priority;
  final bool isRisk;
  const _ExerciseCard({required this.exercise, required this.priority,
      required this.isRisk});
  @override State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final color = widget.isRisk ? BM.error : ex.color;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: BM.card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Número de prioridad
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Center(child: Text('${widget.priority}',
                      style: TextStyle(color: color,
                          fontWeight: FontWeight.w800, fontSize: 14)))),
                const SizedBox(width: 12),
                // Ícono animado
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color.withOpacity(0.6), color]),
                    shape: BoxShape.circle),
                  child: Icon(ex.icon, color: Colors.white, size: 22))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 2000.ms, begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        curve: Curves.easeInOut),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (widget.isRisk)
                    Container(margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: BM.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('⚠️ Prioridad alta',
                          style: TextStyle(color: BM.error,
                              fontSize: 10, fontWeight: FontWeight.w700))),
                  Text(ex.name, style: const TextStyle(color: BM.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(ex.muscle, style: const TextStyle(
                      color: BM.textSecondary, fontSize: 11)),
                ])),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: BM.textHint),
              ]),
            ),
          ),

          // Detalle expandido
          if (_expanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Prescripción
                Row(children: [
                  _PrescTag(ex.sets, Icons.repeat_rounded, color),
                  const SizedBox(width: 8),
                  _PrescTag(ex.duration, Icons.calendar_today_rounded, color),
                ]),
                const SizedBox(height: 14),

                // Animación de pasos
                _StepsAnimation(steps: ex.steps, color: color),
                const SizedBox(height: 14),

                // Tip
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Icon(Icons.lightbulb_rounded, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ex.tip, style: const TextStyle(
                        color: BM.textSecondary, fontSize: 12))),
                  ])),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _PrescTag extends StatelessWidget {
  final String text; final IconData icon; final Color color;
  const _PrescTag(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color,
          fontSize: 11, fontWeight: FontWeight.w600)),
    ]));
}

// Animación de pasos del ejercicio
class _StepsAnimation extends StatefulWidget {
  final List<String> steps; final Color color;
  const _StepsAnimation({required this.steps, required this.color});
  @override State<_StepsAnimation> createState() => _StepsAnimationState();
}

class _StepsAnimationState extends State<_StepsAnimation> {
  int _current = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() => _current = (_current + 1) % widget.steps.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Cómo hacerlo:',
          style: TextStyle(color: BM.textHint, fontSize: 11,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: widget.steps.asMap().entries.map((e) {
        final active = e.key == _current;
        return Expanded(child: AnimatedContainer(
          duration: 400.ms,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 4,
          decoration: BoxDecoration(
            color: active ? widget.color : Colors.white12,
            borderRadius: BorderRadius.circular(2)),
        ));
      }).toList()),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: 400.ms,
        child: Container(
          key: ValueKey(_current),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(width: 24, height: 24,
              decoration: BoxDecoration(color: widget.color,
                  shape: BoxShape.circle),
              child: Center(child: Text('${_current + 1}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.steps[_current],
                style: TextStyle(color: widget.color,
                    fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    ]);
  }
}

class _WeeklyPlan extends StatelessWidget {
  final List<Map<String, dynamic>> errors;
  const _WeeklyPlan({required this.errors});

  @override
  Widget build(BuildContext context) {
    final days = [
      ('Lunes',    'Movilidad + técnica ligera', Icons.self_improvement_rounded),
      ('Martes',   'Fuerza correctiva', Icons.fitness_center_rounded),
      ('Miércoles','Descanso activo', Icons.hotel_rounded),
      ('Jueves',   'Sentadilla técnica + correctivos', Icons.sports_rounded),
      ('Viernes',  'Fuerza + movilidad', Icons.fitness_center_rounded),
      ('Sábado',   'Sesión principal', Icons.emoji_events_rounded),
      ('Domingo',  'Descanso', Icons.hotel_rounded),
    ];

    return GlassCard(child: Column(children: days.asMap().entries.map((e) {
      final isRest = e.value.$1 == 'Miércoles' || e.value.$1 == 'Domingo';
      final color  = isRest ? BM.textHint : BM.accent;
      return Padding(
        padding: EdgeInsets.only(bottom: e.key < days.length - 1 ? 12 : 0),
        child: Row(children: [
          Container(width: 72,
            child: Text(e.value.$1, style: TextStyle(
                color: isRest ? BM.textHint : BM.textSecondary,
                fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Icon(e.value.$3, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(e.value.$2, style: TextStyle(
              color: isRest ? BM.textHint : BM.textPrimary, fontSize: 12))),
        ]),
      );
    }).toList()));
  }
}
