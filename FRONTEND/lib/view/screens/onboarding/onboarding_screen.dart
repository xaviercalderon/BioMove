// view/screens/onboarding/onboarding_screen.dart
// ISO/IEC 25010:2023 — Aprendizabilidad + Operabilidad — Patrón MVVM
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../../viewmodel/auth_viewmodel.dart';
import '../../../viewmodel/onboarding_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl   = PageController();
  late final OnboardingViewModel _vm;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = OnboardingViewModel();
    _vm.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    if (_pageCtrl.hasClients && _pageCtrl.page?.round() != _vm.currentPage) {
      _pageCtrl.animateToPage(_vm.currentPage, duration: 380.ms, curve: Curves.easeInOutCubic);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_sync); _vm.dispose();
    _pageCtrl.dispose(); _heightCtrl.dispose(); _weightCtrl.dispose(); _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _vm,
    child: Scaffold(
      backgroundColor: BM.bg,
      body: SafeArea(child: Column(children: [
        _TopBar(vm: _vm, onSkip: _skipToData),
        Expanded(child: PageView(
          controller: _pageCtrl, physics: const BouncingScrollPhysics(),
          onPageChanged: (p) => _vm.setPage(p),
          children: [
            ...OnboardingViewModel.introSlides.map((s) => _SlideView(slide: s)),
            _DataFormView(vm: _vm, hCtrl: _heightCtrl, wCtrl: _weightCtrl, aCtrl: _ageCtrl),
          ],
        )),
        _BottomBar(vm: _vm, onNext: _vm.nextPage, onBegin: _save, onSkip: _skipSave),
      ])),
    ),
  );

  void _skipToData() {
    _vm.skipToData();
    _pageCtrl.animateToPage(OnboardingViewModel.introSlides.length, duration: 450.ms, curve: Curves.easeInOutCubic);
  }

  Future<void> _save() async {
    _vm.clearError();
    final err = _vm.dataError;
    if (err != null) { _vm.setError(err); return; }
    _vm.setSaving(true);
    final auth = context.read<AuthViewModel>();
    final ok   = await auth.savePhysicalData(h: _vm.heightCm!, w: _vm.weightKg!, age: _vm.age!, sex: _vm.sex, years: _vm.years);
    if (mounted) { _vm.setSaving(false); if (ok) _go(auth); }
  }

  Future<void> _skipSave() async {
    final auth = context.read<AuthViewModel>();
    try { await auth.refreshProfile(); } catch (_) {}
    if (mounted) _go(auth);
  }

  void _go(AuthViewModel a) {
    switch (a.role) {
      case 'admin': context.go('/admin'); break;
      case 'coach': context.go('/coach'); break;
      default:      context.go('/dashboard');
    }
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final OnboardingViewModel vm; final VoidCallback onSkip;
  const _TopBar({required this.vm, required this.onSkip});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: BM.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BM.primary.withOpacity(0.3))),
        child: Text('Paso ${vm.currentPage+1} de ${vm.totalPages}',
            style: const TextStyle(color: BM.primary, fontSize: 11, fontWeight: FontWeight.w600))),
      const Spacer(),
      SizedBox(width: 90, child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: vm.progress, minHeight: 5, backgroundColor: BM.elevated,
              valueColor: const AlwaysStoppedAnimation(BM.primary)))),
      if (vm.canSkipCurrent) ...[
        const SizedBox(width: 12),
        GestureDetector(onTap: onSkip,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: BM.elevated)),
            child: const Text('Saltar', style: TextStyle(color: BM.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)))),
      ],
    ]),
  );
}

// ── Bottom Bar ─────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final OnboardingViewModel vm; final VoidCallback onNext, onBegin, onSkip;
  const _BottomBar({required this.vm, required this.onNext, required this.onBegin, required this.onSkip});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (vm.isOnIntroSlide)
        Padding(padding: const EdgeInsets.only(bottom: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(vm.totalPages, (i) => AnimatedContainer(duration: 250.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i==vm.currentPage?22:7, height: 7,
              decoration: BoxDecoration(color: i==vm.currentPage?BM.primary:BM.elevated, borderRadius: BorderRadius.circular(4)))))),
      if (vm.error != null)
        Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BM.error.withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.error_outline_rounded, color: BM.error, size: 14), const SizedBox(width: 8),
            Expanded(child: Text(vm.error!, style: const TextStyle(color: BM.error, fontSize: 12)))])),
      vm.isOnIntroSlide
        ? GBtn(text: vm.currentPage < vm.totalPages-2 ? 'Siguiente' : 'Continuar', icon: Icons.arrow_forward_rounded, onTap: onNext)
        : GBtn(
            text: 'Empezar a usar BioMove',
            icon: Icons.check_rounded,
            loading: vm.saving,
            onTap: (vm.saving || !vm.dataIsValid) ? null : onBegin,
            colors: !vm.dataIsValid
                ? const [Color(0xFF2A2A3E), Color(0xFF1E1E30)]
                : const [BM.primary, BM.primaryDk],
          ),
      if (vm.isOnDataForm) ...[
        const SizedBox(height: 10),
        GestureDetector(onTap: onSkip,
          child: const Text('Completar datos después', style: TextStyle(color: BM.textSecondary, fontSize: 12))),
      ],
    ]),
  );
}

// ── Slide View ─────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final dynamic slide;
  const _SlideView({required this.slide});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(children: [
      const SizedBox(height: 16),
      SizedBox(height: 200, child: _getAnim(slide.animationKey)).animate().fadeIn(duration: 500.ms),
      const SizedBox(height: 20),
      Text(slide.title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: BM.textPrimary, height: 1.2))
          .animate().fadeIn(delay: 120.ms).slideY(begin: 0.15),
      const SizedBox(height: 7),
      Text(slide.subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: BM.accent, fontWeight: FontWeight.w500)).animate().fadeIn(delay: 180.ms),
      const SizedBox(height: 20),
      ...(slide.bulletPoints as List<String>).asMap().entries.map((e) => _BulletItem(text: e.value, delay: 260+e.key*90)),
      const SizedBox(height: 16),
    ]),
  );

  Widget _getAnim(String key) {
    switch (key) {
      case 'ai_coach':      return const _AICoachAnim();
      case 'learning':      return const _LearningAnim();
      case 'how_to_record': return const _HowToRecordAnim();
      default:              return const _AICoachAnim();
    }
  }
}

class _BulletItem extends StatelessWidget {
  final String text; final int delay;
  const _BulletItem({required this.text, required this.delay});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Row(children: [
      Container(width: 26, height: 26, decoration: BoxDecoration(color: BM.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
          child: const Icon(Icons.check_rounded, color: BM.primary, size: 14)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: BM.textPrimary, height: 1.4))),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.12);
}

// ── Animaciones Canvas ─────────────────────────────────────────────────────

class _AICoachAnim extends StatefulWidget {
  const _AICoachAnim();
  @override State<_AICoachAnim> createState() => _AICoachAnimState();
}
class _AICoachAnimState extends State<_AICoachAnim> with TickerProviderStateMixin {
  late AnimationController _p, _o, _s;
  @override void initState() { super.initState();
    _p = AnimationController(vsync: this, duration: 1800.ms)..repeat(reverse: true);
    _o = AnimationController(vsync: this, duration: 4000.ms)..repeat();
    _s = AnimationController(vsync: this, duration: 2500.ms)..repeat();
  }
  @override void dispose() { _p.dispose(); _o.dispose(); _s.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_p,_o,_s]),
    builder: (_, __) => CustomPaint(size: const Size(double.infinity, 200),
        painter: _AICoachPainter(p: _p.value, o: _o.value, s: _s.value)));
}
class _AICoachPainter extends CustomPainter {
  final double p, o, s;
  _AICoachPainter({required this.p, required this.o, required this.s});
  @override void paint(Canvas canvas, Size size) {
    final cx=size.width/2, cy=size.height/2+5;
    canvas.drawCircle(Offset(cx,cy),82+p*8,Paint()..color=BM.primary.withOpacity(0.05+p*0.07)..style=PaintingStyle.fill);
    canvas.drawCircle(Offset(cx,cy),60+p*5,Paint()..color=BM.primary.withOpacity(0.09+p*0.05)..style=PaintingStyle.fill);
    final bp=Paint()..color=BM.primary.withOpacity(0.65+p*0.35)..strokeWidth=2.5..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    canvas.drawCircle(Offset(cx,cy-55),11,Paint()..color=BM.accent.withOpacity(0.75)..style=PaintingStyle.fill);
    canvas.drawLine(Offset(cx,cy-44),Offset(cx,cy-12),bp);
    canvas.drawLine(Offset(cx-22,cy-33),Offset(cx+22,cy-33),bp);
    canvas.drawLine(Offset(cx-22,cy-33),Offset(cx-26,cy-8),bp);
    canvas.drawLine(Offset(cx+22,cy-33),Offset(cx+26,cy-8),bp);
    canvas.drawLine(Offset(cx-14,cy-12),Offset(cx+14,cy-12),bp);
    canvas.drawLine(Offset(cx-14,cy-12),Offset(cx-18,cy+30),bp);
    canvas.drawLine(Offset(cx+14,cy-12),Offset(cx+18,cy+30),bp);
    canvas.drawLine(Offset(cx-18,cy+30),Offset(cx-26,cy+40),bp);
    canvas.drawLine(Offset(cx+18,cy+30),Offset(cx+26,cy+40),bp);
    for (final j in [Offset(cx,cy-44),Offset(cx-22,cy-33),Offset(cx+22,cy-33),Offset(cx-14,cy-12),Offset(cx+14,cy-12),Offset(cx-18,cy+30),Offset(cx+18,cy+30)]) {
      canvas.drawCircle(j,4+p*1.5,Paint()..color=BM.accent..style=PaintingStyle.fill);
    }
    canvas.drawCircle(Offset(cx+70*math.cos(o*math.pi*2),cy+28*math.sin(o*math.pi*2)),5,Paint()..color=BM.warning.withOpacity(0.9)..style=PaintingStyle.fill);
    final sy=cy-58+s*115;
    canvas.drawLine(Offset(cx-52,sy),Offset(cx+52,sy),Paint()..color=BM.primary.withOpacity(0.25)..strokeWidth=1.5..style=PaintingStyle.stroke);
    final tp=TextPainter(text:TextSpan(text:'33 puntos detectados',style:TextStyle(color:BM.accent.withOpacity(0.7),fontSize:10,fontWeight:FontWeight.w600)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas,Offset(cx-tp.width/2,cy+55));
  }
  @override bool shouldRepaint(_AICoachPainter o2)=>true;
}

class _LearningAnim extends StatefulWidget {
  const _LearningAnim();
  @override State<_LearningAnim> createState() => _LearningAnimState();
}
class _LearningAnimState extends State<_LearningAnim> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c=AnimationController(vsync:this,duration:2800.ms)..repeat(reverse:true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation:_c,
    builder:(_,__)=>CustomPaint(size:const Size(double.infinity,200),painter:_LearningPainter(t:_c.value)));
}
class _LearningPainter extends CustomPainter {
  final double t; _LearningPainter({required this.t});
  @override void paint(Canvas canvas, Size size) {
    final cx=size.width/2, baseY=size.height-30.0;
    final cols=[BM.error,BM.warning,BM.warning,BM.accent,BM.accent];
    final heights=[0.35,0.50,0.65,0.75+t*0.15,0.88+t*0.1];
    final labels=['Ses 1','Ses 2','Ses 3','Ses 4','Ahora'];
    const bW=26.0,sp=15.0,maxH=100.0;
    final startX=cx-(cols.length*(bW+sp)-sp)/2;
    final path=Path();
    for(int i=0;i<cols.length;i++){
      final x=startX+i*(bW+sp); final h=heights[i]*maxH;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,baseY-h,bW,h),const Radius.circular(6)),Paint()..color=cols[i].withOpacity(0.85));
      _t(canvas,'${(heights[i]*100).toInt()}',x+bW/2,baseY-h-15,cols[i],10);
      _t(canvas,labels[i],x+bW/2,baseY+5,BM.textHint,9);
      if(i==0)path.moveTo(x+bW/2,baseY-h-8);else path.lineTo(x+bW/2,baseY-h-8);
    }
    canvas.drawPath(path,Paint()..color=BM.primary.withOpacity(0.4)..strokeWidth=2..style=PaintingStyle.stroke);
    _t(canvas,'Tu técnica mejora sesión a sesión',cx,10,BM.textSecondary,11);
  }
  void _t(Canvas c,String t,double x,double y,Color col,double sz){
    final tp=TextPainter(text:TextSpan(text:t,style:TextStyle(color:col,fontSize:sz,fontWeight:FontWeight.w600)),textDirection:TextDirection.ltr)..layout();
    tp.paint(c,Offset(x-tp.width/2,y));
  }
  @override bool shouldRepaint(_LearningPainter o)=>true;
}

class _HowToRecordAnim extends StatefulWidget {
  const _HowToRecordAnim();
  @override State<_HowToRecordAnim> createState() => _HowToRecordAnimState();
}
class _HowToRecordAnimState extends State<_HowToRecordAnim> with TickerProviderStateMixin {
  late AnimationController _blink, _step; int _cs=0;
  @override void initState() { super.initState();
    _blink=AnimationController(vsync:this,duration:900.ms)..repeat(reverse:true);
    _step=AnimationController(vsync:this,duration:2400.ms)
      ..addStatusListener((s){if(s==AnimationStatus.completed&&mounted){setState(()=>_cs=(_cs+1)%3);_step.reset();_step.forward();}});
    _step.forward();
  }
  @override void dispose() { _blink.dispose(); _step.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation:_blink,
    builder:(_,__)=>CustomPaint(size:const Size(double.infinity,200),painter:_RecordPainter(blink:_blink.value,step:_cs)));
}
class _RecordPainter extends CustomPainter {
  final double blink; final int step;
  _RecordPainter({required this.blink,required this.step});
  static const _sc=[BM.accent,BM.warning,BM.primary];
  static const _sl=['Cuerpo visible','Buena iluminación','Cámara a cadera'];
  @override void paint(Canvas canvas, Size size) {
    final cx=size.width/2,cy=size.height/2+8; final c=_sc[step];
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(cx,cy),width:100,height:138),const Radius.circular(10)),
        Paint()..color=c.withOpacity(0.55+blink*0.45)..strokeWidth=2.5..style=PaintingStyle.stroke);
    const cL=12.0; final l=cx-50,r=cx+50,t=cy-69,b=cy+69;
    final cp=Paint()..color=c..strokeWidth=4..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    for(final pts in [[l,t+cL,l,t,l+cL,t],[r-cL,t,r,t,r,t+cL],[l,b-cL,l,b,l+cL,b],[r,b-cL,r,b,r-cL,b]]){
      canvas.drawLine(Offset(pts[0],pts[1]),Offset(pts[2],pts[3]),cp);
      canvas.drawLine(Offset(pts[2],pts[3]),Offset(pts[4],pts[5]),cp);
    }
    final sp=Paint()..color=Colors.white.withOpacity(0.22)..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    canvas.drawCircle(Offset(cx,cy-50),9,Paint()..color=Colors.white.withOpacity(0.2)..style=PaintingStyle.fill);
    canvas.drawLine(Offset(cx,cy-41),Offset(cx,cy-14),sp);
    canvas.drawLine(Offset(cx-13,cy-33),Offset(cx+13,cy-33),sp);
    canvas.drawLine(Offset(cx-13,cy-14),Offset(cx-16,cy+28),sp);
    canvas.drawLine(Offset(cx+13,cy-14),Offset(cx+16,cy+28),sp);
    if(step==1){
      canvas.drawCircle(Offset(l-22,t+22),11,Paint()..color=BM.warning..style=PaintingStyle.fill);
      for(int i=0;i<8;i++){final a=i*math.pi/4;canvas.drawLine(Offset(l-22+math.cos(a)*14,t+22+math.sin(a)*14),Offset(l-22+math.cos(a)*19,t+22+math.sin(a)*19),Paint()..color=BM.warning.withOpacity(0.55)..strokeWidth=2..style=PaintingStyle.stroke);}
    } else if(step==2){
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(r+24,cy),width:26,height:18),const Radius.circular(4)),Paint()..color=BM.primary.withOpacity(0.8)..style=PaintingStyle.fill);
      canvas.drawCircle(Offset(r+24,cy),5,Paint()..color=BM.bg..style=PaintingStyle.fill);
      canvas.drawCircle(Offset(r+24,cy),3.5,Paint()..color=BM.primaryLt..style=PaintingStyle.fill);
    }
    _t(canvas,_sl[step],cx,b+14,c,11);
    for(int i=0;i<3;i++) canvas.drawCircle(Offset(cx-22+i*22.0,t-16),i==step?5:3.5,Paint()..color=i==step?_sc[i]:BM.elevated..style=PaintingStyle.fill);
  }
  void _t(Canvas c,String t,double x,double y,Color col,double sz){final tp=TextPainter(text:TextSpan(text:t,style:TextStyle(color:col,fontSize:sz,fontWeight:FontWeight.w600)),textDirection:TextDirection.ltr)..layout();tp.paint(c,Offset(x-tp.width/2,y));}
  @override bool shouldRepaint(_RecordPainter o)=>o.blink!=blink||o.step!=step;
}

// ── Data Form ──────────────────────────────────────────────────────────────
class _DataFormView extends StatelessWidget {
  final OnboardingViewModel vm; final TextEditingController hCtrl, wCtrl, aCtrl;
  const _DataFormView({required this.vm, required this.hCtrl, required this.wCtrl, required this.aCtrl});

  Widget _fieldError(String? msg) {
    if (msg == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: BM.error, size: 12),
        const SizedBox(width: 4),
        Text(msg, style: const TextStyle(color: BM.error, fontSize: 11)),
      ]));
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tus datos físicos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text('Mejoran la precisión del análisis y el cálculo de tu 1RM estimado.',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
          ])),
        ])).animate().fadeIn(),
      const SizedBox(height: 18),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(controller: hCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: BM.textPrimary), onChanged: vm.setHeight,
              decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm',
                  prefixIcon: Icon(Icons.height_rounded, size: 20))),
          _fieldError(vm.heightError),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(controller: wCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: BM.textPrimary), onChanged: vm.setWeight,
              decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20))),
          _fieldError(vm.weightError),
        ])),
      ]).animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(controller: aCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: BM.textPrimary), onChanged: vm.setAge,
            decoration: const InputDecoration(labelText: 'Edad', suffixText: 'años',
                prefixIcon: Icon(Icons.cake_outlined, size: 20))),
        _fieldError(vm.ageError),
      ]).animate().fadeIn(delay: 130.ms),
      const SizedBox(height: 12),
      Row(children: [
        _SexChip(label: 'Masculino', sel: vm.sex=='male',   onTap: ()=>vm.setSex('male')),
        const SizedBox(width: 10),
        _SexChip(label: 'Femenino',  sel: vm.sex=='female', onTap: ()=>vm.setSex('female')),
      ]).animate().fadeIn(delay: 180.ms),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Años entrenando', style: TextStyle(fontSize: 13, color: BM.textSecondary)),
        Text('${vm.years.toStringAsFixed(1)} años', style: const TextStyle(color: BM.primary, fontWeight: FontWeight.w600, fontSize: 13)),
      ]).animate().fadeIn(delay: 210.ms),
      Slider(value: vm.years, min: 0, max: 20, divisions: 40, activeColor: BM.primary, inactiveColor: BM.elevated, onChanged: vm.setYears).animate().fadeIn(delay: 230.ms),
      Container(padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: BM.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: BM.primary.withOpacity(0.15))),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_rounded, color: BM.primary, size: 14), SizedBox(width: 8),
          Expanded(child: Text('Opcional. Con estos datos el sistema calibra los cálculos de fuerza y adapta el análisis biomecánico a tu morfología.',
              style: TextStyle(color: BM.textSecondary, fontSize: 11, height: 1.5))),
        ])).animate().fadeIn(delay: 270.ms),
      const SizedBox(height: 18),
    ]),
  );
}

class _SexChip extends StatelessWidget {
  final String label; final bool sel; final VoidCallback onTap;
  const _SexChip({required this.label, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: 180.ms, padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(color: sel?BM.primary.withOpacity(0.12):BM.card, borderRadius: BorderRadius.circular(11),
          border: Border.all(color: sel?BM.primary:BM.elevated, width: sel?1.5:1)),
      child: Center(child: Text(label, style: TextStyle(color: sel?BM.primary:BM.textSecondary, fontSize: 13, fontWeight: sel?FontWeight.w600:FontWeight.w400))))));
}
