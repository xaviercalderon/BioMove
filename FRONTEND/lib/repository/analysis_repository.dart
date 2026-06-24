// repository/analysis_repository.dart — Sin Firebase Storage
import '../model/analysis_model.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';

class AnalysisRepository {
  static final AnalysisRepository _i = AnalysisRepository._();
  factory AnalysisRepository() => _i;
  AnalysisRepository._();

  final _api    = ApiService();
  final _camera = CameraService();

  Future<VideoValidationModel> validateVideo(String filePath) =>
      _camera.validateVideo(filePath);

  Future<Map<String, dynamic>> preValidateVideoBackend(String filePath) =>
      _api.preValidateVideo(filePath: filePath);

  /// Sube el video DIRECTAMENTE al backend (sin Firebase Storage)
  Future<String> startAnalysis({
    required String filePath,
    required String exerciseType,
    required String videoView,
    double weightKg = 0.0,
    void Function(double)? onUploadProgress,
  }) async {
    return _api.uploadVideoToBackend(
      filePath: filePath,
      exerciseType: exerciseType,
      videoView: videoView,
      weightKg: weightKg,
      onProgress: onUploadProgress,
    );
  }

  Future<Map<String, dynamic>> getJobStatus(String jobId) =>
      _api.getJobStatus(jobId);

  Future<AnalysisResultModel> getResults(String jobId) =>
      _api.getResults(jobId);

  Future<List<WorkoutSessionModel>> getWorkouts({int page = 1, String? exerciseType}) =>
      _api.getWorkouts(page: page, exerciseType: exerciseType);

  Future<OneRMModel> calculateOneRM(String exercise, double weight, int reps) =>
      _api.calculateOneRM(exercise, weight, reps);

  Future<AIModelStateModel> getAIModel() => _api.getAIModel();
}
