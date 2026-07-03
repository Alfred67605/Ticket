import 'package:flutter/foundation.dart';

/// Logger global de la aplicación.
class AppLogger {
  AppLogger._();

  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String tag, dynamic error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ [$tag] ERROR: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$tag] $message');
    }
  }

  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [$tag] $message');
    }
  }

  static void success(String tag, String message) {
    if (kDebugMode) {
      debugPrint('✅ [$tag] $message');
    }
  }
}
