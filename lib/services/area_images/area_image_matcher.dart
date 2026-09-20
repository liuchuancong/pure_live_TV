import 'dart:convert';

import 'package:pure_live/shared/models/live_area/live_area.dart';
import 'package:pure_live/shared/models/live_category/live_category.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/platforms/sites.dart';

/// Fills missing category artwork by borrowing it from other platforms.
///
/// Douyin's category API returns no images; when its category name matches a
/// category on a platform that does have artwork (bilibili / douyu / huya),
/// that picture is shown on the douyin card. Matches persist in Hive so the
/// grid looks stable, and a picture that later fails to load is reported
/// broken ([reportBroken]) which drops every match pointing at it — the next
/// category refresh re-matches, possibly from another platform.
class AreaImageMatcher {
  AreaImageMatcher._();

  static final AreaImageMatcher instance = AreaImageMatcher._();

  /// Platforms whose category lists are scraped for source artwork, in order.
  static const List<String> _sourcePlatforms = <String>['bilibili', 'douyu', 'huya'];

  static const String _hiveKey = 'area_pic_matches_v2';

  /// `'<platform>|<areaId>' → image url`, persisted in Hive.
  Map<String, String> _matches = <String, String>{};
  bool _matchesLoaded = false;

  /// Normalized category name → every distinct artwork found for it, built
  /// once per session. A name often exists on several source platforms (or at
  /// two levels), and those pictures differ; keeping the list lets each area
  /// take a different one instead of every card showing the same image.
  Map<String, List<String>>? _sourceIndex;

  Map<String, String> _loadMatches() {
    if (_matchesLoaded) return _matches;
    final String? raw = HivePrefUtil.getString(_hiveKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _matches = (jsonDecode(raw) as Map).cast<String, String>();
      } catch (_) {
        _matches = <String, String>{};
      }
    }
    _matchesLoaded = true;
    return _matches;
  }

  void _saveMatches() {
    try {
      HivePrefUtil.setString(_hiveKey, jsonEncode(_matches));
    } catch (_) {
      // Persistence is an optimisation; matching still works this session.
    }
  }

  /// Category names compared loosely: case, spaces and separators ignored, and
  /// as a fallback a containment check (`英雄联盟手游` matches `英雄联盟：手游`).
  static String normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[\s·・_\-—‐:：,，。.（）()【】\[\]]+'), '');

  Future<Map<String, List<String>>> _sources() async {
    final Map<String, List<String>>? cached = _sourceIndex;
    if (cached != null) return cached;

    final Map<String, List<String>> index = <String, List<String>>{};
    void offer(String name, String pic) {
      final String normalized = normalize(name);
      if (normalized.isEmpty) return;
      final List<String> pics = index.putIfAbsent(normalized, () => <String>[]);
      if (!pics.contains(pic)) pics.add(pic);
    }

    for (final String platformId in _sourcePlatforms) {
      try {
        final List<LiveCategory> categories = await Sites.of(platformId).liveSite.getCategores(1, 1000);
        for (final LiveCategory category in categories) {
          for (final area in category.children) {
            if (area.areaPic.isNotEmpty) offer(area.areaName, area.areaPic);
          }
        }
      } catch (_) {
        // A source platform failing to load just leaves fewer matches.
      }
    }
    _sourceIndex = index;
    return index;
  }

  /// Candidates for a name: the exact list first, then loose containment
  /// matches (at least two chars, so single-glyph broad names do not swallow
  /// everything). The caller picks the first candidate not already used.
  List<String> _candidates(Map<String, List<String>> index, String name) {
    final String key = normalize(name);
    if (key.isEmpty) return const <String>[];
    final List<String>? exact = index[key];
    if (exact != null) return exact;
    final List<String> loose = <String>[];
    for (final entry in index.entries) {
      if (entry.key.length < 2) continue;
      if (entry.key.contains(key) || key.contains(entry.key)) loose.addAll(entry.value);
    }
    return loose;
  }

  /// Returns [categories] with empty `areaPic`s filled from a match (Hive
  /// first, live sources otherwise). Areas that have their own artwork, and
  /// names nothing matches, pass through untouched.
  ///
  /// One picture is used at most once per call: several areas loosely matching
  /// the same source do not all render the identical card. Persisted matches
  /// keep their picture across refreshes (they claimed it first); new areas
  /// take the first candidate no sibling uses, and a name with nothing unique
  /// left simply shows the placeholder icon.
  Future<List<LiveCategory>> fill(String platform, List<LiveCategory> categories) async {
    final Map<String, String> matches = _loadMatches();
    final Map<String, List<String>> index = await _sources();
    var changed = false;

    final Set<String> used = <String>{};
    // Settle persisted claims first, so long-since-assigned pictures keep them
    // before fresh areas pick from what is left.
    final Map<String, String> claimed = <String, String>{
      for (final LiveCategory category in categories)
        for (final area in category.children)
          if (area.areaPic.isEmpty) '$platform|${area.areaId}': matches['$platform|${area.areaId}'] ?? '',
    }..removeWhere((_, value) => value.isEmpty);
    used.addAll(claimed.values);

    List<LiveArea> fillChildren(List<LiveArea> children) {
      final List<LiveArea> result = <LiveArea>[];
      for (final area in children) {
        if (area.areaPic.isNotEmpty) {
          result.add(area);
          continue;
        }

        final String key = '$platform|${area.areaId}';
        String? pic = claimed[key];
        if (pic == null) {
          for (final candidate in [
            ..._candidates(index, area.areaName),
            ..._candidates(index, area.typeName),
          ]) {
            if (used.add(candidate)) {
              pic = candidate;
              matches[key] = candidate;
              changed = true;
              break;
            }
          }
        }
        result.add(pic == null ? area : area.copyWith(areaPic: pic));
      }
      return result;
    }

    final List<LiveCategory> filled = categories
        .map((category) => category.copyWith(children: fillChildren(category.children)))
        .toList();

    if (changed) _saveMatches();
    return filled;
  }

  /// Drops every persisted match that points at [url], so the next refresh
  /// re-matches (a dead or expired picture gets replaced, not reshown).
  void reportBroken(String url) {
    final Map<String, String> matches = _loadMatches();
    final int before = matches.length;
    matches.removeWhere((_, value) => value == url);
    // Also stop offering it from the in-memory source index this session.
    _sourceIndex?.updateAll((_, pics) => pics.where((pic) => pic != url).toList());
    _sourceIndex?.removeWhere((_, pics) => pics.isEmpty);
    if (matches.length != before) _saveMatches();
  }
}
