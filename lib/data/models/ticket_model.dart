import '../database/app_database.dart';

/// Modelo de ticket completo que asocia la información de compra,
/// el evento, el tipo de boleto y el pago relacionado.
class TicketModel {
  final Ticket ticket;
  final Event event;
  final TicketType ticketType;
  final Payment? payment;
  final User? user; // Opcional, para el scanner y reportes del admin

  TicketModel({
    required this.ticket,
    required this.event,
    required this.ticketType,
    this.payment,
    this.user,
  });

  int get id => ticket.id;
  String get ticketCode => ticket.ticketCode;
  String get qrToken => ticket.qrToken;
  String get status => ticket.status;
  DateTime get createdAt => ticket.createdAt;
}
