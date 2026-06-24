// viewmodel/progression_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../model/progression_model.dart';
import '../repository/progression_repository.dart';
import '../services/notification_service.dart';

class ProgressionViewModel extends ChangeNotifier {
  final _repo  = ProgressionRepository();
  final _notif = NotificationService();

  TrainingPlanModel? _plan;
  List<StrengthRecordModel> _history = [];
  double? _personalBest;
  double _improvementPct = 0.0;
  bool   _isLoading = false;
  String? _error;

  bool                      get hasPlan        => _plan != null;
  bool                      get isLoading      => _isLoading;
  String?                   get error          => _error;
  WeekModel?                get todaySession   => _plan?.todaySession;
  List<BlockModel>          get blocks         => _plan?.blocks ?? [];
  List<WeekModel>           get allWeeks       => _plan?.allWeeks ?? [];
  int                       get currentWeek    => _plan?.currentWeek ?? 1;
  String                    get currentBlock   => _plan?.currentBlock ?? 'accumulation';
  bool                      get coachApproved  => _plan?.coachApproved ?? false;
  String?                   get coachNotes     => _plan?.coachNotes;
  double?                   get personalBest   => _personalBest;
  double                    get improvementPct => _improvementPct;
  List<StrengthRecordModel> get history        => _history;
  String?                   get planId         => _plan?.planId;

  Future<void> loadActivePlan({String exercise = 'squat'}) async {
    _isLoading = true; _error = null;
    notifyListeners();
    try {
      final data = await _repo.getActivePlan(exercise);
      if (data['plan'] != null) {
        _plan = TrainingPlanModel.fromJson(data);
      } else {
        _plan = null;
      }
      await _loadHistory(exercise);
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistory(String exercise) async {
    try {
      final data    = await _repo.getHistory(exercise);
      _history      = (data['records'] as List? ?? [])
          .map((r) => StrengthRecordModel.fromJson(r as Map<String, dynamic>))
          .toList();
      _personalBest = (data['personal_best'] as num?)?.toDouble();
      _improvementPct = (data['improvement_pct'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {}
  }

  Future<void> createPlan({required String exercise, double? oneRm}) async {
    _isLoading = true; _error = null;
    notifyListeners();
    try {
      final data = await _repo.createPlan(exercise: exercise, oneRm: oneRm);
      _plan = TrainingPlanModel.fromJson(data);
      await _loadHistory(exercise);
      // Notificación de plan creado
      await _notif.showSessionReminder(
        exerciseLabel: exercise == 'squat' ? 'Sentadilla' : 'Ejercicio',
        prescription: _plan?.todaySession?.prescription ?? 'Plan creado',
      );
    } catch (e) {
      _error = _friendly(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> advanceWeek() async {
    if (_plan == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _repo.advanceWeek(_plan!.planId);
      // Recargar plan completo
      await loadActivePlan(exercise: _plan!.exerciseType);
    } catch (e) {
      _error = _friendly(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VBTResultModel?> submitVBTFeedback({
    required double velocity,
    required double weightUsed,
    required int repsDone,
  }) async {
    if (_plan == null) return null;
    try {
      final data = await _repo.vbtFeedback(
        planId: _plan!.planId,
        weekNumber: currentWeek,
        velocity: velocity,
        weightUsed: weightUsed,
        repsDone: repsDone,
      );
      final result = VBTResultModel.fromJson(data);
      // Si el 1RM mejoró, notificar
      if (data['predicted_1rm'] != null) {
        final predicted = (data['predicted_1rm'] as num).toDouble();
        if (predicted > (_personalBest ?? 0) * 1.01) {
          _personalBest = predicted;
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      _error = _friendly(e);
      notifyListeners();
      return null;
    }
  }

  void clearError() { _error = null; notifyListeners(); }

  String _friendly(dynamic e) {
    final s = e.toString();
    if (s.contains('400')) return 'No tienes registros de 1RM aún. Analiza un video primero.';
    if (s.contains('404')) return 'No encontrado. Crea un plan primero.';
    if (s.contains('Connection')) return 'Sin conexión al servidor.';
    return 'Error inesperado. Intenta de nuevo.';
  }
}
