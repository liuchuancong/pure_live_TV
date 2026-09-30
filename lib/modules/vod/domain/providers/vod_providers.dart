import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/domain/repositories/music_vod_repository.dart';
import 'package:pure_live/modules/vod/domain/repositories/ugc_repository.dart';
import 'package:pure_live/modules/vod/domain/repositories/pgc_repository.dart';

// Bridges the abstract repository interfaces to the API-backed
// implementations. Manual Providers (no codegen) — swapping any of these for
// a fake in tests is a one-line override.

final Provider<MusicVodRepository> musicRepositoryProvider =
    Provider<MusicVodRepository>((ref) => ApiMusicVodRepository());

final Provider<UgcRepository> ugcRepositoryProvider =
    Provider<UgcRepository>((ref) => ApiUgcRepository());

final Provider<PgcRepository> pgcRepositoryProvider =
    Provider<PgcRepository>((ref) => ApiPgcRepository());

class ApiMusicVodRepository implements MusicVodRepository {
  @override
  @override
  Future<List<MusicArchive>> getMusicRanking() => BilibiliMusicApi.instance.getMusicRanking();
  @override
  Future<List<MusicArchive>> getRegionRanking({required int rid}) => BilibiliMusicApi.instance.getRegionRanking(rid: rid);
  @override
  Future<List<MusicArchive>> getPopularVideos({required int page, int pageSize = 12}) =>
      BilibiliMusicApi.instance.getPopularVideos(page: page, pageSize: pageSize);
  @override
  Future<List<MusicArchive>> getRecommendFeed({required int page, int pageSize = 12}) =>
      BilibiliMusicApi.instance.getRecommendFeed(page: page, pageSize: pageSize);
  @override
  Future<List<MusicArchive>> getRelatedVideos({required int aid, String bvid = ''}) =>
      BilibiliMusicApi.instance.getRelatedVideos(aid: aid, bvid: bvid);
  @override
  Future<List<MusicArchive>> searchVideos(String keyword, {int page = 1, int pageSize = 20}) =>
      BilibiliMusicApi.instance.searchVideos(keyword, page: page, pageSize: pageSize);
  @override
  Future<MusicArchive> getArchiveDetail(String bvid) => BilibiliMusicApi.instance.getArchiveDetail(bvid);
  @override
  Future<MusicPlayUrls> getPlayUrls({required String bvid, required int cid}) =>
      BilibiliMusicApi.instance.getPlayUrls(bvid: bvid, cid: cid);
  @override
  String qualityLabel(int quality) => BilibiliMusicApi.qualityLabel(quality);
}

class ApiUgcRepository implements UgcRepository {
  @override
  Future<UgcMyInfo> getMyInfo() => BilibiliUgcApi.instance.getMyInfo();
  @override
  Future<String> getUserSign(int mid) => BilibiliUgcApi.instance.getUserSign(mid);
  @override
  Future<UserSpaceInfo> getUserSpace(int mid) => BilibiliUgcApi.instance.getUserSpace(mid);
  @override
  Future<List<MusicArchive>> getUserUploads(int mid, {int page = 1, int pageSize = 25, String order = 'pubdate'}) =>
      BilibiliUgcApi.instance.getUserUploads(mid, page: page, pageSize: pageSize, order: order);
  @override
  Future<void> setFollowing(int mid, {required bool follow}) =>
      BilibiliUgcApi.instance.setFollowing(mid, follow: follow);
  @override
  Future<List<({int mid, String name, String face, String sign})>> getFollowings({int page = 1, int pageSize = 25}) =>
      BilibiliUgcApi.instance.getFollowings(page: page, pageSize: pageSize);
  @override
  Future<void> setLike(int aid, {required bool like}) => BilibiliUgcApi.instance.setLike(aid, like: like);
  @override
  Future<bool> hasLiked(int aid) => BilibiliUgcApi.instance.hasLiked(aid);
  @override
  Future<void> addCoin(int aid, {int multiply = 1}) => BilibiliUgcApi.instance.addCoin(aid, multiply: multiply);
  @override
  Future<void> tripleAction(int aid) => BilibiliUgcApi.instance.tripleAction(aid);
  @override
  Future<List<FavFolder>> getMyFavFolders() => BilibiliUgcApi.instance.getMyFavFolders();
  @override
  Future<List<FavFolder>> getCollectedFavFolders({int page = 1, int pageSize = 20}) =>
      BilibiliUgcApi.instance.getCollectedFavFolders(page: page, pageSize: pageSize);
  @override
  Future<List<FavResource>> getFavResources(int mediaId, {int page = 1, int pageSize = 20}) =>
      BilibiliUgcApi.instance.getFavResources(mediaId, page: page, pageSize: pageSize);
  @override
  Future<void> favDeal({required int aid, List<int> addFolderIds = const [], List<int> delFolderIds = const []}) =>
      BilibiliUgcApi.instance.favDeal(aid: aid, addFolderIds: addFolderIds, delFolderIds: delFolderIds);
  @override
  Future<bool> isFavoured(int aid) => BilibiliUgcApi.instance.isFavoured(aid);
  @override
  Future<void> createFavFolder(String title) => BilibiliUgcApi.instance.createFavFolder(title);
  @override
  Future<(List<HistoryItem>, int, int)> getHistory({int max = 0, int viewAt = 0, String business = ''}) =>
      BilibiliUgcApi.instance.getHistory(max: max, viewAt: viewAt, business: business);
  @override
  Future<void> reportHistory({required int aid, required int cid, required int progress, String? bvid}) =>
      BilibiliUgcApi.instance.reportHistory(aid: aid, cid: cid, progress: progress, bvid: bvid);
  @override
  Future<void> deleteHistory({required int aid, required int cid}) =>
      BilibiliUgcApi.instance.deleteHistory(aid: aid, cid: cid);
  @override
  Future<List<ToViewItem>> getToView() => BilibiliUgcApi.instance.getToView();
  @override
  Future<void> addToView(int aid) => BilibiliUgcApi.instance.addToView(aid);
  @override
  Future<void> removeFromView(int aid) => BilibiliUgcApi.instance.removeFromView(aid);
  @override
  Future<(List<DynamicVideo>, String)> getDynamics({String offset = ''}) =>
      BilibiliUgcApi.instance.getDynamics(offset: offset);
  @override
  Future<(List<CommentItem>, String, bool)> getComments(
      {required int oid, int type = 1, required int page, bool hot = true}) =>
      BilibiliUgcApi.instance.getComments(oid: oid, type: type, page: page, hot: hot);
  @override
  Future<List<CommentItem>> getCommentReplies({required int oid, required int rpid, int page = 1}) =>
      BilibiliUgcApi.instance.getCommentReplies(oid: oid, rpid: rpid, page: page);
  @override
  Future<void> likeComment({required int oid, required int rpid, required bool like}) =>
      BilibiliUgcApi.instance.likeComment(oid: oid, rpid: rpid, like: like);
  @override
  Future<List<Hotword>> getHotwords() => BilibiliUgcApi.instance.getHotwords();
  @override
  Future<List<String>> getSuggestions(String term) => BilibiliUgcApi.instance.getSuggestions(term);
  @override
  Future<List<SearchUserItem>> searchUsers(String keyword, {int page = 1}) =>
      BilibiliUgcApi.instance.searchUsers(keyword, page: page);
  @override
  Future<List<SearchLiveItem>> searchLives(String keyword, {int page = 1}) =>
      BilibiliUgcApi.instance.searchLives(keyword, page: page);
  @override
  Future<List<SearchPgcItem>> searchPgc(String keyword, {int page = 1}) =>
      BilibiliUgcApi.instance.searchPgc(keyword, page: page);
  @override
  Future<List<SubtitleTrack>> getSubtitles({required String bvid, required int cid}) =>
      BilibiliUgcApi.instance.getSubtitles(bvid: bvid, cid: cid);
  @override
  Future<List<SubtitleCue>> fetchSubtitleCues(String url) =>
      BilibiliUgcApi.instance.fetchSubtitleCues(url);
  @override
  Future<int> getOnlineCount({required String bvid, required int cid}) =>
      BilibiliUgcApi.instance.getOnlineCount(bvid: bvid, cid: cid);
}

class ApiPgcRepository implements PgcRepository {
  @override
  Future<List<PgcItem>> getFeed({required int pgcType, int page = 1, int pageSize = 20}) =>
      BilibiliPgcApi.instance.getFeed(pgcType: pgcType, page: page, pageSize: pageSize);
  @override
  Future<List<PgcItem>> getFollowedSeasons({int type = 1, int page = 1, int pageSize = 20}) =>
      BilibiliPgcApi.instance.getFollowedSeasons(type: type, page: page, pageSize: pageSize);
  @override
  Future<PgcSeason> getSeasonDetail({int? seasonId, int? epId}) =>
      BilibiliPgcApi.instance.getSeasonDetail(seasonId: seasonId, epId: epId);
  @override
  Future<void> unfollowSeason({required int seasonId}) =>
      BilibiliPgcApi.instance.unfollowSeason(seasonId: seasonId);
  @override
  Future<MusicPlayUrls> getPlayUrls({required int epId, required int cid}) =>
      BilibiliPgcApi.instance.getPlayUrls(epId: epId, cid: cid);
}
