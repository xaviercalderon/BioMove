// repository/progression_repository.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/app_constants.dart';

class ProgressionRepository {
  late final Dio _dio;

  ProgressionRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken(false);
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        } catch (_) {}
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final resp = await _dio.fetch(error.requestOptions);
              handler.resolve(resp); return;
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> getActivePlan(String exercise) async {
    final r = await _dio.get('/progression/plan/active',
        queryParameters: {'exercise_type': exercise});
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> createPlan({
    required String exercise, double? oneRm}) async {
    final r = await _dio.post('/progression/plan', data: {
      'exercise_type': exercise,
      if (oneRm != null) 'current_1rm': oneRm,
    });
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> advanceWeek(String planId) async {
    final r = await _dio.post('/progression/plan/$planId/advance');
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> vbtFeedback({
    required String planId, required int weekNumber,
    required double velocity, required double weightUsed,
    required int repsDone,
  }) async {
    final r = await _dio.post('/progression/vbt-feedback', data: {
      'plan_id': planId, 'week_number': weekNumber,
      'actual_velocity': velocity, 'weight_used': weightUsed,
      'reps_done': repsDone,
    });
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> getHistory(String exercise) async {
    final r = await _dio.get('/progression/history/$exercise');
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> predictOneRm(
      double weightKg, double velocityMs) async {
    final r = await _dio.post('/progression/predict-1rm',
        queryParameters: {'weight_kg': weightKg, 'velocity_ms': velocityMs});
    return Map<String, dynamic>.from(r.data);
  }
}
