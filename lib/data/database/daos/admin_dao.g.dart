// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_dao.dart';

// ignore_for_file: type=lint
mixin _$AdminDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventsTable get events => attachedDatabase.events;
  $RolesTable get roles => attachedDatabase.roles;
  $UsersTable get users => attachedDatabase.users;
  $TicketTypesTable get ticketTypes => attachedDatabase.ticketTypes;
  $TicketsTable get tickets => attachedDatabase.tickets;
  $PromotionsTable get promotions => attachedDatabase.promotions;
  $PaymentsTable get payments => attachedDatabase.payments;
  $AttendancesTable get attendances => attachedDatabase.attendances;
  AdminDaoManager get managers => AdminDaoManager(this);
}

class AdminDaoManager {
  final _$AdminDaoMixin _db;
  AdminDaoManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db.attachedDatabase, _db.events);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db.attachedDatabase, _db.roles);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$TicketTypesTableTableManager get ticketTypes =>
      $$TicketTypesTableTableManager(_db.attachedDatabase, _db.ticketTypes);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db.attachedDatabase, _db.tickets);
  $$PromotionsTableTableManager get promotions =>
      $$PromotionsTableTableManager(_db.attachedDatabase, _db.promotions);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$AttendancesTableTableManager get attendances =>
      $$AttendancesTableTableManager(_db.attachedDatabase, _db.attendances);
}
