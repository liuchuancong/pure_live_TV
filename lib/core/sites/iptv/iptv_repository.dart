import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/db_service/db_controller.dart';
import 'package:pure_live/core/sites/iptv/models/channel.dart' as models;
import 'package:pure_live/core/sites/iptv/local/database.dart' as database;

class IptvRepository {
  final Ref ref;
  IptvRepository(this.ref);

  Future<List<models.Channel>> getChannels(String providerId) async {
    try {
      final db = ref.read(dbServiceProvider).db;
      final List<database.Channel> dbChannels = await db.getChannelsForProvider(providerId);

      return dbChannels
          .map(
            (e) => models.Channel(
              id: e.id,
              providerId: e.providerId,
              name: e.name,
              streamUrl: e.streamUrl,
              groupTitle: e.groupTitle,
              tvgId: e.tvgId,
              tvgName: e.tvgName,
              tvgLogo: e.tvgLogo,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final iptvRepositoryProvider = Provider<IptvRepository>((ref) {
  return IptvRepository(ref);
});
