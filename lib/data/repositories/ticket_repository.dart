import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/ticket_dao.dart';
import '../models/ticket_model.dart';
import 'storage_repository.dart';

class TicketRepository {
  final TicketDao _ticketDao;
  final StorageRepository _storage;

  TicketRepository(this._ticketDao, this._storage);

  Future<TicketModel> purchase({
    required int ticketTypeId,
    String paymentMethod = 'qr',
  }) async {
    final userId = _storage.getUserId();
    if (userId == null) throw Exception('Sesión no válida');

    final ticket = await _ticketDao.purchase(
      userId: userId,
      ticketTypeId: ticketTypeId,
      paymentMethod: paymentMethod,
    );

    return _loadTicketDetails(ticket);
  }

  Future<List<TicketModel>> getMyTickets() async {
    final userId = _storage.getUserId();
    if (userId == null) return [];

    final rawTickets = await _ticketDao.getMyTickets(userId);
    final List<TicketModel> detailedTickets = [];

    for (final ticket in rawTickets) {
      final detailed = await _loadTicketDetails(ticket);
      detailedTickets.add(detailed);
    }

    return detailedTickets;
  }

  Future<TicketModel?> getTicketDetails(int id) async {
    final userId = _storage.getUserId();
    if (userId == null) return null;

    final ticket = await _ticketDao.getTicket(id, userId);
    if (ticket == null) return null;

    return _loadTicketDetails(ticket);
  }

  Future<Map<String, dynamic>> validateQR(String qrToken) async {
    final validatorId = _storage.getUserId();
    if (validatorId == null) throw Exception('Usuario validador no identificado');

    final result = await _ticketDao.validateQR(qrToken, validatorId);
    if (result['valid'] == true) {
      final ticket = result['ticket'] as Ticket;
      final detailed = await _loadTicketDetails(ticket);
      return {
        'valid': true,
        'message': result['message'],
        'ticket': detailed,
      };
    }
    return result;
  }

  Future<List<TicketModel>> getAllTickets() async {
    final rawTickets = await _ticketDao.getAllTickets();
    final List<TicketModel> detailedTickets = [];

    for (final ticket in rawTickets) {
      final detailed = await _loadTicketDetails(ticket);
      detailedTickets.add(detailed);
    }

    return detailedTickets;
  }

  Future<TicketModel> _loadTicketDetails(Ticket ticket) async {
    final event = await _ticketDao.getTicketEvent(ticket.eventId);
    final type = await _ticketDao.getTicketType(ticket.ticketTypeId);
    final user = await _ticketDao.getTicketUser(ticket.userId);

    // Obtener pago relacionado
    final db = _ticketDao.attachedDatabase;
    final payment = await (db.select(db.payments)..where((p) => p.ticketId.equals(ticket.id))).getSingleOrNull();

    return TicketModel(
      ticket: ticket,
      event: event,
      ticketType: type,
      payment: payment,
      user: user,
    );
  }
}
