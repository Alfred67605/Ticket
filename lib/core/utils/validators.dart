/// Validaciones centralizadas para formularios.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Correo electrónico inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es requerido';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 7) return 'Número de teléfono inválido';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
    if (value.trim().length < 2) return 'Nombre demasiado corto';
    return null;
  }

  static String? number(String? value, {String field = 'Este campo', double min = 0}) {
    if (value == null || value.trim().isEmpty) return '$field es requerido';
    final parsed = double.tryParse(value);
    if (parsed == null) return '$field debe ser un número';
    if (parsed < min) return '$field debe ser al menos $min';
    return null;
  }

  static String? integer(String? value, {String field = 'Este campo', int min = 1}) {
    if (value == null || value.trim().isEmpty) return '$field es requerido';
    final parsed = int.tryParse(value);
    if (parsed == null) return '$field debe ser un número entero';
    if (parsed < min) return '$field debe ser al menos $min';
    return null;
  }
}
