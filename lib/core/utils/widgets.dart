import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../theme/theme.dart';

// ── GBtn — Gradient button ────────────────────────────────────────────────────
class GBtn extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  final List<Color> colors;

  const GBtn({super.key, required this.text, this.icon, this.onTap,
      this.loading = false, this.height = 56,
      this.colors = const [BM.primary, BM.primaryDk]});

  @override
  State<GBtn> createState() => _GBtnState();
}

class _GBtnState extends State<GBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); if (enabled) widget.onTap!(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0, duration: 100.ms,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.5, duration: 200.ms,
          child: Container(
            height: widget.height, width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled ? [BoxShadow(color: widget.colors.first.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6))] : [],
            ),
            child: Center(child: widget.loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── GoogleBtn ─────────────────────────────────────────────────────────────────
class GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  const GoogleBtn({super.key, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56, width: double.infinity,
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BM.elevated, width: 1)),
      child: Center(child: loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: BM.primary, strokeWidth: 2.5))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text('G', style: TextStyle(color: Colors.red[600], fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            const Text('Continuar con Google', style: TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
      ),
    ),
  );
}

// ── ScoreGauge ─────────────────────────────────────────────────────────────────
class ScoreGauge extends StatefulWidget {
  final double score;
  final double size;
  const ScoreGauge({super.key, required this.score, this.size = 140});
  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1200.ms);
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => SizedBox(
      width: widget.size, height: widget.size,
      child: CustomPaint(
        painter: _GaugePainter(_anim.value, BM.scoreColor(widget.score)),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${(widget.score * _anim.value / widget.score * widget.score).toStringAsFixed(0)}',
              style: TextStyle(fontSize: widget.size * 0.28, fontWeight: FontWeight.w800,
                  color: BM.scoreColor(widget.score))),
          Text(BM.scoreLabel(widget.score),
              style: TextStyle(fontSize: widget.size * 0.09, color: BM.textSecondary, fontWeight: FontWeight.w500)),
        ])),
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r  = size.width * 0.44;
    final startAngle = math.pi * 0.75; final sweepTotal = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()..color = BM.elevated..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweepTotal, false, bgPaint);

    // Value arc
    if (value > 0) {
      final fgPaint = Paint()..color = color..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.07..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          startAngle, sweepTotal * value, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

// ── MetricCard ────────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;
  final int animDelay;

  const MetricCard({super.key, required this.label, required this.value, this.unit,
      required this.icon, required this.color, this.animDelay = 0});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const Spacer(),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        if (unit != null) ...[
          const SizedBox(width: 2),
          Text(unit!, style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
        ],
      ]),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
    ]),
  ).animate(delay: Duration(milliseconds: animDelay)).fadeIn().slideY(begin: 0.1);
}

// ── GlassCard ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;

  const GlassCard({super.key, required this.child, this.borderColor, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: BM.card, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.06)),
    ),
    child: child,
  );
}

// ── SectionHeader ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BM.textPrimary))),
    if (action != null)
      GestureDetector(onTap: onAction,
        child: Text(action!, style: const TextStyle(fontSize: 13, color: BM.primary, fontWeight: FontWeight.w500))),
  ]);
}

// ── SeverityBadge ─────────────────────────────────────────────────────────────
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final c = BM.severityColor(severity);
    final labels = {'severe':'Riesgo','moderate':'Moderado','mild':'Leve','riesgo':'Riesgo'};
    final label  = labels[severity] ?? severity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700)),
    );
  }
}

// ── BioBottomNav ─────────────────────────────────────────────────────────────
class BioBottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;

  const BioBottomNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Inicio'),
      (Icons.analytics_rounded, Icons.analytics_outlined, 'Progreso'),
      (Icons.history_rounded, Icons.history_outlined, 'Historial'),
      (Icons.calculate_rounded, Icons.calculate_outlined, '1RM'),
      (Icons.person_rounded, Icons.person_outlined, 'Perfil'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: BM.surface,
        border: Border(top: BorderSide(color: Color(0xFF1E1E30), width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(children: items.asMap().entries.map((e) {
            final selected = e.key == current;
            return Expanded(child: GestureDetector(
              onTap: () => onTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(duration: 200.ms,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedSwitcher(duration: 150.ms,
                    child: Icon(selected ? e.value.$1 : e.value.$2, key: ValueKey(selected),
                        color: selected ? BM.primary : BM.textHint, size: 22)),
                  const SizedBox(height: 3),
                  Text(e.value.$3, style: TextStyle(fontSize: 10,
                      color: selected ? BM.primary : BM.textHint,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                ]),
              ),
            ));
          }).toList()),
        ),
      ),
    );
  }
}

// ── BioShimmer ────────────────────────────────────────────────────────────────
class BioShimmer extends StatefulWidget {
  final double width, height, radius;
  const BioShimmer({super.key, required this.width, required this.height, this.radius = 12});
  @override
  State<BioShimmer> createState() => _BioShimmerState();
}

class _BioShimmerState extends State<BioShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: 1200.ms)..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + _ctrl.value * 2, 0),
          end:   Alignment(0  + _ctrl.value * 2, 0),
          colors: const [Color(0xFF161624), Color(0xFF1E1E30), Color(0xFF161624)],
        ),
      ),
    ),
  );
}

// ── ParamRow ──────────────────────────────────────────────────────────────────
class ParamRow extends StatelessWidget {
  final String label;
  final String? value, unit;
  final String? section;
  final bool showDivider;

  const ParamRow({super.key, required this.label, this.value, this.unit,
      this.section, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final c = section == 'riesgo' ? BM.error : (section == 'mejora' ? BM.warning : BM.accent);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          if (section != null) Container(width: 4, height: 20, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          if (section != null) const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: BM.textSecondary))),
          if (value != null)
            Text('$value${unit != null ? ' $unit' : ''}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: section != null ? c : BM.textPrimary)),
        ]),
      ),
      if (showDivider) Divider(color: Colors.white.withOpacity(0.05), height: 1),
    ]);
  }
}

// ── RiskAlertBanner ───────────────────────────────────────────────────────────
class RiskAlertBanner extends StatelessWidget {
  final String message;
  const RiskAlertBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: BM.gradDanger, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: BM.error.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  ).animate(onPlay: (c) => c.repeat(reverse: true))
      .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.1));
}

// ── ClassifierCard ────────────────────────────────────────────────────────────
class ClassifierCard extends StatelessWidget {
  final String clfClass;
  final double confidence;
  final List<Map<String, dynamic>>? topFactors;
  final String? version;

  const ClassifierCard({super.key, required this.clfClass, required this.confidence,
      this.topFactors, this.version});

  @override
  Widget build(BuildContext context) {
    final color = BM.clfColor(clfClass);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(clfClass.toUpperCase(), style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700))),
          const Spacer(),
          Text('${(confidence*100).toStringAsFixed(0)}% confianza',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        if (version != null) ...[
          const SizedBox(height: 6),
          Text('Modelo $version', style: const TextStyle(fontSize: 11, color: BM.textHint)),
        ],
        if (topFactors != null && topFactors!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Factores determinantes:', style: TextStyle(fontSize: 12, color: BM.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...topFactors!.take(3).map((f) {
            final pct = (f['importance_pct'] as num?)?.toDouble() ?? 0.0;
            final param = (f['param'] as String?)?.replaceAll('_', ' ') ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(param, style: const TextStyle(fontSize: 12, color: BM.textPrimary))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: pct/100, minHeight: 5,
                        backgroundColor: BM.elevated, valueColor: AlwaysStoppedAnimation(color)))),
                const SizedBox(width: 6),
                Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

// ── RoleBadge ─────────────────────────────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {'admin': BM.warning, 'coach': BM.accent, 'athlete': BM.primary};
    final labels = {'admin': 'Admin', 'coach': 'Entrenador', 'athlete': 'Atleta'};
    final c = colors[role] ?? BM.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(labels[role] ?? role, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
