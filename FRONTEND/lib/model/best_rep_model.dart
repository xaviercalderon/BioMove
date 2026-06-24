// model/best_rep_model.dart
class BestRepModel {
  final String id, repType;
  final double repScore;
  final double? kneeAngle, valgus, eccentricDur, aclRisk, weightKg;
  final String? clipUrl, clipPath, recordedAt;
  final Map<String, dynamic> params;

  const BestRepModel({
    required this.id, required this.repType, required this.repScore,
    this.kneeAngle, this.valgus, this.eccentricDur, this.aclRisk,
    this.weightKg, this.clipUrl, this.clipPath, this.recordedAt,
    this.params = const {},
  });

  factory BestRepModel.fromJson(Map<String, dynamic> j) {
    final p = j['params_json'] as Map? ?? {};
    return BestRepModel(
      id:           j['id'] ?? '',
      repType:      j['rep_type'] ?? 'best',
      repScore:     (j['rep_score'] as num?)?.toDouble() ?? 0.0,
      kneeAngle:    (p['knee_angle_min'] as num?)?.toDouble(),
      valgus:       (p['left_valgus'] as num?)?.toDouble(),
      eccentricDur: (p['eccentric_duration_s'] as num?)?.toDouble(),
      aclRisk:      (p['acl_risk_score'] as num?)?.toDouble(),
      weightKg:     (j['weight_kg'] as num?)?.toDouble(),
      clipUrl:      j['clip_url'],
      clipPath:     j['clip_path'],
      recordedAt:   j['recorded_at'] != null
          ? _formatDate(j['recorded_at'].toString()) : null,
      params:       Map<String, dynamic>.from(p),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return iso; }
  }
}
