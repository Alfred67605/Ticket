import '../database/app_database.dart';

/// Modelo de evento completo para la capa de presentación.
/// Combina la información de la tabla Events, sus TicketTypes, Presales y Artists.
class EventModel {
  final Event event;
  final List<TicketType> ticketTypes;
  final Presale? presale;
  final List<Artist> artists;

  EventModel({
    required this.event,
    required this.ticketTypes,
    this.presale,
    required this.artists,
  });

  int get id => event.id;
  String get title => event.title;
  String get description => event.description;
  String get location => event.location;
  DateTime get eventDate => event.eventDate;
  String? get image => event.image;
  String? get video => event.video;
  String get mediaPreference => event.mediaPreference;
  String get organizer => event.organizer;
  String? get organizerLogo => event.organizerLogo;
  String get category => event.category;
  String get status => event.status;
  int get capacity => event.capacity;
  int get ticketsAvailable => event.ticketsAvailable;

  bool get isPresale {
    if (presale == null || !presale!.isActive) return false;
    final now = DateTime.now();
    return presale!.startDate.isBefore(now) && presale!.endDate.isAfter(now);
  }

  /// Retorna el precio correspondiente para un tipo de ticket considerando preventa.
  double getPriceForType(TicketType type) {
    if (presale != null && presale!.isActive) {
      final now = DateTime.now();
      if (presale!.startDate.isBefore(now) && presale!.endDate.isAfter(now)) {
        if (presale!.ticketTypeId == null || presale!.ticketTypeId == type.id) {
          return presale!.presalePrice;
        }
      }
    }
    return type.price;
  }
}
