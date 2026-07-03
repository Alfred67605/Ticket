import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/repositories/storage_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/ticket_repository.dart';
import '../data/repositories/admin_repository.dart';

/// Configuración de inyección de dependencias unificada.
class DependencyInjection {
  DependencyInjection._();

  /// Inicializa los servicios asíncronos básicos (ej. SharedPreferences).
  static Future<List<SingleChildWidget>> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Base de datos (Drift SQLite local)
    final database = AppDatabase.instance;

    // Repositorios y DAOs
    final storageRepo = StorageRepository(prefs);
    final authRepo = AuthRepository(database.authDao, storageRepo);
    final eventRepo = EventRepository(database.eventDao);
    final ticketRepo = TicketRepository(database.ticketDao, storageRepo);
    final adminRepo = AdminRepository(database.adminDao, storageRepo);

    return [
      Provider<AppDatabase>.value(value: database),
      Provider<StorageRepository>.value(value: storageRepo),
      Provider<AuthRepository>.value(value: authRepo),
      Provider<EventRepository>.value(value: eventRepo),
      Provider<TicketRepository>.value(value: ticketRepo),
      Provider<AdminRepository>.value(value: adminRepo),
    ];
  }
}
