import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/auth_dao.dart';
import 'daos/event_dao.dart';
import 'daos/ticket_dao.dart';
import 'daos/admin_dao.dart';

part 'app_database.g.dart';

/// Base de datos embebida de TicketPotosí.
/// Reemplaza completamente a Laravel + SQLite externo.
@DriftDatabase(
  tables: [
    Roles,
    Users,
    Events,
    TicketTypes,
    Presales,
    Promotions,
    Tickets,
    Payments,
    Artists,
    EventArtists,
    Attendances,
  ],
  daos: [AuthDao, EventDao, TicketDao, AdminDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Seed inicial: roles
      await into(roles).insert(RolesCompanion.insert(name: 'Admin'));
      await into(roles).insert(RolesCompanion.insert(name: 'Cliente'));
      // Crear admin por defecto
      await into(users).insert(UsersCompanion.insert(
        name: 'Administrador',
        email: 'admin@ticketpotosi.com',
        password: '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // sha256('admin123')
        phone: const Value('70000000'),
        roleId: const Value(1),
        status: const Value('active'),
      ));
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Futuras migraciones aquí
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ticket_potosi.db'));
    return NativeDatabase.createInBackground(file);
  });
}
