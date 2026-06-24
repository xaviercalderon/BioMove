// services/settings_service.dart — Preferencias de la app
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio central de preferencias del usuario (funciones opcionales).
/// Se persiste en SharedPreferences y notifica cambios a la UI.
class SettingsService extends ChangeNotifier {
  static final SettingsService _i = SettingsService._();
  factory SettingsService() => _i;
  SettingsService._();

  // Valores por defecto
  bool   _notifications   = true;     // notificaciones de análisis
  String _units           = 'kg';     // 'kg' | 'lb'
  String _defaultView     = 'auto';   // 'auto' | 'lateral' | 'frontal'
  String _analysisQuality = 'precise';// 'fast' | 'precise'
  bool   _shareWithCoach  = false;    // compartir con coach por defecto
  String _language        = 'es';     // 'es' | 'en'

  bool   get notifications   => _notifications;
  String get units           => _units;
  String get defaultView     => _defaultView;
  String get analysisQuality => _analysisQuality;
  bool   get shareWithCoach  => _shareWithCoach;
  String get language        => _language;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _notifications   = p.getBool('set_notifications') ?? true;
    _units           = p.getString('set_units') ?? 'kg';
    _defaultView     = p.getString('set_default_view') ?? 'auto';
    _analysisQuality = p.getString('set_quality') ?? 'precise';
    _shareWithCoach  = p.getBool('set_share_coach') ?? false;
    _language        = p.getString('set_language') ?? 'es';
    notifyListeners();
  }

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    (await SharedPreferences.getInstance()).setBool('set_notifications', v);
    notifyListeners();
  }

  Future<void> setUnits(String v) async {
    _units = v;
    (await SharedPreferences.getInstance()).setString('set_units', v);
    notifyListeners();
  }

  Future<void> setDefaultView(String v) async {
    _defaultView = v;
    (await SharedPreferences.getInstance()).setString('set_default_view', v);
    notifyListeners();
  }

  Future<void> setAnalysisQuality(String v) async {
    _analysisQuality = v;
    (await SharedPreferences.getInstance()).setString('set_quality', v);
    notifyListeners();
  }

  Future<void> setShareWithCoach(bool v) async {
    _shareWithCoach = v;
    (await SharedPreferences.getInstance()).setBool('set_share_coach', v);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    (await SharedPreferences.getInstance()).setString('set_language', v);
    notifyListeners();
  }

  /// Convierte kg a la unidad seleccionada para mostrar.
  double displayWeight(double kg) => _units == 'lb' ? kg * 2.20462 : kg;
  String get weightUnit => _units;
}
