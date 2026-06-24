// view/widgets/common_widgets.dart — Widgets reutilizables (View layer)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ── GBtn — Gradient button ─────────────────────────────────────────────────
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

class _GBtnState extends State<GBtn> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shine;
  @override
  void initState() {
    super.initState();
    _shine = AnimationController(vsync: this, duration: 700.ms);
  }
  @override void dispose() { _shine.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        if (enabled) { _shine.forward(from: 0); widget.onTap!(); }
      },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(scale: _pressed ? 0.97 : 1.0, duration: 100.ms,
        child: AnimatedOpacity(opacity: enabled ? 1.0 : 0.5, duration: 200.ms,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: widget.height, width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.colors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: enabled ? [BoxShadow(color: widget.colors.first.withOpacity(0.4),
                    blurRadius: 16, offset: const Offset(0, 6))] : [],
              ),
              child: Stack(alignment: Alignment.center, children: [
                // Efecto shine que cruza al presionar
                AnimatedBuilder(animation: _shine, builder: (_, __) {
                  if (_shine.value == 0 || _shine.value == 1) return const SizedBox.shrink();
                  return Positioned(
                    left: -widget.height + _shine.value * (widget.height*4),
                    child: Transform.rotate(angle: 0.4,
                      child: Container(width: widget.height*0.7, height: widget.height*2,
                        decoration: BoxDecoration(gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.35), Colors.white.withOpacity(0)],
                        )))),
                  );
                }),
                widget.loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (widget.icon != null) ...[Icon(widget.icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                      Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── GoogleBtn ──────────────────────────────────────────────────────────────
class GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  const GoogleBtn({super.key, this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(height: 56, width: double.infinity,
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BM.elevated)),
      child: Center(child: loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: BM.primary, strokeWidth: 2.5))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text('G', style: TextStyle(color: Colors.red[600], fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            const Text('Continuar con Google', style: TextStyle(color: BM.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          ]))));
}

// ── ScoreGauge ─────────────────────────────────────────────────────────────
class ScoreGauge extends StatefulWidget {
  final double score; final double size;
  const ScoreGauge({super.key, required this.score, this.size = 140});
  @override State<ScoreGauge> createState() => _ScoreGaugeState();
}
class _ScoreGaugeState extends State<ScoreGauge> with TickerProviderStateMixin {
  late AnimationController _ctrl;       // animación de llenado (una vez)
  late AnimationController _pulse;      // glow pulsante (loop)
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1300.ms);
    _anim = Tween<double>(begin: 0, end: widget.score/100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _pulse = AnimationController(vsync: this, duration: 2000.ms)..repeat(reverse: true);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = BM.scoreColor(widget.score);
    return AnimatedBuilder(
      animation: Listenable.merge([_anim, _pulse]),
      builder: (_, __) {
        final glow = 0.25 + 0.35 * _pulse.value;  // intensidad del halo
        return SizedBox(width: widget.size, height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(_anim.value, color, glow),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ).createShader(b),
                child: Text('${(widget.score*_anim.value).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: widget.size*0.30, fontWeight: FontWeight.w800,
                        color: Colors.white, height: 1.0)),
              ),
              Text(BM.scoreLabel(widget.score),
                  style: TextStyle(fontSize: widget.size*0.085, color: BM.textSecondary,
                      fontWeight: FontWeight.w600)),
            ])),
          ));
      });
  }
}
class _GaugePainter extends CustomPainter {
  final double value; final Color color; final double glow;
  _GaugePainter(this.value, this.color, this.glow);
  @override
  void paint(Canvas canvas, Size size) {
    final cx=size.width/2, cy=size.height/2, r=size.width*0.44;
    final startAngle=math.pi*0.75, sweepTotal=math.pi*1.5;
    final sw = size.width*0.075;
    // Track de fondo
    canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r), startAngle, sweepTotal, false,
        Paint()..color=BM.elevated..style=PaintingStyle.stroke..strokeWidth=sw..strokeCap=StrokeCap.round);
    if (value>0) {
      // Halo difuso pulsante detrás del arco
      canvas.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r), startAngle, sweepTotal*value, false,
          Paint()..color=color.withOpacity(glow)..style=PaintingStyle.stroke
            ..strokeWidth=sw*2.2..strokeCap=StrokeCap.round
            ..maskFilter=MaskFilter.blur(BlurStyle.normal, size.width*0.04));
      // Arco principal con gradiente
      final rect = Rect.fromCircle(center:Offset(cx,cy),radius:r);
      canvas.drawArc(rect, startAngle, sweepTotal*value, false,
          Paint()
            ..shader = SweepGradient(
              startAngle: startAngle, endAngle: startAngle+sweepTotal,
              colors: [color.withOpacity(0.6), color],
            ).createShader(rect)
            ..style=PaintingStyle.stroke..strokeWidth=sw..strokeCap=StrokeCap.round);
    }
  }
  @override bool shouldRepaint(_GaugePainter o) => o.value!=value || o.glow!=glow;
}

// ── MetricCard ─────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label, value; final String? unit; final IconData icon; final Color color; final int animDelay;
  const MetricCard({super.key, required this.label, required this.value, this.unit,
      required this.icon, required this.color, this.animDelay = 0});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.10), BM.card],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ).animate(delay: Duration(milliseconds: animDelay+100)).scale(begin: const Offset(0.5,0.5), curve: Curves.elasticOut),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        if (unit != null) ...[const SizedBox(width: 2), Text(unit!, style: const TextStyle(fontSize: 12, color: BM.textSecondary))],
      ]),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
    ]),
  ).animate(delay: Duration(milliseconds: animDelay)).fadeIn().slideY(begin: 0.15);
}

// ── GlassCard ──────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child; final Color? borderColor; final EdgeInsets? padding; final EdgeInsets? margin;
  const GlassCard({super.key, required this.child, this.borderColor, this.padding, this.margin});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity,
    margin: margin,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.06))),
    child: child);
}

// ── SectionHeader ──────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title; final String? action; final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: BM.textPrimary))),
    if (action != null) GestureDetector(onTap: onAction,
        child: Text(action!, style: const TextStyle(fontSize: 13, color: BM.primary, fontWeight: FontWeight.w500))),
  ]);
}

// ── SeverityBadge ──────────────────────────────────────────────────────────
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});
  @override
  Widget build(BuildContext context) {
    final c = BM.severityColor(severity);
    final labels = {'severe':'Riesgo','moderate':'Moderado','mild':'Leve','riesgo':'Riesgo'};
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(labels[severity]??severity, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700)));
  }
}

// ── BioBottomNav ───────────────────────────────────────────────────────────
class BioBottomNav extends StatelessWidget {
  final int current; final void Function(int) onTap;
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
          height: 64,
          child: LayoutBuilder(builder: (context, constraints) {
            final itemW = constraints.maxWidth / items.length;
            return Stack(children: [
              // Pill deslizante animada bajo el ítem seleccionado
              AnimatedPositioned(
                duration: 320.ms,
                curve: Curves.easeOutCubic,
                left: itemW * current + itemW*0.18,
                top: 8,
                child: Container(
                  width: itemW*0.64, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      BM.primary.withOpacity(0.18), BM.accent.withOpacity(0.12)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Row(children: items.asMap().entries.map((e) {
                final sel = e.key == current;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(e.key),
                    behavior: HitTestBehavior.opaque,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedSwitcher(duration: 200.ms,
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(sel ? e.value.$1 : e.value.$2,
                          key: ValueKey(sel),
                          color: sel ? BM.primary : BM.textHint, size: 23),
                      ),
                      const SizedBox(height: 3),
                      Text(e.value.$3, style: TextStyle(fontSize: 10,
                        color: sel ? BM.primary : BM.textHint,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList()),
            ]);
          }),
        ),
      ),
    );
  }
}

// ── BioShimmer ─────────────────────────────────────────────────────────────
class BioShimmer extends StatefulWidget {
  final double width, height, radius;
  const BioShimmer({super.key, required this.width, required this.height, this.radius = 12});
  @override State<BioShimmer> createState() => _BioShimmerState();
}
class _BioShimmerState extends State<BioShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: 1200.ms)..repeat(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _ctrl,
    builder: (_, __) => Container(width: widget.width, height: widget.height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(begin: Alignment(-1+_ctrl.value*2,0), end: Alignment(0+_ctrl.value*2,0),
            colors: const [Color(0xFF161624), Color(0xFF1E1E30), Color(0xFF161624)]))));
}

// ── ParamRow ───────────────────────────────────────────────────────────────
class ParamRow extends StatelessWidget {
  final String label; final String? value, unit, section; final bool showDivider;
  const ParamRow({super.key, required this.label, this.value, this.unit, this.section, this.showDivider = true});
  @override
  Widget build(BuildContext context) {
    final c = section=='riesgo'?BM.error:(section=='mejora'?BM.warning:BM.accent);
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          if (section!=null) Container(width: 4, height: 20, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          if (section!=null) const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: BM.textSecondary))),
          if (value!=null) Text('$value${unit!=null?' $unit':''}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: section!=null?c:BM.textPrimary)),
        ])),
      if (showDivider) Divider(color: Colors.white.withOpacity(0.05), height: 1),
    ]);
  }
}

// ── RoleBadge ──────────────────────────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});
  @override
  Widget build(BuildContext context) {
    final colors = {'admin':BM.warning,'coach':BM.accent,'athlete':BM.primary};
    final labels = {'admin':'Admin','coach':'Entrenador','athlete':'Atleta'};
    final c = colors[role]??BM.primary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(labels[role]??role, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

// ── ClassifierCard ─────────────────────────────────────────────────────────
class ClassifierCard extends StatelessWidget {
  final String clfClass; final double confidence;
  final List<Map<String,dynamic>>? topFactors; final String? version;
  const ClassifierCard({super.key, required this.clfClass, required this.confidence, this.topFactors, this.version});
  @override
  Widget build(BuildContext context) {
    final color = BM.clfColor(clfClass);
    return Container(padding: const EdgeInsets.all(16),
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
        if (version!=null) ...[const SizedBox(height: 6), Text('Modelo $version', style: const TextStyle(fontSize: 11, color: BM.textHint))],
        if (topFactors!=null && topFactors!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Factores determinantes:', style: TextStyle(fontSize: 12, color: BM.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...topFactors!.take(3).map((f) {
            final pct = (f['importance_pct'] as num?)?.toDouble()??0.0;
            final param = (f['param'] as String?)?.replaceAll('_',' ')??'';
            return Padding(padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(param, style: const TextStyle(fontSize: 12, color: BM.textPrimary))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: pct/100, minHeight: 5, backgroundColor: BM.elevated,
                        valueColor: AlwaysStoppedAnimation(color)))),
                const SizedBox(width: 6),
                Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
              ]));
          }),
        ],
      ]));
  }
}


// ── ParticleBackground — partículas flotantes sutiles ───────────────────────
class ParticleBackground extends StatefulWidget {
  final int count;
  const ParticleBackground({super.key, this.count = 22});
  @override State<ParticleBackground> createState() => _ParticleBackgroundState();
}
class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(widget.count, (_) => _Particle(
      x: rnd.nextDouble(), y: rnd.nextDouble(),
      r: 1.0 + rnd.nextDouble()*2.0,
      speed: 0.02 + rnd.nextDouble()*0.05,
      drift: (rnd.nextDouble()-0.5)*0.02,
      opacity: 0.15 + rnd.nextDouble()*0.35,
      accent: rnd.nextBool(),
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(_particles, _ctrl.value),
        size: Size.infinite,
      )),
  );
}
class _Particle {
  double x, y, r, speed, drift, opacity; bool accent;
  _Particle({required this.x, required this.y, required this.r, required this.speed,
    required this.drift, required this.opacity, required this.accent});
}
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles; final double t;
  _ParticlePainter(this.particles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - t * p.speed) % 1.0;
      final x = (p.x + math.sin(t * 6.28 + p.y * 10) * p.drift) % 1.0;
      final color = (p.accent ? BM.accent : BM.primary).withOpacity(p.opacity);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.r,
          Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }
  }
  @override bool shouldRepaint(_ParticlePainter o) => o.t != t;
}

// ── CountUpText — número que cuenta desde 0 hasta el valor ──────────────────
class CountUpText extends StatelessWidget {
  final double value; final String suffix; final TextStyle? style; final int decimals;
  const CountUpText({super.key, required this.value, this.suffix = '', this.style, this.decimals = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: 900.ms, curve: Curves.easeOutCubic,
    builder: (_, v, __) => Text('${v.toStringAsFixed(decimals)}$suffix', style: style),
  );
}


// ── ConfettiBurst — celebración para scores altos ──────────────────────────
class ConfettiBurst extends StatefulWidget {
  final bool active;
  const ConfettiBurst({super.key, this.active = true});
  @override State<ConfettiBurst> createState() => _ConfettiBurstState();
}
class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Confetto> _pieces;
  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const palette = [BM.primary, BM.accent, BM.warning, BM.primaryLt, BM.success];
    _pieces = List.generate(60, (_) => _Confetto(
      x: rnd.nextDouble(),
      vx: (rnd.nextDouble()-0.5)*0.6,
      vy: 0.4 + rnd.nextDouble()*0.8,
      rot: rnd.nextDouble()*6.28,
      vrot: (rnd.nextDouble()-0.5)*8,
      size: 5.0 + rnd.nextDouble()*7,
      color: palette[rnd.nextInt(palette.length)],
      delay: rnd.nextDouble()*0.3,
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    if (widget.active) _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(child: AnimatedBuilder(animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_pieces, _ctrl.value), size: Size.infinite)));
  }
}
class _Confetto {
  double x, vx, vy, rot, vrot, size, delay; Color color;
  _Confetto({required this.x, required this.vx, required this.vy, required this.rot,
    required this.vrot, required this.size, required this.color, required this.delay});
}
class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> pieces; final double t;
  _ConfettiPainter(this.pieces, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final x = (p.x + p.vx * lt) * size.width;
      final y = (-0.1 + p.vy * lt + 0.5 * lt * lt) * size.height;
      if (y > size.height) continue;
      final opacity = (1 - lt).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.vrot * lt);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size*0.5),
        Paint()..color = p.color.withOpacity(opacity));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}
