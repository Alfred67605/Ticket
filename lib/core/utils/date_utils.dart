import 'package:intl/intl.dart';

/// Utilidades para formateo de fechas.
class AppDateUtils {
  AppDateUtils._();

  static final _fullFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _dateOnly = DateFormat('dd/MM/yyyy');
  static final _timeOnly = DateFormat('HH:mm');
  static final _monthDay = DateFormat('dd MMM', 'es');
  static final _fullMonth = DateFormat('dd MMMM yyyy', 'es');
  static final _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// "02/07/2026 16:30"
  static String formatFull(String isoDate) {
    try {
      return _fullFormat.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate.replaceAll('T', ' ').substring(0, 16);
    }
  }

  /// "02/07/2026"
  static String formatDate(String isoDate) {
    try {
      return _dateOnly.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate.split('T').first;
    }
  }

  /// "16:30"
  static String formatTime(String isoDate) {
    try {
      return _timeOnly.format(DateTime.parse(isoDate));
    } catch (_) {
      return '';
    }
  }

  /// "02 Jul"
  static String formatShort(String isoDate) {
    try {
      return _monthDay.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// "02 Julio 2026"
  static String formatLong(String isoDate) {
    try {
      return _fullMonth.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  /// Convierte DateTime a ISO string para la BD.
  static String toIso(DateTime date) => _isoFormat.format(date);

  /// Tiempo relativo: "Hace 2 horas", "En 3 días"
  static String timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.isNegative) {
        // Futuro
        final absDiff = diff.abs();
        if (absDiff.inDays > 30) return 'En ${absDiff.inDays ~/ 30} meses';
        if (absDiff.inDays > 0) return 'En ${absDiff.inDays} días';
        if (absDiff.inHours > 0) return 'En ${absDiff.inHours} horas';
        return 'En ${absDiff.inMinutes} min';
      } else {
        // Pasado
        if (diff.inDays > 30) return 'Hace ${diff.inDays ~/ 30} meses';
        if (diff.inDays > 0) return 'Hace ${diff.inDays} días';
        if (diff.inHours > 0) return 'Hace ${diff.inHours} horas';
        if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} min';
        return 'Ahora';
      }
    } catch (_) {
      return isoDate;
    }
  }
}
