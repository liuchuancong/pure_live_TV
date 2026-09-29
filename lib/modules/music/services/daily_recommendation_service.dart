import 'dart:convert';
import 'dart:math';

import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/core/utils/hive_pref_util.dart';

/// The brute-force daily recommendation, ported from the bmsc reference:
///
/// - a generation shuffles that folder, takes 30 seeds, and for each seed asks
///   bilibili's related-videos endpoint, keeping the FIRST related video that
///   is in a music category ([_tidWhitelist]), longer than a minute and not in
///   the cross-day recommend history;
/// - the list is cached per day (and per folder — switching folders must
///   regenerate, or yesterday's other folder's picks would linger);
/// - single slots can be re-rolled from a fresh random folder seed.
class DailyRecommendationService {
  DailyRecommendationService._();

  static const String _cacheKey = 'musicDailyRecs';
  static const String _dateKey = 'musicDailyRecsDate';
  static const String _folderIdKey = 'musicDailyRecsFolder';
  static const String _historyKey = 'musicRecommendHistory';
  static const String _defaultFolderKey = 'musicDefaultFavFolder';

  /// reference's tid whitelist [130, 193, 267, 28, 59].
  static const List<int> _tidWhitelist = [130, 193, 267, 28, 59];

  static const int _seedCount = 30;

  /// The pinned default folder, or null before one is chosen (needs login).
  static ({int id, String title})? defaultFolder() {
    final raw = HivePrefUtil.getString(_defaultFolderKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
      if (id <= 0) return null;
      return (id: id, title: json['name']?.toString() ?? '$id');
    } catch (_) {
      return null;
    }
  }

  static Future<void> setDefaultFolder(FavFolder folder) async {
    await HivePrefUtil.setString(
      _defaultFolderKey,
      jsonEncode({'id': folder.id, 'name': folder.title}),
    );
  }

  /// Today's recommendations, generating them from the default folder when the
  /// cache is stale, from another folder, or when [force] re-rolls.
  static Future<List<MusicArchive>?> dailyRecommendations({bool force = false}) async {
    final folder = defaultFolder();
    if (folder == null) return null;

    final lastUpdate = DateTime.tryParse(HivePrefUtil.getString(_dateKey) ?? '');
    final cachedFolderId = HivePrefUtil.getInt(_folderIdKey);
    final folderChanged = cachedFolderId != null && cachedFolderId != folder.id;
    final sameDay = lastUpdate != null &&
        lastUpdate.year == DateTime.now().year &&
        lastUpdate.month == DateTime.now().month &&
        lastUpdate.day == DateTime.now().day;

    if (!force && sameDay && !folderChanged) {
      final cached = _loadCache();
      if (cached != null && cached.isNotEmpty) return cached;
    }

    final recommended = await _generate(folder.id);
    await HivePrefUtil.setString(_dateKey, DateTime.now().toIso8601String());
    await HivePrefUtil.setInt(_folderIdKey, folder.id);
    return recommended;
  }

  /// Re-rolls one slot: a random not-yet-listed folder video seeds a related
  /// search, and the first fresh music pick takes the slot.
  static Future<MusicArchive?> regenerateOne({required List<String> existingBvids}) async {
    final folder = defaultFolder();
    if (folder == null) return null;

    final favVideos = await _folderVideos(folder.id);
    final candidates = favVideos.where((v) => !existingBvids.contains(v.bvid)).toList();
    if (candidates.isEmpty) return null;

    final seed = candidates[Random().nextInt(candidates.length)];
    final history = _loadHistory();
    final fresh = await _pickFromRelated(seed, history);
    return fresh;
  }

  // ----------------------------------------------------------------- engine

  static Future<List<MusicArchive>?> _generate(int folderId) async {
    final favVideos = await _folderVideos(folderId);
    if (favVideos.isEmpty) return null;

    favVideos.shuffle();
    final seeds = favVideos.take(_seedCount).toList();

    final history = _loadHistory();
    final recommended = <MusicArchive>[];
    // One related call per seed, all in flight at once — the reference's
    // Future.wait.
    final related = await Future.wait([
      for (final seed in seeds) _pickFromRelated(seed, history),
    ]);
    for (final pick in related) {
      if (pick != null) {
        recommended.add(pick);
        history.add(pick.bvid);
      }
    }
    await HivePrefUtil.setString(_historyKey, jsonEncode(history.toList()));
    await _saveCache(recommended);
    return recommended;
  }

  /// The first related video of [seed] that is a music category, longer than a
  /// minute and never recommended before; null leaves the slot unchanged.
  static Future<MusicArchive?> _pickFromRelated(MusicArchive seed, Set<String> history) async {
    try {
      final related = await BilibiliMusicApi.instance.getRelatedVideos(aid: seed.aid);
      for (final video in related) {
        if (!_tidWhitelist.contains(video.tid)) continue;
        if (history.contains(video.bvid) || video.duration < 60) continue;
        history.add(video.bvid);
        await HivePrefUtil.setString(_historyKey, jsonEncode(history.toList()));
        return video;
      }
    } catch (_) {
      // One dead seed loses its slot, not the whole list.
    }
    return null;
  }

  static Future<List<MusicArchive>> _folderVideos(int folderId) async {
    final archives = <MusicArchive>[];
    for (var page = 1; page <= 25; page++) {
      final resources = await BilibiliUgcApi.instance.getFavResources(folderId, page: page, pageSize: 20);
      archives.addAll([for (final r in resources) if (!r.invalid) r.toArchive()]);
      if (resources.length < 20) break;
    }
    return archives;
  }

  static Set<String> _loadHistory() {
    try {
      final raw = HivePrefUtil.getString(_historyKey);
      if (raw == null || raw.isEmpty) return {};
      final list = jsonDecode(raw);
      if (list is! List) return {};
      return {for (final v in list) v?.toString() ?? ''}..remove('');
    } catch (_) {
      return {};
    }
  }

  /// Persists the caller's list after a per-slot re-roll, so the day's cache
  /// stays what is on screen.
  static Future<void> saveCache(List<MusicArchive> list) => _saveCache(list);

  // ------------------------------------------------------------------ cache

  static List<MusicArchive>? _loadCache() {
    try {
      final raw = HivePrefUtil.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return [
        for (final entry in list)
          if (entry is Map<String, dynamic>) MusicArchive.fromJson(entry),
      ];
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(List<MusicArchive> list) async {
    await HivePrefUtil.setString(_cacheKey, jsonEncode([for (final a in list) a.toJson()]));
  }
}
