// services/haptic_service.dart
import 'package:flutter/services.dart';
class HapticService {
  static Future<void> light()   => HapticFeedback.lightImpact();
  static Future<void> medium()  => HapticFeedback.mediumImpact();
  static Future<void> heavy()   => HapticFeedback.heavyImpact();
  static Future<void> success() => HapticFeedback.lightImpact();
  static Future<void> error()   => HapticFeedback.heavyImpact();
  static Future<void> select()  => HapticFeedback.selectionClick();
}
