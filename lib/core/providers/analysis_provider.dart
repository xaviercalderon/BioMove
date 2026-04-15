// lib/core/providers/analysis_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../api/api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


enum AnalysisStep { idle, uploading, processing, completed, failed }

class AnalysisProvider extends ChangeNotifier {
  final _api = ApiClient();
  AnalysisStep    _step      = AnalysisStep.idle;
  double          _uploadPct = 0.0;
  String?         _jobId;
  AnalysisResult? _result;
  String?         _error;
  Timer?          _pollTimer;
  int             _pollCount = 0;

  AnalysisStep    get step      => _step;
  double          get uploadPct => _uploadPct;
  AnalysisResult? get result    => _result;
  String?         get error     => _error;
  bool get isLoading => _step == AnalysisStep.uploading || _step == AnalysisStep.processing;

  String get statusMessage {
    switch (_step) {
      case AnalysisStep.uploading:  return 'Subiendo video... ${(_uploadPct*100).toInt()}%';
      case AnalysisStep.processing: return 'Analizando con IA — 40 parámetros biomecánicos...';
      case AnalysisStep.completed:  return '¡Análisis completado!';
      case AnalysisStep.failed:     return 'Error en el análisis';
      default:                      return '';
    }
  }

  Future<void> analyze({required String filePath, required String exerciseType,
      required String videoView, double weightKg = 0.0}) async {
    _step = AnalysisStep.uploading; _uploadPct = 0.0;
    _error = null; _result = null; _pollCount = 0;
    notifyListeners();
    try {
      final uid   = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final jobId = const Uuid().v4();
      final storagePath = await _api.uploadVideoToStorage(
        uid: uid, jobId: jobId, filePath: filePath,
        onProgress: (p) { _uploadPct = p; notifyListeners(); },
      );
      _jobId = await _api.startAnalysis(storagePath: storagePath,
          exerciseType: exerciseType, videoView: videoView, weightKg: weightKg);
      _step = AnalysisStep.processing; notifyListeners();
      _startPolling();
    } catch (e) {
      _step = AnalysisStep.failed; _error = _extractError(e); notifyListeners();
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
      _pollTimer?.cancel(); _step = AnalysisStep.failed;
      _error = 'El análisis tardó demasiado. Intenta con un video más corto.';
      notifyListeners(); return;
    }
    try {
      final status = await _api.getJobStatus(_jobId!);
      final st     = status['status'] as String?;
      if (st == 'completed') {
        _pollTimer?.cancel();
        _result = await _api.getResults(_jobId!);
        _step   = AnalysisStep.completed; notifyListeners();
      } else if (st == 'failed') {
        _pollTimer?.cancel(); _step = AnalysisStep.failed;
        _error = status['error_message'] ?? 'El análisis falló'; notifyListeners();
      }
    } catch (_) {}
  }

  void reset() {
    _pollTimer?.cancel(); _step = AnalysisStep.idle; _uploadPct = 0.0;
    _jobId = null; _result = null; _error = null; _pollCount = 0;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    final s = e.toString();
    if (s.contains('Connection refused')) return 'Servidor no disponible. Inicia el backend con start_all.bat';
    if (s.contains('413')) return 'Video demasiado grande (máx 500 MB)';
    if (s.contains('SocketException')) return 'Sin conexión. Verifica que el servidor esté corriendo.';
    return s;
  }

  @override
  void dispose() { _pollTimer?.cancel(); super.dispose(); }
}

// lib/core/providers/connectivity_provider.dart

class ConnectivityProvider extends ChangeNotifier {
  bool _online = true;
  bool get online  => _online;
  bool get offline => !_online;

  ConnectivityProvider() {
    Connectivity().onConnectivityChanged.listen((results) {
      final was = _online;
      _online = results.any((r) => r != ConnectivityResult.none);
      if (was != _online) notifyListeners();
    });
    _check();
  }

  Future<void> _check() async {
    final results = await Connectivity().checkConnectivity();
    _online = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
  }
}
