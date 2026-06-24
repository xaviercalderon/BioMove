// model/user_model.dart — Modelo de datos del usuario
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

  const UserModel({
    required this.id, this.firebaseUid, required this.email,
    required this.displayName, this.photoUrl, this.role = 'athlete',
    this.heightCm, this.weightKg, this.age, this.sex, this.trainingYears,
    this.onboardingDone = false, this.hasPhysicalData = false,
    this.features = const {},
  });

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
