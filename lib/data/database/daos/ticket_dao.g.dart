// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dao.dart';

// ignore_for_file: type=lint
mixin _$TicketDaoMixin on DatabaseAccessor<AppDatabase> {
  $RolesTable get roles => attachedDatabase.roles;
  $UsersTable get users => attachedDatabase.users;
  $EventsTable get events => attachedDatabase.events;
  $TicketTypesTable get ticketTypes => attachedDatabase.ticketTypes;
  $TicketsTable get tickets => attachedDatabase.tickets;
  $PaymentsTable get payments => attachedDatabase.payments;
  $AttendancesTable get attendances => attachedDatabase.attendances;
  TicketDaoManager get managers => TicketDaoManager(this);
}

class TicketDaoManager {
  final _$TicketDaoMixin _db;
  TicketDaoManager(this._db);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db.attachedDatabase, _db.roles);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db.attachedDatabase, _db.events);
  $$TicketTypesTableTableManager get ticketTypes =>
      $$TicketTypesTableTableManager(_db.attachedDatabase, _db.ticketTypes);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db.attachedDatabase, _db.tickets);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$AttendancesTableTableManager get attendances =>
      $$AttendancesTableTableManager(_db.attachedDatabase, _db.attendances);
}
