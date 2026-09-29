import 'package:drift/drift.dart';

/// Drift table definitions for clubTivi local database.

/// IPTV service providers (M3U or Xtream Codes).
class Providers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'm3u', 'xtream'
  TextColumn get url => text().nullable()(); // M3U URL or Xtream base URL
  TextColumn get username => text().nullable()(); // Xtream
  TextColumn get password => text().nullable()(); // Xtream
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastRefresh => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isAutoUpdate => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Channels from all providers.
class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get providerId => text().references(Providers, #id)();
  TextColumn get name => text()();
  TextColumn get tvgId => text().nullable()();
  TextColumn get tvgName => text().nullable()();
  TextColumn get tvgLogo => text().nullable()();
  TextColumn get groupTitle => text().nullable()();
  IntColumn get channelNumber => integer().nullable()();
  TextColumn get streamUrl => text()();
  TextColumn get streamType => text().withDefault(const Constant('live'))();
  TextColumn get catchupMode => text().nullable()();
  TextColumn get catchupSource => text().nullable()();
  RealColumn get catchupDays => real().nullable()();
  RealColumn get catchupCorrectionHours => real().nullable()();
  TextColumn get httpHeadersJson => text().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isAutoUpdate => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

/// User-defined channel groups.
class ChannelGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Named favorite lists (e.g., "Sports", "News", "Kids").
class FavoriteLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('star'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Join table: channels in a favorite list.
class FavoriteListChannels extends Table {
  TextColumn get listId => text().references(FavoriteLists, #id)();
  TextColumn get channelId => text().references(Channels, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {listId, channelId};
}

/// User-defined failover groups — manually curated sets of interchangeable channels.
class FailoverGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Channels belonging to a failover group, ordered by priority.
class FailoverGroupChannels extends Table {
  IntColumn get groupId => integer().references(FailoverGroups, #id)();
  TextColumn get channelId => text().references(Channels, #id)();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId, channelId};
}
