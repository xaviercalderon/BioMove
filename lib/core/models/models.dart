// lib/core/models/models.dart

class UserModel {
  final String id;
  final String? firebaseUid;
  final String email, displayName;
  final String? photoUrl, sex;
  final String role;
  final double? heightCm, weightKg, trainingYears;
  final int? age;
  final bool onboardingDone, hasPhysicalData;
  final Map<String, bool> features;

  const UserModel({required this.id, this.firebaseUid, required this.email,
      required this.displayName, this.photoUrl, this.role = 'athlete', this.heightCm,
      this.weightKg, this.age, this.sex, this.trainingYears,
      this.onboardingDone = false, this.hasPhysicalData = false, this.features = const {}});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? j['uid'] ?? '',
    firebaseUid: j['firebase_uid'],
    email: j['email'] ?? '',
    displayName: j['display_name'] ?? j['displayName'] ?? '',
    photoUrl: j['photo_url'] ?? j['photoURL'],
    role: j['role'] ?? 'athlete',
    heightCm: (j['height_cm'] as num?)?.toDouble(),
    weightKg: (j['weight_kg'] as num?)?.toDouble(),
    age: j['age'] as int?,
    sex: j['sex'],
    trainingYears: (j['training_years'] as num?)?.toDouble(),
    onboardingDone: j['onboarding_done'] ?? false,
    hasPhysicalData: j['has_physical_data'] ?? false,
    features: (j['features'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v == true)),
  );

  bool get isCoach   => role == 'coach';
  bool get isAdmin   => role == 'admin';
  bool get isAthlete => role == 'athlete';
  String get firstLetter => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  bool featureEnabled(String key) => features[key] ?? false;
}

class AnalysisResult {
  final String sessionId;
  final String? jobId;
  final String exerciseType, videoView;
  final double? weightKg;
  final int totalReps;
  final double techniqueScore, fatigueIndex;
  final bool fatigueDetected;
  final double? durationSeconds;
  final bool classifierEnabled;
  final String? classifierVersion;
  final Map<String, dynamic> paramsSummary, aiComparison;
  final List<RepResult> repetitions;
  final List<FeedbackItem> feedback;
  final String? annotatedDownloadUrl;
  final DateTime sessionDate;

  const AnalysisResult({required this.sessionId, this.jobId, required this.exerciseType,
      required this.videoView, this.weightKg, required this.totalReps,
      required this.techniqueScore, required this.fatigueDetected, this.fatigueIndex = 0.0,
      this.durationSeconds, this.classifierEnabled = false, this.classifierVersion,
      required this.paramsSummary, required this.repetitions, required this.feedback,
      required this.aiComparison, this.annotatedDownloadUrl, required this.sessionDate});

  factory AnalysisResult.fromJson(Map<String, dynamic> j) => AnalysisResult(
    sessionId: j['session_id'] ?? '',
    jobId: j['job_id'],
    exerciseType: j['exercise_type'] ?? 'squat',
    videoView: j['video_view'] ?? 'lateral',
    weightKg: (j['weight_kg'] as num?)?.toDouble(),
    totalReps: j['total_reps'] ?? 0,
    techniqueScore: (j['technique_score'] as num?)?.toDouble() ?? 0.0,
    fatigueDetected: j['fatigue_detected'] ?? false,
    fatigueIndex: (j['fatigue_index'] as num?)?.toDouble() ?? 0.0,
    durationSeconds: (j['duration_seconds'] as num?)?.toDouble(),
    classifierEnabled: j['classifier_enabled'] ?? false,
    classifierVersion: j['classifier_version'],
    paramsSummary: Map<String, dynamic>.from(j['params_summary'] ?? {}),
    repetitions: (j['repetitions'] as List? ?? []).map((r) => RepResult.fromJson(r)).toList(),
    feedback: (j['feedback'] as List? ?? []).map((f) => FeedbackItem.fromJson(f)).toList(),
    aiComparison: Map<String, dynamic>.from(j['ai_comparison'] ?? {}),
    annotatedDownloadUrl: j['annotated_download_url'],
    sessionDate: j['session_date'] != null ? DateTime.parse(j['session_date']) : DateTime.now(),
  );

  double? get oneRmEpley => (paramsSummary['one_rm_epley'] as num?)?.toDouble();
  List<FeedbackItem> get riskFeedback    => feedback.where((f) => f.isInjuryRisk).toList();
  List<FeedbackItem> get improveFeedback => feedback.where((f) => !f.isInjuryRisk && f.reportSection == 'mejora').toList();
}

class RepResult {
  final int repNumber;
  final double repScore;
  final bool depthAchieved;
  final double? kneeAngleMin, hipAngleMin, trunkLeanMax;
  final double? leftValgus, rightValgus;
  final double? ankleDF, eccentricDur, concentricDur, eccConRatio;
  final double? barVelocityMs, kneeAsymmetryPct, lateralHipShiftCm;
  final double? pelvicRotationDeg, heelElevationLeft;
  final double? aclRiskScore, patellofemoralLoad, lumbarRiskScore;
  final List<Map<String, dynamic>> errors;
  final String? clfClass;
  final double? clfConfidence;
  final Map<String, double>? clfProba;
  final List<Map<String, dynamic>>? clfTopFactors;
  final String? clfVersion;

  const RepResult({required this.repNumber, required this.repScore, required this.depthAchieved,
      this.kneeAngleMin, this.hipAngleMin, this.trunkLeanMax, this.leftValgus, this.rightValgus,
      this.ankleDF, this.eccentricDur, this.concentricDur, this.eccConRatio, this.barVelocityMs,
      this.kneeAsymmetryPct, this.lateralHipShiftCm, this.pelvicRotationDeg, this.heelElevationLeft,
      this.aclRiskScore, this.patellofemoralLoad, this.lumbarRiskScore,
      required this.errors, this.clfClass, this.clfConfidence, this.clfProba,
      this.clfTopFactors, this.clfVersion});

  factory RepResult.fromJson(Map<String, dynamic> j) => RepResult(
    repNumber: j['rep_number'] ?? 0,
    repScore: (j['rep_score'] as num?)?.toDouble() ?? 0.0,
    depthAchieved: j['depth_achieved'] ?? false,
    kneeAngleMin: (j['knee_angle_min'] as num?)?.toDouble(),
    hipAngleMin: (j['hip_angle_min'] as num?)?.toDouble(),
    trunkLeanMax: (j['trunk_lean_max'] as num?)?.toDouble(),
    leftValgus: (j['left_valgus'] as num?)?.toDouble(),
    rightValgus: (j['right_valgus'] as num?)?.toDouble(),
    ankleDF: (j['ankle_dorsiflexion_left'] as num?)?.toDouble(),
    eccentricDur: (j['eccentric_duration_s'] as num?)?.toDouble(),
    concentricDur: (j['concentric_duration_s'] as num?)?.toDouble(),
    eccConRatio: (j['eccentric_concentric_ratio'] as num?)?.toDouble(),
    barVelocityMs: (j['bar_velocity_ms'] as num?)?.toDouble(),
    kneeAsymmetryPct: (j['knee_asymmetry_pct'] as num?)?.toDouble(),
    lateralHipShiftCm: (j['lateral_hip_shift_cm'] as num?)?.toDouble(),
    pelvicRotationDeg: (j['pelvic_rotation_deg'] as num?)?.toDouble(),
    heelElevationLeft: (j['heel_elevation_left'] as num?)?.toDouble(),
    aclRiskScore: (j['acl_risk_score'] as num?)?.toDouble(),
    patellofemoralLoad: (j['patellofemoral_load'] as num?)?.toDouble(),
    lumbarRiskScore: (j['lumbar_risk_score'] as num?)?.toDouble(),
    errors: List<Map<String, dynamic>>.from(j['errors'] ?? []),
    clfClass: j['clf_class'],
    clfConfidence: (j['clf_confidence'] as num?)?.toDouble(),
    clfProba: (j['clf_proba'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    clfTopFactors: j['clf_top_factors'] != null ? List<Map<String, dynamic>>.from(j['clf_top_factors']) : null,
    clfVersion: j['clf_version'],
  );

  bool get hasInjuryRisk  => (aclRiskScore ?? 0) >= 50 || (lumbarRiskScore ?? 0) >= 50;
  bool get hasClassifier  => clfClass != null;
}

class FeedbackItem {
  final String errorType, severity, message, correction;
  final String? exerciseRecommendation;
  final int frequency, priorityRank;
  final bool isInjuryRisk;
  final String reportSection;

  const FeedbackItem({required this.errorType, required this.severity,
      required this.message, required this.correction, this.exerciseRecommendation,
      required this.frequency, required this.priorityRank,
      required this.isInjuryRisk, this.reportSection = 'mejora'});

  factory FeedbackItem.fromJson(Map<String, dynamic> j) => FeedbackItem(
    errorType: j['error_type'] ?? '', severity: j['severity'] ?? 'mild',
    message: j['message'] ?? '', correction: j['correction'] ?? '',
    exerciseRecommendation: j['exercise_recommendation'],
    frequency: j['frequency'] ?? 1, priorityRank: j['priority_rank'] ?? 1,
    isInjuryRisk: j['is_injury_risk'] ?? false, reportSection: j['report_section'] ?? 'mejora',
  );
}

class WorkoutSummary {
  final String id, exerciseType;
  final double? weightKg;
  final int totalReps, totalSets;
  final double techniqueScore;
  final bool fatigueDetected, classifierEnabled;
  final DateTime sessionDate;

  const WorkoutSummary({required this.id, required this.exerciseType, this.weightKg,
      required this.totalReps, required this.totalSets, required this.techniqueScore,
      required this.fatigueDetected, this.classifierEnabled = false, required this.sessionDate});

  factory WorkoutSummary.fromJson(Map<String, dynamic> j) => WorkoutSummary(
    id: j['id'] ?? '', exerciseType: j['exercise_type'] ?? 'squat',
    weightKg: (j['weight_kg'] as num?)?.toDouble(),
    totalReps: j['total_reps'] ?? 0, totalSets: j['total_sets'] ?? 1,
    techniqueScore: (j['technique_score'] as num?)?.toDouble() ?? 0.0,
    fatigueDetected: j['fatigue_detected'] ?? false,
    classifierEnabled: j['classifier_enabled'] ?? false,
    sessionDate: j['session_date'] != null ? DateTime.parse(j['session_date']) : DateTime.now(),
  );
}

class OneRMResult {
  final double weightKg, oneRmEpley, oneRmBrzycki, oneRmAverage;
  final int reps;
  final Map<String, dynamic> equivalences;

  const OneRMResult({required this.weightKg, required this.reps,
      required this.oneRmEpley, required this.oneRmBrzycki,
      required this.oneRmAverage, required this.equivalences});

  factory OneRMResult.fromJson(Map<String, dynamic> j) => OneRMResult(
    weightKg: (j['weight_kg'] as num?)?.toDouble() ?? 0.0,
    reps: j['reps'] ?? 0,
    oneRmEpley: (j['epley'] as num?)?.toDouble() ?? 0.0,
    oneRmBrzycki: (j['brzycki'] as num?)?.toDouble() ?? 0.0,
    oneRmAverage: (j['average'] as num?)?.toDouble() ?? 0.0,
    equivalences: Map<String, dynamic>.from(j['equivalences'] ?? {}),
  );
}

class AIModelState {
  final String phase, phaseMessage, nextMilestone;
  final double progress;
  final int totalReps, baselineReps, totalSessions;
  final Map<String, dynamic> morphology, classifier;
  final Map<String, String> improvementTrends;
  final List<Map<String, dynamic>> recommendations;

  const AIModelState({required this.phase, required this.phaseMessage, required this.progress,
      required this.nextMilestone, required this.totalReps, required this.baselineReps,
      required this.totalSessions, required this.morphology, required this.improvementTrends,
      required this.recommendations, required this.classifier});

  factory AIModelState.fromJson(Map<String, dynamic> j) => AIModelState(
    phase: j['phase'] ?? 'collecting',
    phaseMessage: j['phase_message'] ?? '',
    progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
    nextMilestone: j['next_milestone'] ?? '',
    totalReps: j['total_reps'] ?? 0,
    baselineReps: j['baseline_reps'] ?? 0,
    totalSessions: j['total_sessions'] ?? 0,
    morphology: Map<String, dynamic>.from(j['morphology'] ?? {}),
    improvementTrends: (j['improvement_trends'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString())),
    recommendations: List<Map<String, dynamic>>.from(j['recommendations'] ?? []),
    classifier: Map<String, dynamic>.from(j['classifier'] ?? {}),
  );

  bool get isActive        => phase == 'active' || phase == 'optimizing';
  bool get classifierReady => classifier['ready'] == true;
  String get classifierVersion => classifier['version']?.toString() ?? '';
  String get phaseEmoji {
    switch (phase) {
      case 'learning':   return '🧠';
      case 'active':     return '✅';
      case 'optimizing': return '🎯';
      default:           return '📊';
    }
  }
}
