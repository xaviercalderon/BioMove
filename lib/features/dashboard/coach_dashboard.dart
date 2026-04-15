import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/widgets.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});
  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  final _api = ApiClient();
  List<dynamic> _athletes = [];
  bool _loading = true;
  String? _generatedCode;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final athletes = await _api.getMyAthletes();
      if (mounted) setState(() { _athletes = athletes; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: BM.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true, backgroundColor: BM.bg,
          title: const Text('Panel del Entrenador', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(icon: const Icon(Icons.person_rounded), onPressed: () => context.go('/profile')),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: BM.gradCoach, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.white.withOpacity(0.15),
                    child: Text(auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Entrenador ${auth.displayName.split(' ').first}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('${_athletes.length} atletas vinculados',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ])),
                RoleBadge(role: auth.role),
              ]),
            ).animate().fadeIn(),
            const SizedBox(height: 20),

            // Generate invite code
            SectionHeader(title: 'Vincular atleta'),
            const SizedBox(height: 12),
            if (_generatedCode != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: BM.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BM.accent.withOpacity(0.4))),
                child: Column(children: [
                  const Text('Código de invitación generado', style: TextStyle(color: BM.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(_generatedCode!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                      color: BM.accent, letterSpacing: 6)),
                  const SizedBox(height: 6),
                  const Text('Válido por 7 días — el atleta lo ingresa en su app',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: BM.textSecondary)),
                ]),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 10),
            ],
            GBtn(
              text: _generatedCode == null ? 'Generar código de invitación' : 'Nuevo código',
              icon: Icons.link_rounded,
              colors: const [BM.accentDk, Color(0xFF005C45)],
              height: 50,
              onTap: () async {
                try {
                  final code = await _api.generateInviteCode();
                  if (mounted) setState(() => _generatedCode = code);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')));
                }
              },
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Athletes list
            SectionHeader(title: 'Mis atletas (${_athletes.length})'),
            const SizedBox(height: 12),

            if (_loading)
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BioShimmer(width: double.infinity, height: 80, radius: 16)))
            else if (_athletes.isEmpty)
              GlassCard(child: Column(children: [
                const Icon(Icons.group_outlined, color: BM.textHint, size: 44),
                const SizedBox(height: 12),
                const Text('Sin atletas vinculados', style: TextStyle(color: BM.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Genera un código y compártelo con tus atletas',
                    textAlign: TextAlign.center, style: TextStyle(color: BM.textSecondary, fontSize: 13)),
              ]))
            else
              ..._athletes.asMap().entries.map((e) {
                final a = e.value as Map<String, dynamic>;
                final score = (a['last_score'] as num?)?.toDouble();
                final lastDate = a['last_session_date'] != null
                    ? DateFormat('d MMM').format(DateTime.parse(a['last_session_date']))
                    : 'Sin sesiones';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: BM.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onTap: () => context.go('/coach/athlete/${a['id']}'),
                    leading: CircleAvatar(
                      backgroundColor: BM.accent.withOpacity(0.15),
                      child: Text((a['display_name'] as String? ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(color: BM.accent, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(a['display_name'] ?? 'Atleta',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: BM.textPrimary)),
                    subtitle: Text(lastDate, style: const TextStyle(fontSize: 12, color: BM.textSecondary)),
                    trailing: score != null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(score.toStringAsFixed(0),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BM.scoreColor(score))),
                            const Text('/100', style: TextStyle(fontSize: 10, color: BM.textHint)),
                          ])
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: BM.textHint),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60));
              }),
          ])),
        ),
      ]),
    );
  }
}
