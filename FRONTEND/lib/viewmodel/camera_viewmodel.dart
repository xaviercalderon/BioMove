// viewmodel/camera_viewmodel.dart — ViewModel de captura y validación de video
// ISO/IEC 25010:2023 — Operabilidad: validación previa, semáforo, guías
import 'package:flutter/foundation.dart';
import '../model/analysis_model.dart';
import '../repository/analysis_repository.dart';

class CameraViewModel extends ChangeNotifier {
  final _repo = AnalysisRepository();

  String? _filePath;
  String  _exercise       = 'squat';
  String  _view           = '';        // '' = sin seleccionar, debe elegir lateral o frontal
  double  _weightKg       = 0.0;
  bool    _showWeightInfo = false;
  VideoValidationModel _validation = VideoValidationModel.empty;
  String? _detectedView;

  // ── Getters ─────────────────────────────────────────────────────────────
  String?  get filePath       => _filePath;
  String   get exercise       => _exercise;
  String   get view           => _view;
  double   get weightKg       => _weightKg;
  bool     get showWeightInfo => _showWeightInfo;
  VideoValidationModel get validation => _validation;
  String?  get detectedView   => _detectedView;

  bool get hasVideo     => _filePath != null;
  bool get viewSelected => _view == 'lateral' || _view == 'frontal';

  // canAnalyze: necesita video válido Y vista seleccionada
  bool get canAnalyze => hasVideo && _validation.allPassed && viewSelected;

  // true si el validador detectó un plano distinto al que seleccionó el usuario
  bool get viewMismatch {
    if (_detectedView == null || !viewSelected) return false;
    return _view != _detectedView;
  }

  String get analyzeBlockedReason {
    if (!hasVideo) return 'Primero selecciona o graba un video';
    if (_validation.status == VideoValidationStatus.validating) return 'Verificando video...';
    if (!_validation.sizeOk) return 'El video supera los 500 MB permitidos';
    if (!_validation.durationOk) return 'El video debe durar entre 3 segundos y 10 minutos';
    if (!_validation.poseOk) return _validation.mainIssue ?? 'Video no válido para análisis';
    if (!viewSelected) return 'Selecciona la vista: Lateral o Frontal';
    return '';
  }

  // Vista recomendada según el ejercicio
  String get recommendedView => _exercise == 'bench_press' ? 'frontal' : 'lateral';
  bool   get viewMatchesExercise => !viewSelected || _view == recommendedView;

  List<String> get lateralParams => const [
    'Ángulo de rodilla (flexión/extensión)',
    'Ángulo de cadera (profundidad)',
    'Inclinación del tronco',
    'Dorsiflexión del tobillo',
    'Butt wink (rotación pélvica posterior)',
    'Desplazamiento rodilla vs tobillo',
    'Ratio excéntrico/concéntrico',
    'Velocidad de barra estimada',
    'Elevación de talones',
    'Curvatura lumbar vs torácica',
  ];

  List<String> get frontalParams => const [
    'Valgo de rodilla (colapso medial)',
    'Asimetría bilateral izquierdo/derecho',
    'Desplazamiento lateral de cadera',
    'Inclinación pélvica lateral',
    'Ángulo de apertura del pie',
    'Ancho del stance',
    'Alineación rodilla-pie',
  ];

  List<String> get currentViewParams =>
      _view == 'frontal' ? frontalParams : lateralParams;

  // ── Acciones ─────────────────────────────────────────────────────────────
  void setExercise(String ex) {
    _exercise = ex;
    _view = '';
    notifyListeners();
  }

  void setView(String v) { _view = v; notifyListeners(); }

  void setWeight(String v) { _weightKg = double.tryParse(v) ?? 0.0; notifyListeners(); }

  void toggleWeightInfo() { _showWeightInfo = !_showWeightInfo; notifyListeners(); }

  Future<void> setVideoFile(String path) async {
    _filePath     = path;
    _detectedView = null;
    // Fase 1 — validación local (tamaño/duración)
    _validation = VideoValidationModel(status: VideoValidationStatus.validating);
    notifyListeners();
    final local = await _repo.validateVideo(path);
    if (!local.sizeOk || !local.durationOk) {
      _validation = local;
      notifyListeners();
      return;
    }
    // Fase 2 — validación de pose con backend (MediaPipe)
    notifyListeners();
    try {
      final result  = await _repo.preValidateVideoBackend(path);
      final bool poseOk     = result['valid'] == true;
      final String? detView = result['detected_view'] as String?;
      final String? reason  = result['reason'] as String?;
      final int framesOk    = (result['frames_ok']    as num?)?.toInt() ?? 0;
      final int framesTotal = (result['frames_total'] as num?)?.toInt() ?? 0;
      _detectedView = detView;
      _validation = VideoValidationModel(
        status:          poseOk ? VideoValidationStatus.valid : VideoValidationStatus.invalid,
        durationOk:      local.durationOk,
        sizeOk:          local.sizeOk,
        poseOk:          poseOk,
        mainIssue:       poseOk ? null : reason,
        durationSeconds: local.durationSeconds,
        fileSizeMb:      local.fileSizeMb,
        detectedView:    detView,
        framesOk:        framesOk,
        framesTotal:     framesTotal,
      );
    } catch (e) {
      // Backend no disponible — bloquear con mensaje claro
      _validation = VideoValidationModel(
        status:          VideoValidationStatus.invalid,
        durationOk:      local.durationOk,
        sizeOk:          local.sizeOk,
        poseOk:          false,
        mainIssue:       'No se pudo verificar el video. Asegúrate de que el servidor esté activo.',
        fileSizeMb:      local.fileSizeMb,
        durationSeconds: local.durationSeconds,
      );
    }
    notifyListeners();
  }

  void clearVideo() {
    _filePath     = null;
    _detectedView = null;
    _validation   = VideoValidationModel.empty;
    notifyListeners();
  }
}
