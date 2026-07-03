import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/daos/admin_dao.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import 'storage_repository.dart';

class AdminRepository {
  final AdminDao _adminDao;
  final StorageRepository _storage;

  AdminRepository(this._adminDao, this._storage);

  /// Obtener estadísticas de administración para el dashboard.
  Future<Map<String, dynamic>> getDashboardStats() async {
    final currentUserId = _storage.getUserId();
    if (currentUserId == null) throw Exception('Sesión inválida');
    
    final data = await _adminDao.getDashboard();
    
    // Convertir la lista de Eventos en EventModel
    final List<EventModel> detailedEvents = [];
    final List<Event> recentEvents = data['recent_events'] as List<Event>;
    
    final db = _adminDao.attachedDatabase;
    for (final ev in recentEvents) {
      final types = await (db.select(db.ticketTypes)..where((t) => t.eventId.equals(ev.id))).get();
      final presale = await (db.select(db.presales)..where((p) => p.eventId.equals(ev.id))).getSingleOrNull();
      final artists = await (db.select(db.artists).join([
        innerJoin(db.eventArtists, db.eventArtists.artistId.equalsExp(db.artists.id)),
      ])..where(db.eventArtists.eventId.equals(ev.id))).map((row) => row.readTable(db.artists)).get();

      detailedEvents.add(EventModel(
        event: ev,
        ticketTypes: types,
        presale: presale,
        artists: artists,
      ));
    }

    return {
      'total_tickets': data['total_tickets'],
      'used_tickets': data['used_tickets'],
      'total_events': data['total_events'],
      'total_users': data['total_users'],
      'total_revenue': data['total_revenue'],
      'recent_events': detailedEvents,
      'sales_by_day': data['sales_by_day'],
    };
  }

  /// Listar usuarios de la plataforma.
  Future<List<User>> getUsers() async {
    return _adminDao.getUsers();
  }

  /// Activar/desactivar estado de un usuario.
  Future<User> toggleUserStatus(int userId) async {
    final currentUserId = _storage.getUserId();
    if (currentUserId == null) throw Exception('Sesión inválida');
    return _adminDao.toggleUserStatus(userId, currentUserId);
  }

  /// Listar todas las promociones.
  Future<List<Promotion>> getPromotions() async {
    return _adminDao.getPromotions();
  }

  /// Crear una promoción.
  Future<Promotion> createPromotion({
    required String title,
    String? description,
    String? code,
    required double discountPercentage,
    required DateTime startDate,
    required DateTime endDate,
    int? eventId,
    String? imagePath,
  }) async {
    return _adminDao.createPromotion(
      title: title,
      description: description,
      code: code,
      discountPercentage: discountPercentage,
      startDate: startDate,
      endDate: endDate,
      eventId: eventId,
      imagePath: imagePath,
    );
  }

  /// Actualizar una promoción.
  Future<Promotion> updatePromotion(
    int id, {
    String? title,
    String? description,
    String? code,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? eventId,
  }) async {
    return _adminDao.updatePromotion(
      id,
      title: title,
      description: description,
      code: code,
      discountPercentage: discountPercentage,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      eventId: eventId,
    );
  }

  /// Eliminar una promoción.
  Future<void> deletePromotion(int id) async {
    await _adminDao.deletePromotion(id);
  }

  /// Validar código promocional.
  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    return _adminDao.validatePromoCode(code);
  }

  /// Obtener reporte por evento.
  Future<Map<String, dynamic>> getEventReport(int eventId) async {
    final data = await _adminDao.getEventReport(eventId);
    final event = data['event'] as Event;
    
    // Convertir tickets a TicketModel
    final List<TicketModel> detailedTickets = [];
    final List<Ticket> rawTickets = data['tickets'] as List<Ticket>;

    final db = _adminDao.attachedDatabase;
    for (final ticket in rawTickets) {
      final type = await (db.select(db.ticketTypes)..where((t) => t.id.equals(ticket.ticketTypeId))).getSingle();
      final user = await (db.select(db.users)..where((u) => u.id.equals(ticket.userId))).getSingle();
      final payment = await (db.select(db.payments)..where((p) => p.ticketId.equals(ticket.id))).getSingleOrNull();

      detailedTickets.add(TicketModel(
        ticket: ticket,
        event: event,
        ticketType: type,
        user: user,
        payment: payment,
      ));
    }

    return {
      'event': event,
      'summary': data['summary'],
      'tickets': detailedTickets,
    };
  }

  /// Obtener reporte general.
  Future<List<Map<String, dynamic>>> getGeneralReport() async {
    return _adminDao.getGeneralReport();
  }
}
