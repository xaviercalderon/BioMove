// viewmodel/best_rep_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/best_rep_model.dart';
import '../core/utils/app_constants.dart';

class BestRepViewModel extends ChangeNotifier {
  BestRepModel? _best;
  BestRepModel? _worst;
  bool   _isLoading = false;
  String? _error;

  BestRepModel? get best      => _best;
  BestRepModel? get worst     => _worst;
  bool          get isLoading => _isLoading;
  String?       get error     => _error;

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 1),
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken(false);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
      } catch (_) {}
      handler.next(options);
    },
  ));

  Future<void> load(String exercise) async {
    _isLoading = true; _error = null;
    notifyListeners();
    try {
      final r = await _dio.get('/best-reps/$exercise');
      final data = r.data as Map<String, dynamic>;
      final bestJson  = data['best']  as Map<String, dynamic>?;
      final worstJson = data['worst'] as Map<String, dynamic>?;
      _best  = bestJson  != null ? BestRepModel.fromJson(bestJson)  : null;
      _worst = worstJson != null ? BestRepModel.fromJson(worstJson) : null;
    } catch (e) {
      _error = e.toString().contains('404') ? null : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
