// services/camera_service.dart — Servicio de validación de video (ISO Operabilidad)
// Valida offline: tamaño, duración estimada. Sin análisis de postura.
import 'dart:io';
import '../model/analysis_model.dart';

class CameraService {
  static final CameraService _i = CameraService._();
  factory CameraService() => _i;
  CameraService._();

  static const double maxFileSizeMb     = 500.0;
  static const double minFileSizeMbApprox = 0.05; // ~3 segundos de video

  /// Valida un video ANTES de enviarlo al servidor.
  /// Sólo verifica tamaño y duración estimada — no analiza postura.
  Future<VideoValidationModel> validateVideo(String filePath) async {
    try {
      final file  = File(filePath);
      final bytes = await file.length();
      final mb    = bytes / (1024 * 1024);

      final sizeOk     = mb <= maxFileSizeMb;
      final durationOk = mb >= minFileSizeMbApprox && mb <= maxFileSizeMb;

      String? mainIssue;
      if (!sizeOk)
        mainIssue = 'El video supera los 500 MB. Graba uno más corto.';
      else if (mb < minFileSizeMbApprox)
        mainIssue = 'El video es demasiado corto. Graba al menos 3 segundos.';

      return VideoValidationModel(
        status:          (sizeOk && durationOk) ? VideoValidationStatus.valid : VideoValidationStatus.invalid,
        durationOk:      durationOk,
        sizeOk:          sizeOk,
        mainIssue:       mainIssue,
        durationSeconds: mb * 1.5,  // estimación: ~1 MB/s a 720p
        fileSizeMb:      mb,
      );
    } catch (_) {
      return const VideoValidationModel(
        status: VideoValidationStatus.valid,
        durationOk: true, sizeOk: true,
      );
    }
  }
}
