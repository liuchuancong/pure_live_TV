import 'package:pure_live/modules/vod/models/models.dart';

/// Domain interface for the bilibili PGC (anime/movie) endpoints.
abstract class PgcRepository {
  Future<List<PgcItem>> getFeed({required int pgcType, int page, int pageSize});
  Future<List<PgcItem>> getFollowedSeasons({int type, int page, int pageSize});
  Future<PgcSeason> getSeasonDetail({int? seasonId, int? epId});
  Future<void> unfollowSeason({required int seasonId});
  Future<MusicPlayUrls> getPlayUrls({required int epId, required int cid});
}
