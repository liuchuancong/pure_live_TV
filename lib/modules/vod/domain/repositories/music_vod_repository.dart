import 'package:pure_live/modules/vod/models/models.dart';

/// Domain interface for the bilibili music/VOD endpoints.
///
/// `modules/music` and `modules/video` depend on this abstraction, never on
/// [BilibiliMusicApi] directly — the API implementation is injectable via
/// [musicRepositoryProvider], so controllers can be tested with a fake.
abstract class MusicVodRepository {
  Future<List<MusicArchive>> getMusicRanking();
  Future<List<MusicArchive>> getRegionRanking({required int rid});
  Future<List<MusicArchive>> getPopularVideos({required int page, int pageSize});
  Future<List<MusicArchive>> getRecommendFeed({required int page, int pageSize});
  Future<List<MusicArchive>> getRelatedVideos({required int aid, String bvid});
  Future<List<MusicArchive>> searchVideos(String keyword, {int page, int pageSize});
  Future<MusicArchive> getArchiveDetail(String bvid);
  Future<MusicPlayUrls> getPlayUrls({required String bvid, required int cid});
  String qualityLabel(int quality);
}
