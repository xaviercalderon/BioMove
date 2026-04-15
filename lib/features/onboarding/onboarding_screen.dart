import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Datos físicos
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String _sex       = 'male';
  double _years     = 1.0;
  bool _saving      = false;

  @override
  void dispose() {
    _pageCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _ageCtrl.dispose();
    super.dispose();
  }

  static const _slides = [
    ('🏋️', 'Análisis biomecánico', 'Detectamos 33 puntos articulares en cada frame de tu video para calcular 40 parámetros de movimiento con precisión científica.'),
    ('🧠', 'IA personal que aprende', 'El sistema aprende tu morfología y rangos de movimiento individuales. Con el tiempo, los análisis se personalizan para ti.'),
    ('📊', 'Feedback accionable', 'No solo scores — explicaciones claras de qué mejorar, por qué es importante y qué ejercicios correctivos hacer.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    body: SafeArea(
      child: Column(children: [
        // Indicator
        Padding(
          padding: const EdgeInsets.only(top: 20, right: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (_page < _slides.length)
              GestureDetector(onTap: _skipToForm,
                  child: const Text('Saltar', style: TextStyle(color: BM.primary, fontSize: 14, fontWeight: FontWeight.w500))),
          ]),
        ),

        Expanded(
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              ..._slides.map((s) => _SlidePage(emoji: s.$1, title: s.$2, body: s.$3)),
              _DataForm(heightCtrl: _heightCtrl, weightCtrl: _weightCtrl, ageCtrl: _ageCtrl,
                  sex: _sex, years: _years, onSexChanged: (v) => setState(() => _sex=v),
                  onYearsChanged: (v) => setState(() => _years=v)),
            ],
          ),
        ),

        // Bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(children: [
            if (_page < _slides.length)
              SmoothPageIndicator(controller: _pageCtrl, count: _slides.length+1,
                  effect: WormEffect(activeDotColor: BM.primary, dotColor: BM.elevated,
                      dotHeight: 8, dotWidth: 8))
            else const SizedBox.shrink(),
            const SizedBox(height: 20),
            if (_page < _slides.length)
              GBtn(text: 'Siguiente', icon: Icons.arrow_forward_rounded, onTap: () {
                _pageCtrl.nextPage(duration: 400.ms, curve: Curves.easeInOut);
              })
            else
              Consumer<AuthProvider>(builder: (_, auth, __) =>
                GBtn(text: 'Comenzar', icon: Icons.check_rounded,
                    loading: _saving,
                    onTap: _saving ? null : () => _save(auth))
              ),
            const SizedBox(height: 12),
            if (_page == _slides.length)
              GestureDetector(
                onTap: _skipSave,
                child: const Text('Completar después', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
              ),
          ]),
        ),
      ]),
    ),
  );

  void _skipToForm() {
    _pageCtrl.animateToPage(_slides.length, duration: 400.ms, curve: Curves.easeInOut);
  }

  Future<void> _save(AuthProvider auth) async {
    if (_heightCtrl.text.isEmpty || _weightCtrl.text.isEmpty || _ageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
      return;
    }
    setState(() => _saving = true);
    final ok = await auth.savePhysicalData(
      h: double.parse(_heightCtrl.text), w: double.parse(_weightCtrl.text),
      age: int.parse(_ageCtrl.text), sex: _sex, years: _years,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (ok) _navigate(auth);
    }
  }

  Future<void> _skipSave() async {
    final auth = context.read<AuthProvider>();
    try { await auth.refreshProfile(); } catch (_) {}
    if (mounted) _navigate(auth);
  }

  void _navigate(AuthProvider auth) {
    switch (auth.role) {
      case 'admin': context.go('/admin'); break;
      case 'coach': context.go('/coach'); break;
      default:      context.go('/dashboard');
    }
  }
}

class _SlidePage extends StatelessWidget {
  final String emoji, title, body;
  const _SlidePage({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 36),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 72)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 28),
      Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: BM.textPrimary))
          .animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 14),
      Text(body, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: BM.textSecondary, height: 1.6))
          .animate().fadeIn(delay: 250.ms),
    ]),
  );
}

class _DataForm extends StatelessWidget {
  final TextEditingController heightCtrl, weightCtrl, ageCtrl;
  final String sex;
  final double years;
  final void Function(String) onSexChanged;
  final void Function(double) onYearsChanged;

  const _DataForm({required this.heightCtrl, required this.weightCtrl, required this.ageCtrl,
      required this.sex, required this.years, required this.onSexChanged, required this.onYearsChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text('Datos físicos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BM.textPrimary))
          .animate().fadeIn(),
      const SizedBox(height: 6),
      const Text('Para cálculos más precisos de 1RM y análisis biomecánico',
          style: TextStyle(fontSize: 13, color: BM.textSecondary)).animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 24),

      Row(children: [
        Expanded(child: TextFormField(controller: heightCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: BM.textPrimary),
            decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm', prefixIcon: Icon(Icons.height_rounded, size: 20)))),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: weightCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: BM.textPrimary),
            decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20)))),
      ]).animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 14),
      TextFormField(controller: ageCtrl, keyboardType: TextInputType.number,
          style: const TextStyle(color: BM.textPrimary),
          decoration: const InputDecoration(labelText: 'Edad', suffixText: 'años', prefixIcon: Icon(Icons.cake_outlined, size: 20)))
          .animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 16),

      // Sexo
      Row(children: [
        _SexBtn(label: 'Masculino', value: 'male', selected: sex == 'male', onTap: () => onSexChanged('male')),
        const SizedBox(width: 10),
        _SexBtn(label: 'Femenino', value: 'female', selected: sex == 'female', onTap: () => onSexChanged('female')),
      ]).animate().fadeIn(delay: 250.ms),
      const SizedBox(height: 16),

      // Años entrenando
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Años entrenando', style: TextStyle(fontSize: 13, color: BM.textSecondary)),
        Text('${years.toStringAsFixed(1)} años', style: const TextStyle(color: BM.primary, fontWeight: FontWeight.w600)),
      ]).animate().fadeIn(delay: 300.ms),
      Slider(value: years, min: 0, max: 20, divisions: 40,
          activeColor: BM.primary, inactiveColor: BM.elevated,
          onChanged: onYearsChanged).animate().fadeIn(delay: 320.ms),
    ]),
  );
}

class _SexBtn extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _SexBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: 200.ms,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected ? BM.primary.withOpacity(0.12) : BM.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? BM.primary : BM.elevated, width: selected ? 1.5 : 1),
      ),
      child: Center(child: Text(label, style: TextStyle(color: selected ? BM.primary : BM.textSecondary,
          fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
    ),
  ));
}
