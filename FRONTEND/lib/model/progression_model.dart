// model/progression_model.dart
import 'package:intl/intl.dart';

class WeekModel {
  final int weekNumber;
  final String block, blockLabel, prescription;
  final int sets, reps;
  final double weightKg, pctOnerm, rpeTarget;
  final bool isDeload;
  final String? note, blockDescription;

  const WeekModel({
    required this.weekNumber, required this.block, required this.blockLabel,
    required this.prescription, required this.sets, required this.reps,
    required this.weightKg, required this.pctOnerm, required this.rpeTarget,
    this.isDeload = false, this.note, this.blockDescription,
  });

  factory WeekModel.fromJson(Map<String, dynamic> j) => WeekModel(
    weekNumber:       j['week_number'] ?? 1,
    block:            j['block'] ?? 'accumulation',
    blockLabel:       j['block_label'] ?? 'Acumulación',
    prescription:     j['prescription'] ?? '',
    sets:             j['sets'] ?? 4,
    reps:             j['reps'] ?? 5,
    weightKg:         (j['weight_kg'] as num?)?.toDouble() ?? 0.0,
    pctOnerm:         (j['pct_1rm'] as num?)?.toDouble() ?? 0.0,
    rpeTarget:        (j['rpe_target'] as num?)?.toDouble() ?? 7.0,
    isDeload:         j['is_deload'] ?? false,
    note:             j['note'],
    blockDescription: j['block_description'],
  );
}

class BlockModel {
  final String key, label, description;
  final List<WeekModel> weeks;
  const BlockModel({required this.key, required this.label,
      required this.description, required this.weeks});

  factory BlockModel.fromJson(Map<String, dynamic> j) => BlockModel(
    key:         j['key'] ?? '',
    label:       j['label'] ?? '',
    description: j['description'] ?? '',
    weeks: (j['weeks'] as List? ?? [])
        .map((w) => WeekModel.fromJson(w as Map<String, dynamic>))
        .toList(),
  );
}

class TrainingPlanModel {
  final String planId, exerciseType;
  final double oneRm;
  final int currentWeek, totalWeeks;
  final String currentBlock;
  final bool coachApproved;
  final String? coachNotes;
  final WeekModel? todaySession;
  final List<BlockModel> blocks;
  final List<WeekModel> allWeeks;

  const TrainingPlanModel({
    required this.planId, required this.exerciseType, required this.oneRm,
    required this.currentWeek, required this.totalWeeks, required this.currentBlock,
    required this.blocks, required this.allWeeks,
    this.coachApproved = false, this.coachNotes, this.todaySession,
  });

  factory TrainingPlanModel.fromJson(Map<String, dynamic> j) {
    final planData = j['plan'] as Map<String, dynamic>? ?? {};
    final blocksRaw = planData['blocks'] as List? ?? [];
    final weeksRaw  = planData['weeks']  as List? ?? [];
    final blocks = blocksRaw
        .map((b) => BlockModel.fromJson(b as Map<String, dynamic>))
        .toList();
    final allWeeks = weeksRaw
        .map((w) => WeekModel.fromJson(w as Map<String, dynamic>))
        .toList();
    final todayRaw = j['today_session'] as Map<String, dynamic>?;
    return TrainingPlanModel(
      planId:        j['plan_id'] ?? '',
      exerciseType:  j['exercise_type'] ?? 'squat',
      oneRm:         (j['one_rm'] as num?)?.toDouble() ?? 0.0,
      currentWeek:   j['current_week'] ?? 1,
      totalWeeks:    j['total_weeks'] ?? 11,
      currentBlock:  j['current_block'] ?? 'accumulation',
      coachApproved: j['coach_approved'] ?? false,
      coachNotes:    j['coach_notes'],
      todaySession:  todayRaw != null ? WeekModel.fromJson(todayRaw) : null,
      blocks:        blocks,
      allWeeks:      allWeeks,
    );
  }
}

class StrengthRecordModel {
  final String id;
  final double weightKg, oneRmAverage;
  final int reps;
  final DateTime recordedAt;

  const StrengthRecordModel({required this.id, required this.weightKg,
      required this.oneRmAverage, required this.reps, required this.recordedAt});

  factory StrengthRecordModel.fromJson(Map<String, dynamic> j) =>
      StrengthRecordModel(
        id:           j['id'] ?? '',
        weightKg:     (j['weight_kg'] as num?)?.toDouble() ?? 0.0,
        oneRmAverage: (j['one_rm_average'] as num?)?.toDouble() ?? 0.0,
        reps:         j['reps'] ?? 0,
        recordedAt:   j['recorded_at'] != null
            ? DateTime.tryParse(j['recorded_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  String get formattedDate =>
      DateFormat("d MMM yyyy", 'es').format(recordedAt);
}

class VBTResultModel {
  final double rpe, velocity;
  final int pctOnerm;
  final String label, recommendation;
  final String adjustment;
  final double nextWeight;

  const VBTResultModel({required this.rpe, required this.velocity,
      required this.pctOnerm, required this.label, required this.recommendation,
      required this.adjustment, required this.nextWeight});

  factory VBTResultModel.fromJson(Map<String, dynamic> j) {
    final vbt = j['vbt_result'] as Map<String, dynamic>? ?? {};
    final adj = j['adjustment'] as Map<String, dynamic>? ?? {};
    return VBTResultModel(
      rpe:            (vbt['rpe'] as num?)?.toDouble() ?? 0.0,
      velocity:       (vbt['velocity_ms'] as num?)?.toDouble() ?? 0.0,
      pctOnerm:       (vbt['pct_1rm'] as num?)?.toInt() ?? 0,
      label:          vbt['label'] ?? '',
      recommendation: vbt['recommendation'] ?? '',
      adjustment:     adj['message'] ?? '',
      nextWeight:     (adj['next_weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
