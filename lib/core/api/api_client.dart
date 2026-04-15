import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._();
  factory ApiClient() => _i;
  ApiClient._() { _setup(); }
  late final Dio _dio;

  void _setup() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        } catch (_) {}
        handler.next(options);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<UserModel> verifyToken() async {
    final r = await _dio.post('/auth/verify-token');
    return UserModel.fromJson(r.data);
  }

  // ── Users ─────────────────────────────────────────────────────────────────
  Future<UserModel> getMe() async {
    final r = await _dio.get('/users/me');
    return UserModel.fromJson(r.data);
  }

  Future<void> savePhysicalData({required double heightCm, required double weightKg,
      required int age, required String sex, required double trainingYears}) async {
    await _dio.post('/users/physical-data', data: {
      'height_cm': heightCm, 'weight_kg': weightKg, 'age': age,
      'sex': sex, 'training_years': trainingYears,
    });
  }

  Future<void> updateMe(Map<String, dynamic> data) async {
    await _dio.patch('/users/me', data: data);
  }

  // ── Video — Firebase Storage direct upload ────────────────────────────────
  Future<String> uploadVideoToStorage({
    required String uid, required String jobId, required String filePath,
    void Function(double)? onProgress,
  }) async {
    final storagePath = 'originals/$uid/$jobId.mp4';
    final ref  = FirebaseStorage.instance.ref().child(storagePath);
    final file = File(filePath);
    final task = ref.putFile(file, SettableMetadata(contentType: 'video/mp4'));
    task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) onProgress?.call(snap.bytesTransferred / snap.totalBytes);
    });
    await task;
    return storagePath;
  }

  Future<String> startAnalysis({required String storagePath, required String exerciseType,
      required String videoView, double weightKg = 0.0}) async {
    final r = await _dio.post('/videos/analyze', data: {
      'storage_path': storagePath, 'exercise_type': exerciseType,
      'video_view': videoView, 'weight_kg': weightKg,
    });
    return r.data['job_id'] as String;
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final r = await _dio.get('/videos/$jobId/status');
    return Map<String, dynamic>.from(r.data);
  }

  Future<AnalysisResult> getResults(String jobId) async {
    final r = await _dio.get('/videos/$jobId/results');
    return AnalysisResult.fromJson(r.data);
  }

  // ── Workouts ──────────────────────────────────────────────────────────────
  Future<List<WorkoutSummary>> getWorkouts({int page = 1, String? exerciseType}) async {
    final r = await _dio.get('/workouts/', queryParameters: {
      'page': page, 'per_page': 20,
      if (exerciseType != null) 'exercise_type': exerciseType,
    });
    return (r.data['items'] as List).map((j) => WorkoutSummary.fromJson(j)).toList();
  }

  // ── Strength ──────────────────────────────────────────────────────────────
  Future<OneRMResult> calculateOneRM(String exercise, double weight, int reps) async {
    final r = await _dio.post('/strength/calculate',
        data: {'exercise_type': exercise, 'weight_kg': weight, 'reps': reps});
    return OneRMResult.fromJson({...r.data, 'weight_kg': weight, 'reps': reps});
  }

  // ── AI Model ──────────────────────────────────────────────────────────────
  Future<AIModelState> getAIModel() async {
    final r = await _dio.get('/ai/model');
    return AIModelState.fromJson(r.data);
  }

  // ── Coach ─────────────────────────────────────────────────────────────────
  Future<String> generateInviteCode() async {
    final r = await _dio.post('/coach/invite-code');
    return r.data['code'] as String;
  }

  Future<Map<String, dynamic>> linkWithCode(String code) async {
    final r = await _dio.post('/coach/link/$code');
    return Map<String, dynamic>.from(r.data);
  }

  Future<List<dynamic>> getMyAthletes() async {
    final r = await _dio.get('/coach/athletes');
    return r.data['athletes'] as List;
  }

  Future<List<dynamic>> getAthleteSessions(String athleteId) async {
    final r = await _dio.get('/coach/athlete/$athleteId/sessions');
    return r.data['sessions'] as List;
  }

  Future<void> addSessionNotes(String sessionId, String notes) async {
    await _dio.post('/coach/session/notes', data: {'session_id': sessionId, 'notes': notes});
  }

  // ── Admin ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final r = await _dio.get('/admin/dashboard');
    return Map<String, dynamic>.from(r.data);
  }

  Future<List<dynamic>> getAdminUsers({String? role, String? search}) async {
    final r = await _dio.get('/admin/users', queryParameters: {
      if (role != null) 'role': role,
      if (search != null) 'search': search,
    });
    return r.data['users'] as List;
  }

  Future<void> userAction(String userId, String action, {String? value}) async {
    await _dio.post('/admin/users/$userId/action',
        data: {'action': action, if (value != null) 'value': value});
  }

  Future<Map<String, dynamic>> getClassifierInfo() async {
    final r = await _dio.get('/admin/model/info');
    return Map<String, dynamic>.from(r.data);
  }
}
