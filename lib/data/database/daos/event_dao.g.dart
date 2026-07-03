// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_dao.dart';

// ignore_for_file: type=lint
mixin _$EventDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventsTable get events => attachedDatabase.events;
  $TicketTypesTable get ticketTypes => attachedDatabase.ticketTypes;
  $PresalesTable get presales => attachedDatabase.presales;
  $ArtistsTable get artists => attachedDatabase.artists;
  $EventArtistsTable get eventArtists => attachedDatabase.eventArtists;
  EventDaoManager get managers => EventDaoManager(this);
}

class EventDaoManager {
  final _$EventDaoMixin _db;
  EventDaoManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db.attachedDatabase, _db.events);
  $$TicketTypesTableTableManager get ticketTypes =>
      $$TicketTypesTableTableManager(_db.attachedDatabase, _db.ticketTypes);
  $$PresalesTableTableManager get presales =>
      $$PresalesTableTableManager(_db.attachedDatabase, _db.presales);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db.attachedDatabase, _db.artists);
  $$EventArtistsTableTableManager get eventArtists =>
      $$EventArtistsTableTableManager(_db.attachedDatabase, _db.eventArtists);
}
