import 'dart:io';

import 'tables.dart';

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:pure_live/app/bootstrap/app_path_manager.dart';

part 'database.g.dart';

const _uuid = Uuid();

@DriftDatabase(
  tables: [
    Providers,
    Channels,
    ChannelGroups,
    FavoriteLists,
    FavoriteListChannels,
    FailoverGroups,
    FailoverGroupChannels,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) => transaction(() async {
      if (from > to) {
        throw StateError('Database downgrade from $from to $to is not supported');
      }
      if (from < 2) {
        await m.createTable(favoriteLists);
        await m.createTable(favoriteListChannels);
      }
      if (from < 5) {
        await m.createTable(failoverGroups);
        await m.createTable(failoverGroupChannels);
      }
      if (from < 6) {
        await m.addColumn(providers, providers.isAutoUpdate);
      }
      if (from < 8) {
        final channelColumns = (await customSelect(
          'PRAGMA table_info(channels)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!channelColumns.contains(channels.catchupMode.$name)) await m.addColumn(channels, channels.catchupMode);
        if (!channelColumns.contains(channels.catchupSource.$name)) await m.addColumn(channels, channels.catchupSource);
        if (!channelColumns.contains(channels.catchupDays.$name)) await m.addColumn(channels, channels.catchupDays);
        if (!channelColumns.contains(channels.catchupCorrectionHours.$name)) {
          await m.addColumn(channels, channels.catchupCorrectionHours);
        }
      }
      if (from < 9) {
        final channelColumns = (await customSelect(
          'PRAGMA table_info(channels)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!channelColumns.contains(channels.httpHeadersJson.$name)) {
          await m.addColumn(channels, channels.httpHeadersJson);
        }
      }
      if (from < 10) {
        // The EPG feature is gone: drop the tables it owned, along with the reminder and
        // scheduled-recording tables that only existed to point at its programmes, so an
        // upgraded install does not keep the listings forever.
        for (final table in const <String>[
          'epg_programmes',
          'epg_mappings',
          'epg_channels',
          'epg_sources',
          'epg_reminders',
          'scheduled_recordings',
        ]) {
          await customStatement('DROP TABLE IF EXISTS $table');
        }
      }
      // Commit the version with the data, before Drift repeats its version write.
      // Otherwise an interrupted open could replay conversion of orphaned IDs.
      await customStatement('PRAGMA user_version = $to');
    }),
  );

  // --- Provider queries ---

  Future<List<Provider>> getAllProviders() => select(providers).get();

  Future<Provider?> getProviderById(String id) {
    return (select(providers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Channel>> searchChannelsByName(String keyword) {
    return (select(channels)
          ..where((t) => t.name.like('%$keyword%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> upsertProvider(ProvidersCompanion entry) => into(providers).insertOnConflictUpdate(entry);

  Future<void> deleteProvider(String id) => (delete(providers)..where((t) => t.id.equals(id))).go();

  /// Deletes a provider with everything that belongs to its channels.
  ///
  /// The whole delete is one transaction: removing the channel rows first without
  /// their favourite/failover references would strand rows pointing at channels that
  /// no longer exist, and a later failure would keep them for good.
  Future<void> deleteProviderAndChannels(String providerId) => deleteProviderCascading(providerId);

  // --- Channel queries ---
  Future<List<Channel>> getChannelsForProvider(String providerId) =>
      (select(channels)..where((t) => t.providerId.equals(providerId))).get();

  Future<List<Channel>> getChannelsByIds(Set<String> ids) => (select(channels)..where((t) => t.id.isIn(ids))).get();
  Future<Channel?> getChannelById(String id) async {
    return (select(channels)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get distinct group names per provider without loading channel objects.
  Future<Map<String, List<String>>> getProviderGroups() async {
    final rows = await customSelect(
      'SELECT DISTINCT provider_id, group_title FROM channels '
      'WHERE group_title IS NOT NULL AND group_title != \'\' '
      'ORDER BY provider_id, group_title',
    ).get();
    final result = <String, List<String>>{};
    for (final row in rows) {
      final pid = row.read<String>('provider_id');
      final g = row.read<String>('group_title');
      (result[pid] ??= []).add(g);
    }
    return result;
  }

  /// Get channels for a specific provider and group.
  Future<List<Channel>> getChannelsForProviderGroup(String providerId, String groupTitle) =>
      (select(channels)..where((t) => t.providerId.equals(providerId) & t.groupTitle.equals(groupTitle))).get();

  Future<List<Channel>> getFavoriteChannels() => (select(channels)..where((t) => t.favorite.equals(true))).get();

  /// Loads every visible channel once, ordered by provider and playlist order.
  ///
  /// Category screens group the result in memory instead of issuing one query
  /// per provider, which matters when many providers are installed.
  Future<List<Channel>> getAllVisibleChannels() => (select(channels)
        ..where((t) => t.hidden.equals(false))
        ..orderBy([
          (t) => OrderingTerm(expression: t.providerId),
          (t) => OrderingTerm(expression: t.sortOrder),
        ]))
      .get();

  Future<void> upsertChannels(List<ChannelsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(channels, entries);
    });
  }

  Future<void> updateChannelLogo(String channelId, String logoUrl) =>
      (update(channels)..where((t) => t.id.equals(channelId))).write(ChannelsCompanion(tvgLogo: Value(logoUrl)));

  /// Batch-update logos for multiple channels in a single transaction.
  Future<void> updateChannelLogos(Map<String, String> idToLogoUrl) async {
    await batch((b) {
      for (final entry in idToLogoUrl.entries) {
        b.update(channels, ChannelsCompanion(tvgLogo: Value(entry.value)), where: (t) => t.id.equals(entry.key));
      }
    });
  }

  Future<void> renameChannel(String channelId, String providerId, String newName) =>
      (update(channels)..where((t) => t.id.equals(channelId))).write(ChannelsCompanion(name: Value(newName)));

  Future<void> toggleFavorite(String channelId) async {
    final channel = await (select(channels)..where((t) => t.id.equals(channelId))).getSingle();
    await (update(
      channels,
    )..where((t) => t.id.equals(channelId))).write(ChannelsCompanion(favorite: Value(!channel.favorite)));
  }

  // --- EPG queries removed with the feature ---

  Future<List<Provider>> getNetworkProviders() {
    return (select(providers)..where((t) => t.url.like('http%') | t.url.like('https%'))).get();
  }

  Future<void> deleteProviderCascading(String providerId) async {
    await transaction(() async {
      // Favourites and failover rows reference channel rows, never the provider row,
      // so they must be collected before the channels disappear.
      final channelIds = (await (select(channels)
                ..where((t) => t.providerId.equals(providerId)))
              .get())
          .map((channel) => channel.id)
          .toList(growable: false);
      if (channelIds.isNotEmpty) {
        await (delete(favoriteListChannels)..where((t) => t.channelId.isIn(channelIds))).go();
        await (delete(failoverGroupChannels)..where((t) => t.channelId.isIn(channelIds))).go();
      }
      await (delete(channels)..where((t) => t.providerId.equals(providerId))).go();
      await (delete(providers)..where((t) => t.id.equals(providerId))).go();
    });
  }

  Future<void> updateProviderUpdateStatus(String providerId, bool status) async {
    await (update(
      providers,
    )..where((t) => t.id.equals(providerId))).write(ProvidersCompanion(isAutoUpdate: Value(status)));
  }

  // Precise lookup: only sources that are both overdue and have auto-update
  // switched on (isAutoUpdate == true) are returned.

  Future<List<Provider>> getExpiredNetworkProviders(Duration checkInterval) {
    final threshold = DateTime.now().subtract(checkInterval);
    return (select(providers)..where(
          (t) => t.url.like('http%') & t.lastRefresh.isSmallerThan(Variable(threshold)) & t.isAutoUpdate.equals(true),
        ))
        .get();
  }

  Future<List<Channel>> getAllChannels() => select(channels).get();

  // --- Favorite List queries ---

  Future<List<FavoriteList>> getAllFavoriteLists() =>
      (select(favoriteLists)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<List<Channel>> getChannelsInList(String listId) async {
    final query =
        select(channels).join([innerJoin(favoriteListChannels, favoriteListChannels.channelId.equalsExp(channels.id))])
          ..where(favoriteListChannels.listId.equals(listId))
          ..orderBy([OrderingTerm.asc(favoriteListChannels.sortOrder)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(channels)).toList();
  }

  Future<void> addChannelToList(String listId, String channelId) =>
      into(favoriteListChannels)
          .insertOnConflictUpdate(FavoriteListChannelsCompanion.insert(listId: listId, channelId: channelId));

  Future<void> removeChannelFromList(String listId, String channelId) =>
      (delete(favoriteListChannels)..where((t) => t.listId.equals(listId) & t.channelId.equals(channelId))).go();

  Future<FavoriteList> createFavoriteList(String name) async {
    final id = _uuid.v4();
    final count = await (select(favoriteLists)..limit(1000)).get();
    final entry = FavoriteListsCompanion.insert(id: id, name: name, sortOrder: Value(count.length));
    await into(favoriteLists).insert(entry);
    return (select(favoriteLists)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> renameFavoriteList(String id, String name) =>
      (update(favoriteLists)..where((t) => t.id.equals(id))).write(FavoriteListsCompanion(name: Value(name)));

  Future<void> deleteFavoriteList(String id) async {
    await (delete(favoriteListChannels)..where((t) => t.listId.equals(id))).go();
    await (delete(favoriteLists)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> isChannelInList(String listId, String channelId) async {
    final row = await (select(
      favoriteListChannels,
    )..where((t) => t.listId.equals(listId) & t.channelId.equals(channelId))).getSingleOrNull();
    return row != null;
  }

  Future<List<FavoriteList>> getListsForChannel(String channelId) async {
    final query = select(favoriteLists).join([
      innerJoin(favoriteListChannels, favoriteListChannels.listId.equalsExp(favoriteLists.id)),
    ])..where(favoriteListChannels.channelId.equals(channelId));
    final rows = await query.get();
    return rows.map((row) => row.readTable(favoriteLists)).toList();
  }

  /// Get all channel IDs that belong to any favorite list.
  Future<Set<String>> getAllFavoritedChannelIds() async {
    final rows = await select(favoriteListChannels).get();
    return rows.map((r) => r.channelId).toSet();
  }

  // --- Failover Group queries ---

  Future<List<FailoverGroup>> getAllFailoverGroups() =>
      (select(failoverGroups)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<FailoverGroup> createFailoverGroup(String name) async {
    final id = await into(failoverGroups).insert(FailoverGroupsCompanion.insert(name: name));
    return (select(failoverGroups)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> addChannelsToFailoverGroup(int groupId, List<String> channelIds) async {
    await batch((b) {
      for (var i = 0; i < channelIds.length; i++) {
        b.insert(
          failoverGroupChannels,
          FailoverGroupChannelsCompanion.insert(groupId: groupId, channelId: channelIds[i], priority: Value(i)),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<FailoverGroupChannel>> getFailoverGroupMembers(int groupId) =>
      (select(failoverGroupChannels)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();

  /// Get all failover group memberships keyed by channel ID for fast lookup.
  Future<Map<String, List<FailoverGroupMembership>>> getFailoverGroupIndex() async {
    final groups = await getAllFailoverGroups();
    final members = await select(failoverGroupChannels).get();
    final groupMap = {for (final g in groups) g.id: g};
    final index = <String, List<FailoverGroupMembership>>{};
    for (final m in members) {
      final group = groupMap[m.groupId];
      if (group == null) continue;
      index.putIfAbsent(m.channelId, () => []).add(FailoverGroupMembership(group: group, priority: m.priority));
    }
    return index;
  }

  Future<void> deleteFailoverGroup(int groupId) async {
    await (delete(failoverGroupChannels)..where((t) => t.groupId.equals(groupId))).go();
    await (delete(failoverGroups)..where((t) => t.id.equals(groupId))).go();
  }

  Future<void> renameFailoverGroup(int groupId, String name) =>
      (update(failoverGroups)..where((t) => t.id.equals(groupId))).write(FailoverGroupsCompanion(name: Value(name)));

  Future<void> removeChannelFromFailoverGroup(int groupId, String channelId) =>
      (delete(failoverGroupChannels)..where((t) => t.groupId.equals(groupId) & t.channelId.equals(channelId))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await AppPathManager().getDir(AppPathManager.dirIptvCache);
    final tableName = AppPathManager.iptvTable;
    final file = File(p.join(dir.path, tableName, '$tableName.db'));
    await file.parent.create(recursive: true);

    if (!await file.exists()) {
      final oldDir = await AppPathManager().getDir(AppPathManager.dirIptvCache);
      final oldFile = File(p.join(oldDir.path, tableName, '$tableName.db'));
      if (await oldFile.exists()) {
        await oldFile.copy(file.path);
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}

/// Lightweight struct for failover group membership lookups.
class FailoverGroupMembership {
  final FailoverGroup group;
  final int priority;
  const FailoverGroupMembership({required this.group, required this.priority});
}
