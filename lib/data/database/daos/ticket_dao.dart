import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';

part 'ticket_dao.g.dart';

const _uuid = Uuid();

/// DAO de tickets — fusión de Alfred + Anny TicketController.php.
/// Incluye el sistema de Payment de Anny.
@DriftAccessor(tables: [Tickets, TicketTypes, Events, Payments, Attendances, Users])
class TicketDao extends DatabaseAccessor<AppDatabase> with _$TicketDaoMixin {
  TicketDao(super.db);

  /// Comprar ticket — versión Anny con payment_method.
  Future<Ticket> purchase({
    required int userId,
    required int ticketTypeId,
    String paymentMethod = 'qr',
  }) async {
    return transaction(() async {
      final ticketType = await (select(ticketTypes)
        ..where((t) => t.id.equals(ticketTypeId)))
          .getSingle();

      // Verificar stock
      if (ticketType.stock <= 0) {
        throw Exception('No hay tickets disponibles');
      }

      // Verificar evento activo
      final event = await (select(events)
        ..where((e) => e.id.equals(ticketType.eventId)))
          .getSingle();

      if (event.status != 'active') {
        throw Exception('El evento no está disponible');
      }

      // Estado según método de pago (lógica de Anny)
      final status = (paymentMethod == 'efectivo') ? 'pending' : 'paid';
      final ticketCode = 'TKP-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final qrToken = _uuid.v4();

      // Crear ticket
      final ticketId = await into(tickets).insert(TicketsCompanion.insert(
        userId: userId,
        eventId: ticketType.eventId,
        ticketTypeId: ticketTypeId,
        ticketCode: ticketCode,
        qrToken: qrToken,
        status: Value(status),
      ));

      // Registrar pago (de Anny)
      await into(payments).insert(PaymentsCompanion.insert(
        ticketId: ticketId,
        amount: ticketType.price,
        paymentMethod: Value(paymentMethod),
        status: Value(status == 'paid' ? 'completed' : 'pending'),
      ));

      // Decrementar stock
      await (update(ticketTypes)..where((t) => t.id.equals(ticketTypeId))).write(
        TicketTypesCompanion(stock: Value(ticketType.stock - 1)),
      );
      await (update(events)..where((e) => e.id.equals(ticketType.eventId))).write(
        EventsCompanion(ticketsAvailable: Value(event.ticketsAvailable - 1)),
      );

      return (select(tickets)..where((t) => t.id.equals(ticketId))).getSingle();
    });
  }

  /// Mis tickets.
  Future<List<Ticket>> getMyTickets(int userId) async {
    return (select(tickets)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Ver un ticket.
  Future<Ticket?> getTicket(int id, int userId) async {
    return (select(tickets)
      ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Validar QR.
  Future<Map<String, dynamic>> validateQR(String qrToken, int validatedBy) async {
    return transaction(() async {
      final ticket = await (select(tickets)
        ..where((t) => t.qrToken.equals(qrToken)))
          .getSingleOrNull();

      if (ticket == null) {
        return {'valid': false, 'message': 'QR inválido'};
      }

      if (ticket.status == 'used') {
        return {'valid': false, 'message': 'Ticket ya fue usado', 'ticket': ticket};
      }

      if (ticket.status != 'paid') {
        return {'valid': false, 'message': 'Ticket no válido', 'ticket': ticket};
      }

      // Marcar como usado
      await (update(tickets)..where((t) => t.id.equals(ticket.id))).write(
        UsersCompanion() is TicketsCompanion ? const TicketsCompanion() :
        TicketsCompanion(
          status: const Value('used'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (update(tickets)..where((t) => t.id.equals(ticket.id))).write(
        TicketsCompanion(
          status: const Value('used'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Registrar asistencia
      await into(attendances).insert(AttendancesCompanion.insert(
        ticketId: ticket.id,
        checkinTime: DateTime.now(),
        validatedBy: validatedBy,
      ));

      return {'valid': true, 'message': 'Ticket válido ✅', 'ticket': ticket};
    });
  }

  /// Obtener todos los tickets (Admin).
  Future<List<Ticket>> getAllTickets() async {
    return (select(tickets)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Obtener evento de un ticket.
  Future<Event> getTicketEvent(int eventId) async {
    return (select(events)..where((e) => e.id.equals(eventId))).getSingle();
  }

  /// Obtener tipo de ticket.
  Future<TicketType> getTicketType(int typeId) async {
    return (select(ticketTypes)..where((t) => t.id.equals(typeId))).getSingle();
  }

  /// Obtener usuario de un ticket.
  Future<User> getTicketUser(int userId) async {
    return (select(users)..where((u) => u.id.equals(userId))).getSingle();
  }
}
