// view/widgets/tutorial_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

// ── Tooltips de parámetros técnicos ──────────────────────────────────────────
const _paramTooltips = {
  'knee_angle_min': _TooltipData(
    title: '¿Qué es el ángulo de rodilla?',
    body: 'Mide cuánto se dobla tu rodilla en el punto más bajo de la sentadilla. '
          'Menos de 95° significa que llegaste al paralelo. Lo ideal es entre 80-95°.',
    icon: Icons.height_rounded,
    color: Color(0xFF6C63FF),
  ),
  'left_valgus': _TooltipData(
    title: '¿Qué es el valgo de rodilla?',
    body: 'Cuando tus rodillas colapsan hacia adentro durante la sentadilla. '
          'Más de 10° es riesgo de lesión. Trabaja glúteos y abductores para corregirlo.',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFFF5252),
  ),
  'trunk_lean_max': _TooltipData(
    title: '¿Qué es la inclinación del tronco?',
    body: 'Cuánto se inclina tu cuerpo hacia adelante. Un poco es normal (especialmente '
          'si tienes fémures largos). Más de 55° puede indicar debilidad de core.',
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFFFFB74D),
  ),
  'acl_risk_score': _TooltipData(
    title: '¿Qué es el riesgo de LCA?',
    body: 'El Ligamento Cruzado Anterior es uno de los más lesionados en sentadilla. '
          'Se calcula combinando valgo, velocidad y carga. Sobre 50 debes reducir el peso.',
    icon: Icons.healing_rounded,
    color: Color(0xFFFF5252),
  ),
  'eccentric_dur': _TooltipData(
    title: '¿Qué es la fase excéntrica?',
    body: 'Es el tiempo que tardas en bajar. Lo ideal es 2-3 segundos. '
          'Bajar lento desarrolla más fuerza, controla mejor la técnica y previene lesiones.',
    icon: Icons.timer_outlined,
    color: Color(0xFF00D4AA),
  ),
  'rpe': _TooltipData(
    title: '¿Qué es @RPE?',
    body: 'RPE (Esfuerzo Percibido) del 1 al 10. @8 significa que podrías hacer '
          '2 repeticiones más. @10 es el máximo absoluto. Entrena entre @7 y @8.5.',
    icon: Icons.speed_rounded,
    color: Color(0xFF9C27B0),
  ),
  'vbt': _TooltipData(
    title: '¿Qué es VBT?',
    body: 'Velocity Based Training: entrenar basándose en la velocidad de la barra. '
          'Cuando la barra baja de velocidad, tu músculo está fatigado. '
          'Permite ajustar el peso de forma objetiva.',
    icon: Icons.flash_on_rounded,
    color: Color(0xFFFFD700),
  ),
};

class _TooltipData {
  final String title, body;
  final IconData icon;
  final Color color;
  const _TooltipData({required this.title, required this.body,
      required this.icon, required this.color});
}

// ── Widget de parámetro con tooltip ──────────────────────────────────────────
class ParamWithTooltip extends StatelessWidget {
  final String paramKey, label, value;
  const ParamWithTooltip({super.key, required this.paramKey,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tip = _paramTooltips[paramKey];
    return Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(color: BM.textSecondary, fontSize: 12))),
      Text(value, style: TextStyle(
          color: tip?.color ?? BM.textPrimary,
          fontWeight: FontWeight.w700, fontSize: 12)),
      if (tip != null) ...[
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _showTooltip(context, tip),
          child: Icon(Icons.help_outline_rounded,
              color: BM.textHint, size: 14),
        ),
      ],
    ]);
  }

  void _showTooltip(BuildContext context, _TooltipData tip) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: BM.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [tip.color.withOpacity(0.6), tip.color]),
              shape: BoxShape.circle),
            child: Icon(tip.icon, color: Colors.white, size: 28))
              .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(tip.title, style: const TextStyle(color: BM.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(tip.body, style: const TextStyle(color: BM.textSecondary,
              fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: tip.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            )),
        ])),
    ));
  }
}

// ── Tutorial interactivo de primera vez ──────────────────────────────────────
class FirstTimeTutorial extends StatefulWidget {
  final String screenKey;
  final Widget child;
  final List<_TutorialStep> steps;
  const FirstTimeTutorial({super.key, required this.screenKey,
      required this.child, required this.steps});

  @override State<FirstTimeTutorial> createState() => _FirstTimeTutorialState();
}

class _FirstTimeTutorialState extends State<FirstTimeTutorial> {
  bool _show = false;
  int  _step = 0;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = 'tutorial_done_${widget.screenKey}';
    if (!(prefs.getBool(key) ?? false)) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _show = true);
    }
  }

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_done_${widget.screenKey}', true);
    setState(() { _show = false; _step = 0; });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_show) _TutorialOverlay(
        steps: widget.steps,
        currentStep: _step,
        onNext: () {
          if (_step < widget.steps.length - 1) {
            setState(() => _step++);
          } else {
            _done();
          }
        },
        onSkip: _done,
      ),
    ]);
  }
}

class _TutorialStep {
  final String title, description;
  final IconData icon;
  final Color color;
  const _TutorialStep({required this.title, required this.description,
      required this.icon, required this.color});
}

class _TutorialOverlay extends StatelessWidget {
  final List<_TutorialStep> steps;
  final int currentStep;
  final VoidCallback onNext, onSkip;
  const _TutorialOverlay({required this.steps, required this.currentStep,
      required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Indicador de pasos
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: steps.asMap().entries.map((e) => AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: e.key == currentStep ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.key == currentStep ? step.color : Colors.white24,
                  borderRadius: BorderRadius.circular(4)),
              )).toList()),
          const SizedBox(height: 32),

          // Ícono animado
          Container(width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [step.color.withOpacity(0.7), step.color]),
              shape: BoxShape.circle),
            child: Icon(step.icon, color: Colors.white, size: 40))
              .animate().scale(duration: 500.ms, curve: Curves.elasticOut)
              .then().shake(duration: 300.ms),

          const SizedBox(height: 24),
          Text(step.title, style: const TextStyle(color: Colors.white,
              fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 12),
          Text(step.description, style: TextStyle(
              color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.6),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),

          // Botones
          Row(children: [
            TextButton(onPressed: onSkip,
                child: const Text('Saltar', style: TextStyle(color: Colors.white54))),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: step.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: onNext,
              child: Text(currentStep < steps.length - 1 ? 'Siguiente →' : '¡Empezar!'),
            ),
          ]),
        ]),
      )),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Tutoriales predefinidos por pantalla ──────────────────────────────────────
class AppTutorials {
  static const results = [
    _TutorialStep(
      title: 'Tu análisis está listo',
      description: 'Aquí verás todo sobre tu sentadilla: video anotado, '
          'parámetros biomecánicos y tu plan de mejora personalizado.',
      icon: Icons.analytics_rounded,
      color: Color(0xFF6C63FF),
    ),
    _TutorialStep(
      title: 'El semáforo técnico',
      description: 'Verde = correcto ✓, Amarillo = puede mejorar, '
          'Rojo = requiere atención. Toca cada tarjeta para ver la corrección.',
      icon: Icons.traffic_rounded,
      color: Color(0xFF00D4AA),
    ),
    _TutorialStep(
      title: 'Tus 4 pestañas',
      description: 'Resumen: vista rápida. Análisis: los 40 parámetros. '
          'Reps: cada repetición. Mi IA: tu modelo personal aprendiendo.',
      icon: Icons.tab_rounded,
      color: Color(0xFFFFB74D),
    ),
  ];

  static const progression = [
    _TutorialStep(
      title: 'Planificación inteligente',
      description: 'Tu plan de 11 semanas calculado con tu 1RM real. '
          'Cada semana tiene el peso exacto y @RPE objetivo para ti.',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF6C63FF),
    ),
    _TutorialStep(
      title: '¿Qué es @RPE?',
      description: '@8 significa que al terminar el set, podrías hacer 2 reps más. '
          'Es la forma más inteligente de controlar la intensidad sin llegar al fallo.',
      icon: Icons.speed_rounded,
      color: Color(0xFF9C27B0),
    ),
    _TutorialStep(
      title: 'Sube tu video después',
      description: 'Después de cada sesión, sube el video. '
          'La IA calcula tu RPE real y ajusta los pesos de la próxima semana automáticamente.',
      icon: Icons.videocam_rounded,
      color: Color(0xFF00D4AA),
    ),
  ];
}

// ── Onboarding progresivo (desbloquear features) ──────────────────────────────
class FeatureUnlockBanner extends StatefulWidget {
  final String featureKey, title, description;
  final IconData icon; final Color color;
  const FeatureUnlockBanner({super.key, required this.featureKey,
      required this.title, required this.description,
      required this.icon, required this.color});
  @override State<FeatureUnlockBanner> createState() => _FeatureUnlockBannerState();
}

class _FeatureUnlockBannerState extends State<FeatureUnlockBanner> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = 'feature_shown_${widget.featureKey}';
    if (!(prefs.getBool(key) ?? false)) {
      setState(() => _show = true);
      await prefs.setBool(key, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [widget.color.withOpacity(0.15), BM.card]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withOpacity(0.4))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [widget.color.withOpacity(0.6), widget.color]),
            shape: BoxShape.circle),
          child: Icon(widget.icon, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: widget.color,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('🔓 DESBLOQUEADO',
                  style: TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 4),
          Text(widget.title, style: TextStyle(color: widget.color,
              fontWeight: FontWeight.w700, fontSize: 13)),
          Text(widget.description, style: const TextStyle(
              color: BM.textSecondary, fontSize: 11)),
        ])),
        IconButton(icon: const Icon(Icons.close_rounded, color: BM.textHint, size: 18),
            onPressed: () => setState(() => _show = false)),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }
}
