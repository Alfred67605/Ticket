import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'event_dao.g.dart';

/// DAO de eventos — reemplaza EventController.php de Laravel.
/// Usa la versión más completa de Alfred (con media_preference + transactions).
@DriftAccessor(tables: [Events, TicketTypes, Presales, Artists, EventArtists])
class EventDao extends DatabaseAccessor<AppDatabase> with _$EventDaoMixin {
  EventDao(super.db);

  /// Listar eventos con filtros.
  Future<List<Event>> getEvents({String? category, bool showAll = false}) async {
    final query = select(events)..orderBy([(e) => OrderingTerm.asc(e.eventDate)]);

    if (category != null && category != 'Todos') {
      query.where((e) => e.category.equals(category));
    }
    if (!showAll) {
      query.where((e) => e.status.equals('active'));
    }

    return query.get();
  }

  /// Obtener un evento por ID.
  Future<Event> getEvent(int id) async {
    return (select(events)..where((e) => e.id.equals(id))).getSingle();
  }

  /// Obtener tipos de ticket de un evento.
  Future<List<TicketType>> getTicketTypes(int eventId) async {
    return (select(ticketTypes)..where((t) => t.eventId.equals(eventId))).get();
  }

  /// Obtener preventa activa de un evento.
  Future<Presale?> getActivePresale(int eventId, {int? ticketTypeId}) async {
    final now = DateTime.now();
    final query = select(presales)
      ..where((p) =>
        p.eventId.equals(eventId) &
        p.isActive.equals(true) &
        p.startDate.isSmallerOrEqualValue(now) &
        p.endDate.isBiggerOrEqualValue(now));

    if (ticketTypeId != null) {
      query.where((p) => p.ticketTypeId.equals(ticketTypeId) | p.ticketTypeId.isNull());
    }

    return query.getSingleOrNull();
  }

  /// Obtener artistas de un evento.
  Future<List<Artist>> getEventArtists(int eventId) async {
    final query = select(artists).join([
      innerJoin(eventArtists, eventArtists.artistId.equalsExp(artists.id)),
    ])..where(eventArtists.eventId.equals(eventId));

    return query.map((row) => row.readTable(artists)).get();
  }

  /// Crear evento (Admin).
  Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required int capacity,
    String? organizer,
    String? category,
    String? imagePath,
    String? videoPath,
    String mediaPreference = 'both',
    required List<Map<String, dynamic>> ticketTypesList,
    DateTime? presaleStart,
    DateTime? presaleEnd,
    double? presalePrice,
  }) async {
    return transaction(() async {
      final eventId = await into(events).insert(EventsCompanion.insert(
        title: title,
        description: description,
        location: location,
        eventDate: eventDate,
        capacity: capacity,
        ticketsAvailable: capacity,
        organizer: Value(organizer ?? 'Gobernación de Potosí'),
        category: Value(category ?? 'General'),
        image: Value(imagePath),
        video: Value(videoPath),
        mediaPreference: Value(mediaPreference),
        status: const Value('active'),
      ));

      // Crear tipos de ticket
      for (final tt in ticketTypesList) {
        await into(ticketTypes).insert(TicketTypesCompanion.insert(
          eventId: eventId,
          name: tt['name'] as String,
          price: (tt['price'] as num).toDouble(),
          stock: tt['stock'] as int,
        ));
      }

      // Crear preventa si se especificó
      if (presaleStart != null && presaleEnd != null && presalePrice != null) {
        await into(presales).insert(PresalesCompanion.insert(
          eventId: eventId,
          startDate: presaleStart,
          endDate: presaleEnd,
          presalePrice: presalePrice,
          isActive: const Value(true),
        ));
      }

      return (select(events)..where((e) => e.id.equals(eventId))).getSingle();
    });
  }

  /// Actualizar evento (Admin) — versión completa de Alfred con transactions.
  Future<Event> updateEvent(
    int id, {
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? organizer,
    String? category,
    String? status,
    int? capacity,
    String? imagePath,
    String? videoPath,
    String? mediaPreference,
    List<Map<String, dynamic>>? ticketTypesList,
    DateTime? presaleStart,
    DateTime? presaleEnd,
    double? presalePrice,
  }) async {
    return transaction(() async {
      await (update(events)..where((e) => e.id.equals(id))).write(EventsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        location: location != null ? Value(location) : const Value.absent(),
        eventDate: eventDate != null ? Value(eventDate) : const Value.absent(),
        organizer: organizer != null ? Value(organizer) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        capacity: capacity != null ? Value(capacity) : const Value.absent(),
        image: imagePath != null ? Value(imagePath) : const Value.absent(),
        video: videoPath != null ? Value(videoPath) : const Value.absent(),
        mediaPreference: mediaPreference != null ? Value(mediaPreference) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));

      // Actualizar ticket types (lógica de Alfred con upsert)
      if (ticketTypesList != null) {
        final incomingIds = <int>[];
        for (final tt in ticketTypesList) {
          final existingId = tt['id'] as int?;
          if (existingId != null && existingId > 0) {
            await (update(ticketTypes)
              ..where((t) => t.id.equals(existingId) & t.eventId.equals(id)))
                .write(TicketTypesCompanion(
              name: Value(tt['name'] as String),
              price: Value((tt['price'] as num).toDouble()),
              stock: Value(tt['stock'] as int),
            ));
            incomingIds.add(existingId);
          } else {
            final newId = await into(ticketTypes).insert(TicketTypesCompanion.insert(
              eventId: id,
              name: tt['name'] as String,
              price: (tt['price'] as num).toDouble(),
              stock: tt['stock'] as int,
            ));
            incomingIds.add(newId);
          }
        }
        // Eliminar tipos no presentes
        if (incomingIds.isNotEmpty) {
          await (delete(ticketTypes)
            ..where((t) => t.eventId.equals(id) & t.id.isNotIn(incomingIds)))
              .go();
        }
      }

      // Actualizar preventa
      if (presaleStart != null && presaleEnd != null && presalePrice != null) {
        final existingPresale = await (select(presales)
          ..where((p) => p.eventId.equals(id)))
            .getSingleOrNull();

        if (existingPresale != null) {
          await (update(presales)..where((p) => p.eventId.equals(id))).write(
            PresalesCompanion(
              startDate: Value(presaleStart),
              endDate: Value(presaleEnd),
              presalePrice: Value(presalePrice),
              isActive: const Value(true),
            ),
          );
        } else {
          await into(presales).insert(PresalesCompanion.insert(
            eventId: id,
            startDate: presaleStart,
            endDate: presaleEnd,
            presalePrice: presalePrice,
            isActive: const Value(true),
          ));
        }
      }

      return getEvent(id);
    });
  }

  /// Eliminar evento.
  Future<void> deleteEvent(int id) async {
    await transaction(() async {
      await (delete(presales)..where((p) => p.eventId.equals(id))).go();
      await (delete(ticketTypes)..where((t) => t.eventId.equals(id))).go();
      await (delete(eventArtists)..where((ea) => ea.eventId.equals(id))).go();
      await (delete(events)..where((e) => e.id.equals(id))).go();
    });
  }
}
