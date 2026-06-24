// services/api_service.dart — Sin Firebase Storage: upload directo al backend
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';
import '../model/analysis_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._() { _setup(); }

  late final Dio _dio;

  // IMPORTANTE: Emulador Android = 10.0.2.2 | Dispositivo físico = IP de tu PC
  static const baseUrl = 'http://10.0.2.2:8000';

  void _setup() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5), // videos pueden tardar
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          // Forzar refresh del token para asegurar que sea válido
          final token = await FirebaseAuth.instance.currentUser
              ?.getIdToken(false); // false = no forzar refresh cada vez
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Si falla obtener token, continúa sin él (dará 401 en el server)
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Si 401, intentar refrescar token y reintentar UNA vez
        if (error.response?.statusCode == 401) {
          try {
            final token = await FirebaseAuth.instance.currentUser
                ?.getIdToken(true); // true = forzar refresh
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {}
        }
        handler.next(error);
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

  Future<void> savePhysicalData({
    required double heightCm, required double weightKg,
    required int age, required String sex, required double trainingYears,
  }) async {
    await _dio.post('/users/physical-data', data: {
      'height_cm': heightCm, 'weight_kg': weightKg,
      'age': age, 'sex': sex, 'training_years': trainingYears,
    });
  }

  Future<void> updateMe(Map<String, dynamic> data) async {
    await _dio.patch('/users/me', data: data);
  }

  Future<Map<String, dynamic>> becomeCoach() async {
    final r = await _dio.post('/users/become-coach', data: {'accept_terms': true});
    return Map<String, dynamic>.from(r.data);
  }

  // ── Video — Upload DIRECTO al backend (sin Firebase Storage) ──────────────
  Future<String> uploadVideoToBackend({
    required String filePath,
    required String exerciseType,
    required String videoView,
    double weightKg = 0.0,
    void Function(double)? onProgress,
  }) async {
    final file = await MultipartFile.fromFile(filePath,
        filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4');

    final formData = FormData.fromMap({
      'file': file,
      'exercise_type': exerciseType,
      'video_view': videoView,
      'weight_kg': weightKg.toString(),
    });

    final r = await _dio.post(
      '/videos/upload-and-analyze',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(minutes: 10),
      ),
    );

    return r.data['job_id'] as String;
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final r = await _dio.get('/videos/$jobId/status');
    return Map<String, dynamic>.from(r.data);
  }

  Future<AnalysisResultModel> getResults(String jobId) async {
    final r = await _dio.get('/videos/$jobId/results');
    return AnalysisResultModel.fromJson(r.data);
  }

  // ── Workouts ──────────────────────────────────────────────────────────────
  Future<List<WorkoutSessionModel>> getWorkouts({int page = 1, String? exerciseType}) async {
    final r = await _dio.get('/workouts/', queryParameters: {
      'page': page, 'per_page': 20,
      if (exerciseType != null) 'exercise_type': exerciseType,
    });
    return (r.data['items'] as List).map((j) => WorkoutSessionModel.fromJson(j)).toList();
  }

  // ── Strength ──────────────────────────────────────────────────────────────
  Future<OneRMModel> calculateOneRM(String exercise, double weight, int reps) async {
    final r = await _dio.post('/strength/calculate',
        data: {'exercise_type': exercise, 'weight_kg': weight, 'reps': reps});
    return OneRMModel.fromJson({...r.data, 'weight_kg': weight, 'reps': reps});
  }

  // ── AI Model ──────────────────────────────────────────────────────────────
  Future<AIModelStateModel> getAIModel() async {
    final r = await _dio.get('/ai/model');
    return AIModelStateModel.fromJson(r.data);
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
