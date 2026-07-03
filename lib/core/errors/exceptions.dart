/// Excepciones custom de la aplicación.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;
  const ValidationException(super.message, {this.errors, super.code});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

class PermissionException extends AppException {
  const PermissionException([String message = 'Acceso denegado'])
      : super(message);
}
