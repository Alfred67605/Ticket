import '../database/app_database.dart';
import '../database/daos/event_dao.dart';
import '../models/event_model.dart';

class EventRepository {
  final EventDao _eventDao;

  EventRepository(this._eventDao);

  Future<List<EventModel>> getEvents({String? category, bool showAll = false}) async {
    final rawEvents = await _eventDao.getEvents(category: category, showAll: showAll);
    final List<EventModel> detailedEvents = [];

    for (final event in rawEvents) {
      final types = await _eventDao.getTicketTypes(event.id);
      final presale = await _eventDao.getActivePresale(event.id);
      final artists = await _eventDao.getEventArtists(event.id);

      detailedEvents.add(EventModel(
        event: event,
        ticketTypes: types,
        presale: presale,
        artists: artists,
      ));
    }
    return detailedEvents;
  }

  Future<EventModel> getEventDetails(int id) async {
    final event = await _eventDao.getEvent(id);
    final types = await _eventDao.getTicketTypes(id);
    final presale = await _eventDao.getActivePresale(id);
    final artists = await _eventDao.getEventArtists(id);

    return EventModel(
      event: event,
      ticketTypes: types,
      presale: presale,
      artists: artists,
    );
  }

  Future<EventModel> createEvent({
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
    final event = await _eventDao.createEvent(
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      capacity: capacity,
      organizer: organizer,
      category: category,
      imagePath: imagePath,
      videoPath: videoPath,
      mediaPreference: mediaPreference,
      ticketTypesList: ticketTypesList,
      presaleStart: presaleStart,
      presaleEnd: presaleEnd,
      presalePrice: presalePrice,
    );

    return getEventDetails(event.id);
  }

  Future<EventModel> updateEvent(
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
    final event = await _eventDao.updateEvent(
      id,
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      organizer: organizer,
      category: category,
      status: status,
      capacity: capacity,
      imagePath: imagePath,
      videoPath: videoPath,
      mediaPreference: mediaPreference,
      ticketTypesList: ticketTypesList,
      presaleStart: presaleStart,
      presaleEnd: presaleEnd,
      presalePrice: presalePrice,
    );

    return getEventDetails(event.id);
  }

  Future<void> deleteEvent(int id) async {
    await _eventDao.deleteEvent(id);
  }
}
