# -*- coding: utf-8 -*-
"""Generates the domain repository interfaces + providers + the API-backed
implementation for the VOD module."""
import io
import os

BASE = 'lib/modules/vod/domain/'

# ---------------------------------------------------------------------------
# The abstract interface: one class per API surface, methods mirroring the
# static entry points callers actually use.
# ---------------------------------------------------------------------------

MUSIC_REPO = '''
/// Domain interface for the bilibili music/VOD endpoints.
///
/// `modules/music` and `modules/video` depend on this abstraction, never on
/// [BilibiliMusicApi] directly — the API implementation is injectable via
/// [musicRepositoryProvider], so controllers can be tested with a fake.
abstract class MusicVodRepository {
  List<MusicArchive> getMusicRanking();
  List<MusicArchive> getRegionRanking({required int rid});
  Future<List<MusicArchive>> getPopularVideos({required int page, int pageSize});
  Future<List<MusicArchive>> getRecommendFeed({required int page, int pageSize});
  Future<List<MusicArchive>> getRelatedVideos({required int aid, String bvid});
  Future<List<MusicArchive>> searchVideos(String keyword, {int page, int pageSize});
  Future<MusicArchive> getArchiveDetail(String bvid);
  Future<MusicPlayUrls> getPlayUrls({required String bvid, required int cid});
  String qualityLabel(int quality);
}
'''

UGC_REPO = '''
/// Domain interface for the bilibili account/UGC endpoints (fav folders,
/// history, watch later, comments, interactions, user space, search extras).
abstract class UgcRepository {
  Future<UgcMyInfo> getMyInfo();
  Future<String> getUserSign(int mid);
  Future<UserSpaceInfo> getUserSpace(int mid);
  Future<List<MusicArchive>> getUserUploads(int mid, {int page, int pageSize, String order});
  Future<void> setFollowing(int mid, {required bool follow});
  Future<List<({int mid, String name, String face, String sign})>> getFollowings({int page, int pageSize});
  Future<void> setLike(int aid, {required bool like});
  Future<bool> hasLiked(int aid);
  Future<void> addCoin(int aid, {int multiply});
  Future<void> tripleAction(int aid);
  Future<List<FavFolder>> getMyFavFolders();
  Future<List<FavFolder>> getCollectedFavFolders({int page, int pageSize});
  Future<List<FavResource>> getFavResources(int mediaId, {int page, int pageSize});
  Future<void> favDeal({required int aid, List<int> addFolderIds, List<int> delFolderIds});
  Future<bool> isFavoured(int aid);
  Future<void> createFavFolder(String title);
  Future<(List<HistoryItem>, int, int)> getHistory({int max, int viewAt, String business});
  Future<void> reportHistory({required int aid, required int cid, required int progress, String? bvid});
  Future<void> deleteHistory({required int aid, required int cid});
  Future<List<ToViewItem>> getToView();
  Future<void> addToView(int aid);
  Future<void> removeFromView(int aid);
  Future<(List<DynamicVideo>, String)> getDynamics({String offset});
  Future<(List<CommentItem>, String, bool)> getComments({required int oid, int type, required int page, bool hot});
  Future<List<CommentItem>> getCommentReplies({required int oid, required int rpid, int page});
  Future<void> likeComment({required int oid, required int rpid, required bool like});
  Future<List<Hotword>> getHotwords();
  Future<List<String>> getSuggestions(String term);
  Future<List<SearchUserItem>> searchUsers(String keyword, {int page});
  Future<List<SearchLiveItem>> searchLives(String keyword, {int page});
  Future<List<SearchPgcItem>> searchPgc(String keyword, {int page});
  Future<List<SubtitleTrack>> getSubtitles({required String bvid, required int cid});
  Future<List<SubtitleCue>> fetchSubtitleCues(String url);
  Future<int> getOnlineCount({required String bvid, required int cid});
}
'''

PGC_REPO = '''
/// Domain interface for the bilibili PGC (anime/movie) endpoints.
abstract class PgcRepository {
  Future<List<PgcItem>> getFeed({required int pgcType, int page, int pageSize});
  Future<List<PgcItem>> getFollowedSeasons({int type, int page, int pageSize});
  Future<PgcSeason> getSeasonDetail({int? seasonId, int? epId});
  Future<void> unfollowSeason({required int seasonId});
  Future<MusicPlayUrls> getPlayUrls({required int epId, required int cid});
}
'''

# ---------------------------------------------------------------------------
# The API-backed implementation: thin delegation to the existing static
# singletons. One file, one class per interface.
# ---------------------------------------------------------------------------

IMPL_MUSIC = '''
@Riverpod(keepAlive: true)
MusicVodRepository musicRepository(MusicRepositoryRef ref) => ApiMusicVodRepository();
'''

IMPL_UGC = '''
@Riverpod(keepAlive: true)
UgcRepository ugcRepository(UgcRepositoryRef ref) => ApiUgcRepository();
'''

IMPL_PGC = '''
@Riverpod(keepAlive: true)
PgcRepository pgcRepository(PgcRepositoryRef ref) => ApiPgcRepository();
'''

IMPL_CLASS = '''
/// The API-backed implementation: thin delegation to the existing static
/// singletons, so no call site changes behaviour.
class ApiMusicVodRepository implements MusicVodRepository {
  @override
  List<MusicArchive> getMusicRanking() => BilibiliMusicApi.instance.getMusicRanking();
  @override
  List<MusicArchive> getRegionRanking({required int rid}) => BilibiliMusicApi.instance.getRegionRanking(rid: rid);
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
'''

# ---------------------------------------------------------------------------
# Write the files.
# ---------------------------------------------------------------------------

os.makedirs(BASE + 'repositories', exist_ok=True)

io.open(BASE + 'repositories/music_vod_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';\n"
    "import 'package:pure_live/modules/vod/models/models.dart';\n"
    "\n" + MUSIC_REPO)

io.open(BASE + 'repositories/ugc_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';\n"
    "import 'package:pure_live/modules/vod/models/models.dart';\n"
    "\n" + UGC_REPO)

io.open(BASE + 'repositories/pgc_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';\n"
    "import 'package:pure_live/modules/vod/models/models.dart';\n"
    "\n" + PGC_REPO)

# Providers file: bridges the abstract interfaces to the API implementations.
providers = ("import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
             "import 'package:riverpod_annotation/riverpod_annotation.dart';\n"
             "import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';\n"
             "import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';\n"
             "import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';\n"
             "import 'package:pure_live/modules/vod/domain/repositories/music_vod_repository.dart';\n"
             "import 'package:pure_live/modules/vod/domain/repositories/ugc_repository.dart';\n"
             "import 'package:pure_live/modules/vod/domain/repositories/pgc_repository.dart';\n"
             "\npart 'providers.g.dart';\n"
             + IMPL_MUSIC + IMPL_UGC + IMPL_PGC + IMPL_CLASS)

os.makedirs(BASE + 'domain/providers', exist_ok=True)
os.makedirs(BASE + 'repositories', exist_ok=True)
io.open(BASE + 'repositories/music_vod_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/models/models.dart';\n" + MUSIC_REPO)
io.open(BASE + 'repositories/ugc_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/models/models.dart';\n" + UGC_REPO)
io.open(BASE + 'repositories/pgc_repository.dart', 'w', encoding='utf-8').write(
    "import 'package:pure_live/modules/vod/models/models.dart';\n" + PGC_REPO)
io.open(BASE + 'domain/providers/vod_providers.dart', 'w', encoding='utf-8').write(providers)

print('domain layer written')
