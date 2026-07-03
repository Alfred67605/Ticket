import 'package:drift/drift.dart';

/// Tabla de roles (Admin, Cliente).
class Roles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
}

/// Tabla de usuarios.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 255)();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get roleId => integer().withDefault(const Constant(2)).references(Roles, #id)();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de eventos.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(max: 255)();
  TextColumn get description => text()();
  TextColumn get location => text()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get image => text().nullable()();
  TextColumn get video => text().nullable()();
  TextColumn get mediaPreference => text().withDefault(const Constant('both'))();
  TextColumn get organizer => text().withDefault(const Constant('Gobernación de Potosí'))();
  TextColumn get organizerLogo => text().nullable()();
  TextColumn get bannerImage => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get capacity => integer()();
  IntColumn get ticketsAvailable => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de tipos de ticket.
class TicketTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  TextColumn get name => text().withLength(max: 100)();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de preventas.
class Presales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  IntColumn get ticketTypeId => integer().nullable().references(TicketTypes, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get presalePrice => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de promociones.
class Promotions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().nullable().references(Events, #id)();
  TextColumn get title => text().withLength(max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get code => text().nullable()();
  RealColumn get discountPercentage => real()();
  TextColumn get image => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de tickets.
class Tickets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get eventId => integer().references(Events, #id)();
  IntColumn get ticketTypeId => integer().references(TicketTypes, #id)();
  TextColumn get ticketCode => text()();
  TextColumn get qrToken => text().unique()();
  TextColumn get status => text().withDefault(const Constant('paid'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de pagos (de Anny).
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId => integer().references(Tickets, #id)();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('qr'))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla de artistas.
class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 255)();
  TextColumn get genre => text().nullable()();
  TextColumn get image => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla pivote evento-artista.
class EventArtists extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventId => integer().references(Events, #id)();
  IntColumn get artistId => integer().references(Artists, #id)();
}

/// Tabla de asistencias.
class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ticketId => integer().references(Tickets, #id)();
  DateTimeColumn get checkinTime => dateTime()();
  IntColumn get validatedBy => integer().references(Users, #id)();
}
