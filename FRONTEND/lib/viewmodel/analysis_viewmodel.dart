// viewmodel/analysis_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/analysis_model.dart';
import '../repository/analysis_repository.dart';
import '../services/notification_service.dart';

enum AnalysisStep { idle, uploading, processing, completed, failed }

class AnalysisViewModel extends ChangeNotifier {
  final _repo  = AnalysisRepository();
  final _notif = NotificationService();

  AnalysisStep         _step        = AnalysisStep.idle;
  double               _uploadPct   = 0.0;
  int                  _progressPct = 0;
  String?              _jobId;
  AnalysisResultModel? _result;
  String?              _error;
  Timer?               _pollTimer;
  int                  _pollCount   = 0;
  String               _exerciseLabel = 'Sentadilla';

  AnalysisStep         get step        => _step;
  double               get uploadPct   => _uploadPct;
  int                  get progressPct => _progressPct;
  AnalysisResultModel? get result      => _result;
  String?              get error       => _error;
  String?              get jobId       => _jobId;
  bool get isLoading =>
      _step == AnalysisStep.uploading || _step == AnalysisStep.processing;

  /// 0-30% upload + 30-100% backend
  int get totalProgressPct {
    if (_step == AnalysisStep.uploading)  return (_uploadPct * 30).toInt();
    if (_step == AnalysisStep.processing) return 30 + (_progressPct * 0.7).toInt();
    if (_step == AnalysisStep.completed)  return 100;
    return 0;
  }

  String get statusMessage {
    switch (_step) {
      case AnalysisStep.uploading:   return 'Subiendo video... ${(_uploadPct*100).toInt()}%';
      case AnalysisStep.processing:  return _backendMsg(_progressPct);
      case AnalysisStep.completed:   return '¡Análisis completado!';
      case AnalysisStep.failed:      return _error ?? 'Error en el análisis';
      default: return '';
    }
  }

  String _backendMsg(int pct) {
    if (pct < 20) return 'Extrayendo poses con IA...';
    if (pct < 50) return 'Detectando repeticiones...';
    if (pct < 80) return 'Calculando 40 parámetros biomecánicos...';
    if (pct < 95) return 'Generando video anotado...';
    return '¡Casi listo!';
  }

  Future<void> analyze({
    required String filePath,
    required String exerciseType,
    required String videoView,
    double weightKg = 0.0,
  }) async {
    _step = AnalysisStep.uploading; _uploadPct = 0.0; _progressPct = 0;
    _error = null; _result = null; _pollCount = 0;
    _exerciseLabel = _labelFromType(exerciseType);
    notifyListeners();
    await _notif.showProgress(percent: 0, exerciseLabel: _exerciseLabel);
    try {
      _jobId = await _repo.startAnalysis(
        filePath: filePath, exerciseType: exerciseType,
        videoView: videoView, weightKg: weightKg,
        onUploadProgress: (p) {
          _uploadPct = p;
          _notif.showProgress(percent: (p*30).toInt(), exerciseLabel: _exerciseLabel);
          notifyListeners();
        },
      );
      _step = AnalysisStep.processing; _progressPct = 0;
      notifyListeners();
      _startPolling();
    } catch (e) {
      _step = AnalysisStep.failed; _error = _extractError(e);
      await _notif.showError(_error!);
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_jobId == null) return;
    _pollCount++;
    if (_pollCount > 120) {
      _pollTimer?.cancel();
      _step = AnalysisStep.failed;
      _error = 'El análisis tardó demasiado. Intenta con un video más corto.';
      await _notif.showError(_error!);
      notifyListeners(); return;
    }
    try {
      final status = await _repo.getJobStatus(_jobId!);
      final st  = status['status'] as String?;
      final pct = (status['progress_pct'] as num?)?.toInt() ?? _progressPct;
      if (pct != _progressPct) {
        _progressPct = pct;
        await _notif.showProgress(
          percent: 30 + (pct * 0.7).toInt(),
          exerciseLabel: _exerciseLabel);
        notifyListeners();
      }
      if (st == 'completed') {
        _pollTimer?.cancel();
        _progressPct = 100;
        // getResults separado: si falla muestra error en vez de quedar pegado
        try {
          _result = await _repo.getResults(_jobId!);
          _step   = AnalysisStep.completed;
          await _notif.showCompleted(
            exerciseLabel: _exerciseLabel,
            score: _result?.techniqueScore ?? 0,
            totalReps: _result?.totalReps ?? 0);
        } catch (e) {
          _step  = AnalysisStep.failed;
          _error = 'Error al cargar resultados: $e';
          await _notif.showError(_error!);
        }
        notifyListeners();
      } else if (st == 'failed') {
        _pollTimer?.cancel();
        _step = AnalysisStep.failed;
        _error = status['error_message'] ?? 'El análisis falló';
        await _notif.showError(_error!);
        notifyListeners();
      }
    } catch (_) {
      // Error de red — no cancelar, seguir reintentando en el próximo tick
    }
  }

  /// Carga un resultado histórico desde el historial (sin polling)
  void setResultFromHistory(AnalysisResultModel result) {
    _pollTimer?.cancel();
    _result = result;
    _step   = AnalysisStep.completed;
    _progressPct = 100;
    _error  = null;
    notifyListeners();
  }

  bool get canLeaveScreen =>
      _step == AnalysisStep.processing || _step == AnalysisStep.uploading;

  /// Cancela el análisis en curso y vuelve al estado inicial
  void cancel() {
    _pollTimer?.cancel();
    _step = AnalysisStep.idle;
    _uploadPct = 0.0; _progressPct = 0;
    _jobId = null; _result = null; _error = null; _pollCount = 0;
    _notif.cancelAll();
    notifyListeners();
  }

  void reset() {
    _pollTimer?.cancel();
    _step = AnalysisStep.idle; _uploadPct = 0.0; _progressPct = 0;
    _jobId = null; _result = null; _error = null; _pollCount = 0;
    notifyListeners();
  }

  String _labelFromType(String t) => const {
    'squat':'Sentadilla','deadlift':'Peso muerto','bench_press':'Press banca'
  }[t] ?? 'Ejercicio';

  String _extractError(dynamic e) {
    final s = e.toString();
    if (s.contains('Connection refused') || s.contains('SocketException'))
      return 'Servidor no disponible. Verifica que el backend esté corriendo.';
    if (s.contains('401')) return 'Error de autenticación. Cierra e inicia sesión.';
    if (s.contains('413')) return 'Video demasiado grande (máx 500 MB).';
    if (s.contains('timeout')) return 'Tiempo de espera agotado.';
    return 'Error inesperado. Intenta de nuevo.';
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }
}
