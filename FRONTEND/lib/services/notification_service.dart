// services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Callback para navegar al tocar una notificación.
  /// Se asigna en main.dart: NotificationService.onTap = (route) => router.go(route);
  static void Function(String route)? onTap;

  static const _channelId   = 'biomove_analysis';
  static const _channelName = 'Análisis BioMove';
  static const _progressId  = 1;
  static const _completeId  = 2;
  static const _sessionId   = 3;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        // Al tocar la notificación navega a la ruta del payload
        final route = details.payload ?? '/results';
        onTap?.call(route);
      },
    );
    _initialized = true;
  }

  Future<void> showProgress({required int percent, required String exerciseLabel}) async {
    await init();
    final color = percent < 40
        ? const Color(0xFF6C63FF)
        : percent < 80 ? const Color(0xFF00D4AA) : const Color(0xFF4CAF50);
    final androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: 'Progreso del análisis biomecánico',
      importance: Importance.low, priority: Priority.low,
      ongoing: true, showProgress: true,
      maxProgress: 100, progress: percent,
      color: color, icon: '@mipmap/ic_launcher',
      subText: '$percent% completado',
    );
    await _plugin.show(_progressId,
      '🏋️ Analizando $exerciseLabel',
      _progressMsg(percent),
      NotificationDetails(android: androidDetails));
  }

  Future<void> showCompleted({
    required String exerciseLabel,
    required double score,
    required int totalReps,
  }) async {
    await init();
    await _plugin.cancel(_progressId);
    final label = score >= 88 ? '🏆 Excelente'
        : score >= 75 ? '✅ Buena técnica'
        : score >= 60 ? '👍 Técnica aceptable'
        : '⚠️ Necesita mejoras';
    final androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      importance: Importance.high, priority: Priority.high,
      color: const Color(0xFF00D4AA), icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '$label\n$totalReps repeticiones analizadas\nToca para ver el informe completo',
        contentTitle: '✅ Análisis listo — ${score.toStringAsFixed(0)}/100',
      ),
    );
    await _plugin.show(_completeId,
      '✅ Análisis listo — ${score.toStringAsFixed(0)}/100',
      '$label · $totalReps reps',
      NotificationDetails(android: androidDetails),
      payload: '/results');
  }

  Future<void> showSessionReminder({
    required String exerciseLabel,
    required String prescription,
  }) async {
    await init();
    final androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      importance: Importance.high, priority: Priority.high,
      color: const Color(0xFF6C63FF), icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(_sessionId,
      '💪 Hoy toca $exerciseLabel',
      prescription,
      NotificationDetails(android: androidDetails));
  }

  Future<void> showError(String message) async {
    await init();
    await _plugin.cancel(_progressId);
    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      importance: Importance.high, priority: Priority.high,
      color: Color(0xFFFF5252),
    );
    await _plugin.show(_progressId, '❌ Error en el análisis',
        message, const NotificationDetails(android: androidDetails));
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  String _progressMsg(int pct) {
    if (pct < 20) return 'Extrayendo poses con MediaPipe...';
    if (pct < 50) return 'Detectando repeticiones...';
    if (pct < 80) return 'Calculando 40 parámetros biomecánicos...';
    if (pct < 95) return 'Generando video anotado...';
    return '¡Casi listo! Guardando resultados...';
  }
}
