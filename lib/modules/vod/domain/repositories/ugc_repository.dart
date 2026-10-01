import 'package:pure_live/modules/vod/models/models.dart';

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
  Future<List<String>> getArchiveTags(String bvid);
  Future<List<({int id, String title, bool contained})>> getFavFoldersForVideo(int aid);
  Future<bool> isFollowing(int mid);
}
