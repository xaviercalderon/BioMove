// lib/features/screens.dart — History, Calculator, Profile, Settings, AIModel,
// Achievements, Live, AthleteDetail, AdminDashboard, AdminUsers, AdminModel
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/theme.dart';
import '../core/utils/widgets.dart';
import '../core/utils/constants.dart';
import '../core/models/models.dart';
import '../core/api/api_client.dart';
import '../core/providers/auth_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HISTORY
// ══════════════════════════════════════════════════════════════════════════════
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiClient();
  List<WorkoutSummary> _items = [];
  bool _loading = true;
  String? _filter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() { _items = []; });
    setState(() => _loading = true);
    try {
      final data = await _api.getWorkouts(page: 1, exerciseType: _filter);
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Historial'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/dashboard')),
    ),
    body: Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _Chip('Todos', _filter == null, () { setState(() => _filter = null); _load(reset: true); }),
          const SizedBox(width: 8),
          ...[('Sentadilla','squat'),('Peso muerto','deadlift'),('Press banca','bench_press')]
              .map((e) => Padding(padding: const EdgeInsets.only(right: 8),
                  child: _Chip(e.$1, _filter == e.$2, () { setState(() => _filter = e.$2); _load(reset: true); }))),
        ]),
      ),
      Expanded(
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator(color: BM.primary))
            : _items.isEmpty
              ? const Center(child: Text('Sin sesiones', style: TextStyle(color: BM.textSecondary)))
              : RefreshIndicator(color: BM.primary, onRefresh: () => _load(reset: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: _items.length,
                    itemBuilder: (_, i) => _HistoryTile(item: _items[i])
                        .animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                  )),
      ),
    ]),
    bottomNavigationBar: BioBottomNav(current: 2, onTap: (i) {
      switch(i) { case 0: context.go('/dashboard'); break; case 3: context.go('/calculator'); break; case 4: context.go('/profile'); break; }
    }),
  );

  Widget _Chip(String l, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: 180.ms,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: active ? BM.primary : BM.card, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? BM.primary : Colors.white.withOpacity(0.08))),
      child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: active ? Colors.white : BM.textSecondary))),
  );
}

class _HistoryTile extends StatelessWidget {
  final WorkoutSummary item;
  const _HistoryTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final ex = ExerciseInfo.fromId(item.exerciseType);
    final c  = BM.scoreColor(item.techniqueScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(ex.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: BM.textPrimary)),
            if (item.classifierEnabled) ...[const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: BM.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text('IA', style: TextStyle(fontSize: 9, color: BM.accent, fontWeight: FontWeight.w700)))],
          ]),
          Text(DateFormat('EEEE d MMM yyyy', 'es').format(item.sessionDate),
              style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
          Text('${item.totalSets}×${item.totalReps} reps${item.weightKg != null ? ' · ${item.weightKg!.toStringAsFixed(0)} kg' : ''}',
              style: const TextStyle(fontSize: 12, color: BM.textHint)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${item.techniqueScore.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c)),
          const Text('/100', style: TextStyle(fontSize: 10, color: BM.textHint)),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CALCULATOR
// ══════════════════════════════════════════════════════════════════════════════
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _api = ApiClient();
  final _wCtrl = TextEditingController();
  final _rCtrl = TextEditingController();
  String _exercise = 'squat';
  OneRMResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _wCtrl.dispose(); _rCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(title: const Text('Calculadora 1RM')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
            SizedBox(height: 10),
            Text('Calcula tu 1RM', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Fórmulas Epley (1985) y Brzycki (1993) — las más validadas en la literatura de fuerza.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          ])).animate().fadeIn(),
        const SizedBox(height: 24),

        const SectionHeader(title: 'Ejercicio'),
        const SizedBox(height: 10),
        ...ExerciseInfo.all.map((ex) => GestureDetector(
          onTap: () => setState(() { _exercise = ex.id; _result = null; }),
          child: AnimatedContainer(duration: 150.ms,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _exercise==ex.id ? BM.primary.withOpacity(0.1) : BM.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _exercise==ex.id ? BM.primary : Colors.white.withOpacity(0.05), width: _exercise==ex.id ? 1.5 : 1),
            ),
            child: Row(children: [
              Text(ex.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(ex.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: _exercise==ex.id ? BM.primary : BM.textPrimary)),
              const Spacer(),
              if (_exercise==ex.id) const Icon(Icons.check_circle_rounded, color: BM.primary, size: 18),
            ]),
          ),
        )),
        const SizedBox(height: 20),

        Row(children: [
          Expanded(child: TextFormField(controller: _wCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: BM.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Peso kg', suffixText: 'kg'),
              onChanged: (_) => setState(() => _result = null))),
          const SizedBox(width: 14),
          Expanded(child: TextFormField(controller: _rCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: BM.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Reps', suffixText: 'reps'),
              onChanged: (_) => setState(() => _result = null))),
        ]),

        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: BM.error, fontSize: 13))),
        const SizedBox(height: 20),

        GBtn(text: 'Calcular 1RM', icon: Icons.calculate_rounded, loading: _loading, onTap: _calculate),

        if (_result != null) ...[
          const SizedBox(height: 28),
          GlassCard(borderColor: BM.primary.withOpacity(0.3), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('1RM estimado', style: TextStyle(color: BM.textSecondary, fontSize: 14)),
              ShaderMask(
                shaderCallback: (b) => BM.grad1.createShader(b),
                child: Text('${_result!.oneRmAverage.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _FormulaBox('Epley', _result!.oneRmEpley)),
              const SizedBox(width: 12),
              Expanded(child: _FormulaBox('Brzycki', _result!.oneRmBrzycki)),
            ]),
          ])).animate().fadeIn(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Tabla de equivalencias'),
          const SizedBox(height: 12),
          GlassCard(child: Column(children: _result!.equivalences.entries.take(9).map((e) {
            final data = e.value as Map<String, dynamic>;
            final weight = (data['weight_kg'] as num).toDouble();
            final reps   = data['approx_reps'] as int;
            final pct    = double.tryParse(e.key.replaceAll('%','')) ?? 0;
            return Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 46, child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BM.primary))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: pct/100, minHeight: 5, backgroundColor: BM.elevated,
                        valueColor: AlwaysStoppedAnimation(Color.lerp(BM.primary.withOpacity(0.5), BM.primary, pct/100)!)))),
                const SizedBox(width: 12),
                SizedBox(width: 72, child: Text('${weight.toStringAsFixed(1)} kg', textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BM.textPrimary))),
                SizedBox(width: 36, child: Text('×$reps', textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: BM.textHint))),
              ]),
            );
          }).toList())).animate().fadeIn(),
        ],
        const SizedBox(height: 40),
      ]),
    ),
    bottomNavigationBar: BioBottomNav(current: 3, onTap: (i) {
      switch(i) { case 0: context.go('/dashboard'); break; case 2: context.go('/history'); break; case 4: context.go('/profile'); break; }
    }),
  );

  Widget _FormulaBox(String label, double value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: BM.elevated, borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
      const SizedBox(height: 3),
      Text('${value.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: BM.textPrimary)),
    ]),
  );

  Future<void> _calculate() async {
    final w = double.tryParse(_wCtrl.text);
    final r = int.tryParse(_rCtrl.text);
    if (w == null || w <= 0) { setState(() => _error = 'Ingresa un peso válido'); return; }
    if (r == null || r <= 0 || r > 30) { setState(() => _error = 'Las reps deben ser entre 1 y 30'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.calculateOneRM(_exercise, w, r);
      if (mounted) setState(() { _result = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al calcular. Verifica tu conexión.'; _loading = false; });
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE
// ══════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Center(child: Column(children: [
            Container(width: 88, height: 88,
                decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Center(child: Text(auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)))),
            const SizedBox(height: 14),
            Text(auth.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BM.textPrimary)),
            const SizedBox(height: 4),
            Text(auth.user?.email ?? '', style: const TextStyle(fontSize: 13, color: BM.textSecondary)),
            const SizedBox(height: 8),
            RoleBadge(role: auth.role),
          ])),
          const SizedBox(height: 28),

          if (auth.user?.hasPhysicalData == true && auth.user?.heightCm != null) ...[
            const SectionHeader(title: 'Datos físicos'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: MetricCard(label: 'Altura', value: auth.user!.heightCm!.toStringAsFixed(0), unit: 'cm',
                  icon: Icons.height_rounded, color: BM.accent)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Peso', value: auth.user!.weightKg!.toStringAsFixed(0), unit: 'kg',
                  icon: Icons.monitor_weight_outlined, color: BM.primary)),
            ]),
            const SizedBox(height: 24),
          ],

          const SectionHeader(title: 'Configuración'),
          const SizedBox(height: 12),
          ...[
            (Icons.tune_rounded, 'Funciones opcionales', '/settings'),
            (Icons.psychology_rounded, 'Modelo IA personal', '/ai_model'),
            (Icons.history_rounded, 'Historial de sesiones', '/history'),
            (Icons.emoji_events_rounded, 'Mis logros', '/achievements'),
            if (auth.isCoach || auth.isAdmin) (Icons.people_rounded, 'Panel de entrenador', '/coach'),
            if (auth.isAdmin) (Icons.admin_panel_settings_rounded, 'Panel de administrador', '/admin'),
          ].map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: BM.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onTap: () => context.go(e.$3),
              leading: Icon(e.$1, color: BM.textSecondary, size: 20),
              title: Text(e.$2, style: const TextStyle(fontSize: 15, color: BM.textPrimary)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: BM.textHint, size: 14),
            ),
          )),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () async { await auth.signOut(); if (context.mounted) context.go('/login'); },
            child: Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: BM.error.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BM.error.withOpacity(0.2))),
                child: const Row(children: [
                  Icon(Icons.logout_rounded, color: BM.error, size: 20),
                  SizedBox(width: 14),
                  Text('Cerrar sesión', style: TextStyle(color: BM.error, fontSize: 15, fontWeight: FontWeight.w500)),
                ])),
          ),
          const SizedBox(height: 16),
          const Text('BioMove v4.0.0 · 40 parámetros biomecánicos', style: TextStyle(fontSize: 11, color: BM.textHint)),
          const SizedBox(height: 40),
        ]),
      ),
      bottomNavigationBar: BioBottomNav(current: 4, onTap: (i) {
        switch(i) { case 0: context.go('/dashboard'); break; case 2: context.go('/history'); break; case 3: context.go('/calculator'); break; }
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS
// ══════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _features = [
    ('feat_live_camera',     '📷', 'Cámara en tiempo real',    'Análisis LIVE mientras entrenas',         true),
    ('feat_fatigue',         '😓', 'Detección de fatiga',       'Compara técnica rep 1 vs rep N',          false),
    ('feat_achievements',    '🏅', 'Logros y badges',           'Sistema de gamificación',                 false),
    ('feat_coach',           '👨‍🏫','Modo entrenador',            'Gestiona análisis de atletas',           false),
    ('feat_weekly_plan',     '📅', 'Plan semanal IA',           'Programa personalizado automático',       false),
    ('feat_pdf_export',      '📄', 'Exportar PDF',              'Reporte de sesión descargable',           false),
    ('feat_push_notif',      '🔔', 'Notificaciones push',       'Alertas cuando termina el análisis',      false),
    ('feat_ai_model',        '🧠', 'Modelo IA personal',        'Aprende tu técnica individual',           false),
    ('feat_injury_risk',     '⚠️', 'Predicción de riesgo',     'Score de riesgo LCA y lumbar',            false),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final api  = ApiClient();
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Funciones opcionales'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/profile')),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: BM.gradHero, borderRadius: BorderRadius.circular(18)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              SizedBox(height: 8),
              Text('Activa solo lo que necesitas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              Text('Las funciones marcadas consumen más batería.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            ])),
        const SizedBox(height: 20),
        ..._features.asMap().entries.map((e) {
          final f = e.value;
          final enabled = auth.user?.featureEnabled(f.$1) ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? BM.primary.withOpacity(0.06) : BM.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: enabled ? BM.primary.withOpacity(0.25) : Colors.white.withOpacity(0.04)),
            ),
            child: Row(children: [
              Text(f.$2, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(f.$3, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                  if (f.$5) ...[const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: BM.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Alta CPU', style: TextStyle(fontSize: 9, color: BM.warning, fontWeight: FontWeight.w700)))],
                ]),
                Text(f.$4, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
              ])),
              Switch(
                value: enabled,
                onChanged: auth.user != null ? (v) async {
                  final features = Map<String, dynamic>.from(auth.user!.features as Map<dynamic, dynamic>);
                  features[f.$1] = v;
                  await api.updateMe({'features': features});
                  await auth.refreshProfile();
                } : null,
              ),
            ]),
          ).animate().fadeIn(delay: Duration(milliseconds: e.key * 40));
        }),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI MODEL SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class AIModelScreen extends StatefulWidget {
  const AIModelScreen({super.key});
  @override
  State<AIModelScreen> createState() => _AIModelScreenState();
}

class _AIModelScreenState extends State<AIModelScreen> {
  final _api = ApiClient();
  AIModelState? _model;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final m = await _api.getAIModel();
      if (mounted) setState(() { _model = m; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Modelo IA personal'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/dashboard')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : RefreshIndicator(color: BM.primary, onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (_model != null) ...[
                // Phase card
                GlassCard(borderColor: BM.primary.withOpacity(0.3), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_model!.phaseEmoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_model!.phase.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: BM.primary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        Text(_model!.phaseMessage, style: const TextStyle(fontSize: 13, color: BM.textPrimary, height: 1.4)),
                      ])),
                    ]),
                    const SizedBox(height: 14),
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: _model!.progress, minHeight: 8,
                            backgroundColor: BM.elevated, valueColor: const AlwaysStoppedAnimation(BM.primary))),
                    const SizedBox(height: 6),
                    Text(_model!.nextMilestone, style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
                  ],
                )).animate().fadeIn(),
                const SizedBox(height: 16),

                // Classifier info
                if (_model!.classifierReady) ...[
                  Container(padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BM.accent.withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome_rounded, color: BM.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Clasificador activo — v${_model!.classifierVersion}',
                              style: const TextStyle(color: BM.accent, fontWeight: FontWeight.w600, fontSize: 14)),
                          const Text('Modelo entrenado por el administrador', style: TextStyle(fontSize: 12, color: BM.textSecondary)),
                        ])),
                      ])).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                ],

                // Stats
                Row(children: [
                  Expanded(child: MetricCard(label: 'Reps totales', value: '${_model!.totalReps}', icon: Icons.repeat_rounded, color: BM.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(label: 'Sesiones', value: '${_model!.totalSessions}', icon: Icons.calendar_today_rounded, color: BM.accent)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(label: 'Baseline', value: '${_model!.baselineReps}', icon: Icons.fitness_center_rounded, color: BM.warning)),
                ]),
                const SizedBox(height: 20),

                // Morphology
                if (_model!.morphology.isNotEmpty) ...[
                  const SectionHeader(title: '🧬 Tu morfología (inferida)'),
                  const SizedBox(height: 10),
                  GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: _model!.morphology.entries
                          .where((e) => e.key.endsWith('_note'))
                          .map((e) => Padding(padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Icon(Icons.info_rounded, color: BM.accent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12, color: BM.textPrimary, height: 1.4))),
                              ]))).toList())),
                  const SizedBox(height: 20),
                ],

                // Recommendations
                if (_model!.recommendations.isNotEmpty) ...[
                  const SectionHeader(title: '🎯 Recomendaciones personales'),
                  const SizedBox(height: 10),
                  ..._model!.recommendations.asMap().entries.map((e) {
                    final r = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['title']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                        const SizedBox(height: 4),
                        Text(r['message']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: BM.textSecondary, height: 1.4)),
                      ]),
                    ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80));
                  }),
                ],

                if (!_model!.isActive) Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: BM.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BM.primary.withOpacity(0.2))),
                  child: const Text(
                    '💡 Para activar el modelo IA necesitas al menos 40 repeticiones con peso leve (≤50% de tu 1RM). Entrena con cargas ligeras enfocándote en la técnica perfecta.',
                    style: TextStyle(color: BM.primary, fontSize: 13, height: 1.5))),
              ] else
                const Center(child: Text('Sin datos del modelo. Sube tu primer video.',
                    style: TextStyle(color: BM.textSecondary))),
              const SizedBox(height: 40),
            ])),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENTS
// ══════════════════════════════════════════════════════════════════════════════
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _achievements = [
    ('Primera repetición', '🎯', 'Sube tu primer video de análisis', false),
    ('10 sesiones', '💪', 'Realiza 10 sesiones de análisis', false),
    ('Técnica perfecta', '⭐', 'Obtén un score de 100', false),
    ('100 repeticiones', '🔢', 'Acumula 100 reps en el sistema', false),
    ('Sin valgo 5 sesiones', '🦵', 'Mantén valgo <5° durante 5 sesiones', false),
    ('Nuevo récord 1RM', '🏆', 'Supera tu mejor 1RM registrado', false),
    ('Modelo IA activo', '🧠', 'Alcanza la fase activa del modelo IA', false),
    ('7 días de racha', '🔥', 'Entrena 7 días consecutivos', false),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Logros'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/profile')),
    ),
    body: ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _achievements.length,
      itemBuilder: (_, i) {
        final a = _achievements[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: a.$4 ? BM.primary.withOpacity(0.08) : BM.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.$4 ? BM.primary.withOpacity(0.3) : Colors.white.withOpacity(0.04)),
          ),
          child: Row(children: [
            Text(a.$2, style: TextStyle(fontSize: 32, color: a.$4 ? null : const Color(0xFF303048))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: a.$4 ? BM.textPrimary : BM.textHint)),
              Text(a.$3, style: TextStyle(fontSize: 12, color: a.$4 ? BM.textSecondary : BM.textHint)),
            ])),
            a.$4 ? const Icon(Icons.check_circle_rounded, color: BM.primary, size: 22)
                 : const Icon(Icons.lock_rounded, color: BM.textHint, size: 18),
          ]),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
      },
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// LIVE
// ══════════════════════════════════════════════════════════════════════════════
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Análisis en vivo'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/dashboard')),
    ),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
            decoration: BoxDecoration(gradient: BM.grad1, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: BM.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))]),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 48))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 1200.ms),
        const SizedBox(height: 28),
        const Text('Análisis en tiempo real', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BM.textPrimary)),
        const SizedBox(height: 12),
        const Text('Esta función muestra los ángulos articulares en pantalla mientras entrenas, usando la cámara del dispositivo.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: BM.textSecondary, height: 1.6)),
        const SizedBox(height: 32),
        GBtn(text: 'Analizar video grabado', icon: Icons.videocam_rounded, height: 52, onTap: () => context.go('/capture')),
      ]),
    )),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ATHLETE DETAIL (for coach)
// ══════════════════════════════════════════════════════════════════════════════
class AthleteDetailScreen extends StatefulWidget {
  final String athleteId;
  const AthleteDetailScreen({super.key, required this.athleteId});
  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  final _api = ApiClient();
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final sessions = await _api.getAthleteSessions(widget.athleteId);
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Sesiones del atleta'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/coach')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : _sessions.isEmpty
          ? const Center(child: Text('Sin sesiones registradas', style: TextStyle(color: BM.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (_, i) {
                final s = _sessions[i] as Map<String, dynamic>;
                final score = (s['technique_score'] as num?)?.toDouble() ?? 0.0;
                final ex = ExerciseInfo.fromId(s['exercise_type'] ?? 'squat');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Text(ex.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ex.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                      Text('${s['total_reps'] ?? 0} reps${s['weight_kg'] != null ? ' · ${(s['weight_kg'] as num).toStringAsFixed(0)} kg' : ''}',
                          style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
                      if (s['coach_notes'] != null)
                        Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: BM.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(s['coach_notes'], style: const TextStyle(fontSize: 11, color: BM.accent))),
                    ])),
                    Text('${score.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: BM.scoreColor(score))),
                  ]),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
              },
            ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _api = ApiClient();
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await _api.getAdminDashboard();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: BM.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: BM.bg,
            title: const Text('Panel del Administrador'),
            actions: [
              IconButton(icon: const Icon(Icons.people_rounded), onPressed: () => context.go('/admin/users')),
              IconButton(icon: const Icon(Icons.psychology_rounded), onPressed: () => context.go('/admin/model')),
              IconButton(icon: const Icon(Icons.person_rounded), onPressed: () => context.go('/profile')),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: BM.gradAdmin,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: BM.warning, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin: ${auth.displayName}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              'Acceso total al sistema',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      const RoleBadge(role: 'admin'),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                _loading
                    ? GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                        (_) => BioShimmer(width: double.infinity, height: 90, radius: 16),
                  ),
                )
                    : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    MetricCard(
                      label: 'Usuarios',
                      value: '${_data['total_users'] ?? 0}',
                      icon: Icons.people_rounded,
                      color: BM.primary,
                      animDelay: 0,
                    ),
                    MetricCard(
                      label: 'Atletas',
                      value: '${_data['total_athletes'] ?? 0}',
                      icon: Icons.fitness_center_rounded,
                      color: BM.accent,
                      animDelay: 60,
                    ),
                    MetricCard(
                      label: 'Coaches',
                      value: '${_data['total_coaches'] ?? 0}',
                      icon: Icons.school_rounded,
                      color: BM.warning,
                      animDelay: 120,
                    ),
                    MetricCard(
                      label: 'Sesiones',
                      value: '${_data['sessions_this_month'] ?? 0}',
                      icon: Icons.analytics_rounded,
                      color: BM.info,
                      animDelay: 180,
                    ),
                    ],
                ),

                const SizedBox(height: 20),

                // ✅ FIX AQUI (ANTES ERA ERROR)
                Builder(
                  builder: (context) {
                    final Map<String, dynamic> clf =
                        (_data['classifier'] as Map<String, dynamic>?) ?? {};

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BM.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (clf['ready'] == true ? BM.accent : BM.textHint).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            clf['ready'] == true
                                ? Icons.check_circle
                                : Icons.pending,
                            color: clf['ready'] == true ? BM.accent : BM.textHint,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clf['ready'] == true
                                      ? 'Clasificador activo — ${clf['version']}'
                                      : 'Sin clasificador',
                                ),
                                if (clf['ready'] == true)
                                  Text(
                                    '${clf['n_samples']} muestras · ${((clf['accuracy'] as num?) ?? 0).toDouble().toStringAsFixed(1)}%',
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/admin/model'),
                            child: const Text('Gestionar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// ADMIN USERS
// ══════════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _api = ApiClient();
  List<dynamic> _users = [];
  bool _loading = true;
  String? _roleFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await _api.getAdminUsers(
          role: _roleFilter,
          search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Gestión de usuarios'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/admin')),
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _searchCtrl,
            style: const TextStyle(color: BM.textPrimary),
            decoration: InputDecoration(hintText: 'Buscar por nombre o email',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(icon: const Icon(Icons.search_rounded), onPressed: _load)),
            onSubmitted: (_) => _load()),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final role in ['Todos','athlete','coach','admin'])
            Padding(padding: const EdgeInsets.only(right: 8),
              child: _RoleChip(role, _roleFilter == (role == 'Todos' ? null : role), () {
                setState(() => _roleFilter = role == 'Todos' ? null : role);
                _load();
              })),
        ])),
      ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _users.length,
            itemBuilder: (_, i) {
              final u = _users[i] as Map<String, dynamic>;
              final suspended = u['is_suspended'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: suspended ? BM.error.withOpacity(0.3) : Colors.white.withOpacity(0.04))),
                child: Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: BM.primary.withOpacity(0.15),
                      child: Text((u['display_name'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: BM.primary, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(u['display_name'] ?? 'Usuario',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BM.textPrimary)),
                      const SizedBox(width: 6),
                      RoleBadge(role: u['role'] ?? 'athlete'),
                      if (suspended) ...[const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: BM.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Suspendido', style: TextStyle(fontSize: 9, color: BM.error, fontWeight: FontWeight.w700)))],
                    ]),
                    Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: BM.textSecondary)),
                  ])),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: BM.textHint, size: 20),
                    color: BM.card,
                    onSelected: (action) => _doAction(u['id'], action, u['role']),
                    itemBuilder: (_) => [
                      if (!suspended) const PopupMenuItem(value: 'suspend', child: Text('Suspender', style: TextStyle(color: BM.warning))),
                      if (suspended) const PopupMenuItem(value: 'unsuspend', child: Text('Activar', style: TextStyle(color: BM.accent))),
                      if (u['role'] == 'athlete') const PopupMenuItem(value: 'to_coach', child: Text('Hacer coach', style: TextStyle(color: BM.primary))),
                      if (u['role'] == 'coach') const PopupMenuItem(value: 'to_athlete', child: Text('Hacer atleta', style: TextStyle(color: BM.primary))),
                      const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: BM.error))),
                    ],
                  ),
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
            }),
      ),
    ]),
  );

  Widget _RoleChip(String l, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: 150.ms,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: active ? BM.warning.withOpacity(0.15) : BM.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? BM.warning : Colors.white.withOpacity(0.08))),
      child: Text(l, style: TextStyle(fontSize: 12, color: active ? BM.warning : BM.textSecondary, fontWeight: FontWeight.w500))),
  );

  Future<void> _doAction(String userId, String action, String role) async {
    try {
      if (action == 'delete') {
        final ok = await showDialog<bool>(context: context,
            builder: (_) => AlertDialog(backgroundColor: BM.card,
              title: const Text('Eliminar usuario', style: TextStyle(color: BM.textPrimary)),
              content: const Text('¿Estás seguro? Esta acción no se puede deshacer.',
                  style: TextStyle(color: BM.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar', style: TextStyle(color: BM.error))),
              ]));
        if (ok != true) return;
        await _api.userAction(userId, 'delete');
      } else if (action == 'suspend') {
        await _api.userAction(userId, 'suspend');
      } else if (action == 'unsuspend') {
        await _api.userAction(userId, 'unsuspend');
      } else if (action == 'to_coach') {
        await _api.userAction(userId, 'change_role', value: 'coach');
      } else if (action == 'to_athlete') {
        await _api.userAction(userId, 'change_role', value: 'athlete');
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN MODEL
// ══════════════════════════════════════════════════════════════════════════════
class AdminModelScreen extends StatefulWidget {
  const AdminModelScreen({super.key});
  @override
  State<AdminModelScreen> createState() => _AdminModelScreenState();
}

class _AdminModelScreenState extends State<AdminModelScreen> {
  final _api = ApiClient();
  Map<String, dynamic> _info = {};
  bool _loading = true;
  String? _uploadMsg;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await _api.getClassifierInfo();
      if (mounted) setState(() { _info = info; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BM.bg,
    appBar: AppBar(
      title: const Text('Modelo Clasificador'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.go('/admin')),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: BM.primary))
        : ListView(padding: const EdgeInsets.all(20), children: [
            // Status
            GlassCard(borderColor: (_info['ready'] == true ? BM.accent : BM.textHint).withOpacity(0.3),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_info['ready'] == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _info['ready'] == true ? BM.accent : BM.textHint, size: 24),
                  const SizedBox(width: 10),
                  Text(_info['ready'] == true ? 'Modelo activo' : 'Sin modelo cargado',
                      style: TextStyle(color: _info['ready'] == true ? BM.accent : BM.textSecondary,
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
                if (_info['ready'] == true) ...[
                  const SizedBox(height: 12),
                  _InfoRow('Versión', _info['version']?.toString() ?? '—'),
                  _InfoRow('Muestras', '${_info['n_samples'] ?? 0} repeticiones'),
                  _InfoRow(
                    'Precisión',
                    '${(((_info['accuracy'] as num?)?.toDouble() ?? 0) * 100).toStringAsFixed(1)}%',
                  ),
                   _InfoRow('Features', '${_info['n_features'] ?? 0} parámetros'),
                ],
              ])).animate().fadeIn(),
            const SizedBox(height: 20),

            // Info de cómo subir
            Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: BM.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BM.primary.withOpacity(0.2))),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cómo actualizar el modelo', style: TextStyle(color: BM.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('1. Entrena en Jupyter: RandomForest con los 40 parámetros\n'
                       '2. Exporta: joblib.dump({model, scaler, version, n_samples, accuracy}, "squat_clf_v2.pkl")\n'
                       '3. Copia el .pkl a backend/models/\n'
                       '4. Reinicia el servidor — se carga automáticamente',
                      style: TextStyle(fontSize: 12, color: BM.textSecondary, height: 1.6)),
                ])).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Classes
            if (_info['ready'] == true && _info['classes'] != null) ...[
              const SectionHeader(title: 'Clases del modelo'),
              const SizedBox(height: 12),
              GlassCard(child: Column(children:
                ((_info['classes'] as List?) ?? []).asMap().entries.map((e) {
                  final colors = [BM.accent, const Color(0xFF69F0AE), BM.warning, BM.moderate, BM.error];
                  final c = colors[e.key % colors.length];
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(e.value.toString().toUpperCase(), style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
                    ]));
                }).toList())),
              const SizedBox(height: 20),
            ],

            if (_uploadMsg != null)
              Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: BM.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(_uploadMsg!, style: const TextStyle(color: BM.accent, fontSize: 13))),

            GBtn(text: 'Recargar estado del modelo', icon: Icons.refresh_rounded, height: 50,
                colors: const [BM.primary, BM.primaryDk],
                onTap: () async {
                  setState(() => _loading = true);
                  await _load();
                  if (mounted) setState(() => _uploadMsg = 'Estado actualizado');
                }),
            const SizedBox(height: 40),
          ]),
  );

  Widget _InfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: BM.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BM.textPrimary)),
    ]),
  );
}
