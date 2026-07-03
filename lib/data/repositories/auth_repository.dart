import '../database/app_database.dart';
import '../database/daos/auth_dao.dart';
import 'storage_repository.dart';

class AuthRepository {
  final AuthDao _authDao;
  final StorageRepository _storage;

  AuthRepository(this._authDao, this._storage);

  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final user = await _authDao.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    final role = await _authDao.getUserRole(user.roleId);
    
    // Generar un token local ficticio para mantener el comportamiento de sesión
    final mockToken = 'local_session_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.saveSession(token: mockToken, userId: user.id, role: role.name);
    
    return user;
  }

  Future<User> login({
    required String login,
    required String password,
  }) async {
    final user = await _authDao.login(login: login, password: password);
    final role = await _authDao.getUserRole(user.roleId);

    final mockToken = 'local_session_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.saveSession(token: mockToken, userId: user.id, role: role.name);

    return user;
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<User?> getCurrentUser() async {
    final id = _storage.getUserId();
    if (id == null) return null;
    try {
      return await _authDao.getProfile(id);
    } catch (_) {
      return null;
    }
  }

  Future<User> updateProfile({String? name, String? phone}) async {
    final id = _storage.getUserId();
    if (id == null) throw Exception('No hay sesión iniciada');
    return _authDao.updateProfile(id, name: name, phone: phone);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final id = _storage.getUserId();
    if (id == null) throw Exception('No hay sesión iniciada');
    await _authDao.changePassword(id, currentPassword, newPassword);
  }

  Future<void> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    await _authDao.resetPassword(email: email, phone: phone, newPassword: newPassword);
  }

  bool isLoggedIn() => _storage.isLoggedIn();
  String? getUserRole() => _storage.getUserRole();
}
