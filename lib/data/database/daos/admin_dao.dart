import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'admin_dao.g.dart';

/// DAO de administración — reemplaza AdminController.php de Laravel.
@DriftAccessor(tables: [Events, Tickets, TicketTypes, Users, Roles, Promotions, Payments, Attendances])
class AdminDao extends DatabaseAccessor<AppDatabase> with _$AdminDaoMixin {
  AdminDao(super.db);

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  /// Estadísticas del dashboard.
  Future<Map<String, dynamic>> getDashboard() async {
    final totalTicketsPaid = await (select(tickets)
      ..where((t) => t.status.equals('paid')))
        .get();
    final totalTicketsUsed = await (select(tickets)
      ..where((t) => t.status.equals('used')))
        .get();
    final totalEventsActive = await (select(events)
      ..where((e) => e.status.equals('active')))
        .get();
    final totalUsersClient = await (select(users)
      ..where((u) => u.roleId.equals(2)))
        .get();

    // Ingresos totales
    final allPayments = await (select(payments)
      ..where((p) => p.status.equals('completed')))
        .get();
    final totalRevenue = allPayments.fold<double>(0, (sum, p) => sum + p.amount);

    // Eventos recientes (últimos 5)
    final recentEvents = await (select(events)
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
      ..limit(5))
        .get();

    // Ventas por día (últimos 7 días)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentTickets = await (select(tickets)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(sevenDaysAgo)))
        .get();

    final salesByDay = <String, int>{};
    for (final t in recentTickets) {
      final dateKey = '${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}';
      salesByDay[dateKey] = (salesByDay[dateKey] ?? 0) + 1;
    }

    return {
      'total_tickets': totalTicketsPaid.length,
      'used_tickets': totalTicketsUsed.length,
      'total_events': totalEventsActive.length,
      'total_users': totalUsersClient.length,
      'total_revenue': totalRevenue,
      'recent_events': recentEvents,
      'sales_by_day': salesByDay,
    };
  }

  // ─── GESTIÓN DE USUARIOS ──────────────────────────────────────────────────

  /// Listar todos los usuarios.
  Future<List<User>> getUsers() async {
    return (select(users)
      ..orderBy([(u) => OrderingTerm.desc(u.createdAt)]))
        .get();
  }

  /// Toggle estado del usuario (activar/desactivar).
  Future<User> toggleUserStatus(int userId, int currentUserId) async {
    if (userId == currentUserId) {
      throw Exception('No puedes desactivar tu propia cuenta');
    }
    final user = await (select(users)..where((u) => u.id.equals(userId))).getSingle();
    final newStatus = user.status == 'active' ? 'inactive' : 'active';

    await (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(status: Value(newStatus), updatedAt: Value(DateTime.now())),
    );

    return (select(users)..where((u) => u.id.equals(userId))).getSingle();
  }

  // ─── PROMOCIONES ──────────────────────────────────────────────────────────

  /// Listar promociones.
  Future<List<Promotion>> getPromotions() async {
    return (select(promotions)
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Crear promoción.
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
    final id = await into(promotions).insert(PromotionsCompanion.insert(
      title: title,
      description: Value(description),
      code: Value(code?.toUpperCase()),
      discountPercentage: discountPercentage,
      startDate: startDate,
      endDate: endDate,
      eventId: Value(eventId),
      image: Value(imagePath),
      isActive: const Value(true),
    ));
    return (select(promotions)..where((p) => p.id.equals(id))).getSingle();
  }

  /// Actualizar promoción.
  Future<Promotion> updatePromotion(int id, {
    String? title,
    String? description,
    String? code,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? eventId,
  }) async {
    await (update(promotions)..where((p) => p.id.equals(id))).write(PromotionsCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      code: code != null ? Value(code.toUpperCase()) : const Value.absent(),
      discountPercentage: discountPercentage != null ? Value(discountPercentage) : const Value.absent(),
      startDate: startDate != null ? Value(startDate) : const Value.absent(),
      endDate: endDate != null ? Value(endDate) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      eventId: eventId != null ? Value(eventId) : const Value.absent(),
    ));
    return (select(promotions)..where((p) => p.id.equals(id))).getSingle();
  }

  /// Eliminar promoción.
  Future<void> deletePromotion(int id) async {
    await (delete(promotions)..where((p) => p.id.equals(id))).go();
  }

  /// Validar código promocional (público).
  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    final now = DateTime.now();
    final promo = await (select(promotions)
      ..where((p) =>
        p.code.equals(code.toUpperCase()) &
        p.isActive.equals(true) &
        p.startDate.isSmallerOrEqualValue(now) &
        p.endDate.isBiggerOrEqualValue(now)))
        .getSingleOrNull();

    if (promo == null) {
      return {'valid': false, 'message': 'Código inválido o expirado'};
    }

    return {
      'valid': true,
      'discount_percentage': promo.discountPercentage,
      'title': promo.title,
      'message': '¡Descuento del ${promo.discountPercentage}% aplicado!',
    };
  }

  // ─── REPORTES ─────────────────────────────────────────────────────────────

  /// Reporte por evento.
  Future<Map<String, dynamic>> getEventReport(int eventId) async {
    final event = await (select(events)..where((e) => e.id.equals(eventId))).getSingle();
    final eventTickets = await (select(tickets)
      ..where((t) => t.eventId.equals(eventId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    // Obtener precios de cada ticket
    double totalRevenue = 0;
    for (final t in eventTickets) {
      if (t.status == 'paid' || t.status == 'used') {
        final type = await (select(ticketTypes)..where((tt) => tt.id.equals(t.ticketTypeId))).getSingleOrNull();
        totalRevenue += type?.price ?? 0;
      }
    }

    return {
      'event': event,
      'summary': {
        'total_sold': eventTickets.where((t) => t.status == 'paid' || t.status == 'used').length,
        'total_used': eventTickets.where((t) => t.status == 'used').length,
        'total_pending': eventTickets.where((t) => t.status == 'pending').length,
        'total_revenue': totalRevenue,
      },
      'tickets': eventTickets,
    };
  }

  /// Reporte general.
  Future<List<Map<String, dynamic>>> getGeneralReport() async {
    final allEvents = await (select(events)
      ..orderBy([(e) => OrderingTerm.desc(e.eventDate)]))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final event in allEvents) {
      final eventTickets = await (select(tickets)
        ..where((t) => t.eventId.equals(event.id)))
          .get();

      double revenue = 0;
      for (final t in eventTickets) {
        if (t.status == 'paid' || t.status == 'used') {
          final type = await (select(ticketTypes)..where((tt) => tt.id.equals(t.ticketTypeId))).getSingleOrNull();
          revenue += type?.price ?? 0;
        }
      }

      result.add({
        'event': event,
        'tickets_sold': eventTickets.where((t) => t.status == 'paid' || t.status == 'used').length,
        'tickets_used': eventTickets.where((t) => t.status == 'used').length,
        'revenue': revenue,
      });
    }
    return result;
  }

  /// Contar tickets vendidos para un evento.
  Future<int> getTicketsSoldForEvent(int eventId) async {
    final tix = await (select(tickets)
      ..where((t) => t.eventId.equals(eventId) & 
        (t.status.equals('paid') | t.status.equals('used'))))
        .get();
    return tix.length;
  }
}
