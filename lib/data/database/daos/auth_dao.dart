import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../app_database.dart';
import '../tables.dart';

part 'auth_dao.g.dart';

/// DAO de autenticación — reemplaza AuthController.php de Laravel.
@DriftAccessor(tables: [Users, Roles])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(super.db);

  /// Hash SHA-256 para contraseñas.
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Registrar nuevo usuario.
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    // Verificar que el email no exista
    final existing = await (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
    if (existing != null) {
      throw Exception('El correo electrónico ya está registrado');
    }

    final id = await into(users).insert(UsersCompanion.insert(
      name: name,
      email: email,
      password: _hashPassword(password),
      phone: Value(phone),
      roleId: const Value(2), // Cliente por defecto
      status: const Value('active'),
    ));

    return (select(users)..where((u) => u.id.equals(id))).getSingle();
  }

  /// Iniciar sesión (email o teléfono).
  Future<User> login({
    required String login,
    required String password,
  }) async {
    // Asegurar roles iniciales
    final rolesList = await select(roles).get();
    if (rolesList.isEmpty) {
      await into(roles).insert(RolesCompanion.insert(name: 'Admin'));
      await into(roles).insert(RolesCompanion.insert(name: 'Cliente'));
    }

    // Asegurar administrador por defecto
    final admins = await (select(users)..where((u) => u.email.equals('admin@ticketpotosi.com'))).get();
    if (admins.isEmpty) {
      await into(users).insert(UsersCompanion.insert(
        name: 'Administrador',
        email: 'admin@ticketpotosi.com',
        password: _hashPassword('admin123'),
        phone: const Value('70000000'),
        roleId: const Value(1),
        status: const Value('active'),
      ));
    }

    final hashedPassword = _hashPassword(password);

    // Buscar por email
    var user = await (select(users)..where((u) => u.email.equals(login))).getSingleOrNull();

    // Si no encuentra, buscar por teléfono
    user ??= await (select(users)..where((u) => u.phone.equals(login))).getSingleOrNull();

    if (user == null) {
      throw Exception('Credenciales incorrectas. Verifica tu email/teléfono y contraseña.');
    }

    if (user.password != hashedPassword) {
      throw Exception('Credenciales incorrectas. Verifica tu email/teléfono y contraseña.');
    }

    if (user.status == 'inactive') {
      throw Exception('Tu cuenta está desactivada. Contacta al administrador.');
    }

    return user;
  }

  /// Obtener perfil del usuario.
  Future<User> getProfile(int userId) async {
    return (select(users)..where((u) => u.id.equals(userId))).getSingle();
  }

  /// Obtener rol del usuario.
  Future<Role> getUserRole(int roleId) async {
    return (select(roles)..where((r) => r.id.equals(roleId))).getSingle();
  }

  /// Actualizar perfil.
  Future<User> updateProfile(int userId, {String? name, String? phone}) async {
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return getProfile(userId);
  }

  /// Cambiar contraseña.
  Future<void> changePassword(int userId, String currentPassword, String newPassword) async {
    final user = await getProfile(userId);
    if (user.password != _hashPassword(currentPassword)) {
      throw Exception('Contraseña actual incorrecta');
    }
    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        password: Value(_hashPassword(newPassword)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Recuperar contraseña sin token (de Anny).
  Future<void> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    final user = await (select(users)
      ..where((u) => u.email.equals(email) & u.phone.equals(phone)))
        .getSingleOrNull();

    if (user == null) {
      throw Exception('El número de celular no coincide con el correo registrado.');
    }

    await (update(users)..where((u) => u.id.equals(user.id))).write(
      UsersCompanion(
        password: Value(_hashPassword(newPassword)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Verificar si es admin.
  Future<bool> isAdmin(int userId) async {
    final user = await getProfile(userId);
    return user.roleId == 1;
  }
}
