import 'dart:math';

import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

/// Track → bilibili-video matching, ported from the bmsc playlist importer
/// (playlist_search_screen's rankScore + search loop).
///
/// A candidate is scored on: word-level containment of the track/artist in the
/// title (KMP subarray over the tokenized words), duration distance, category
/// (music tnames preferred, non-music ones excluded) and popularity. The
/// top-scoring candidate wins.
class PlaylistMatcher {
  PlaylistMatcher._();

  /// Titles shorter than this shared Chinese run are not considered word
  /// matches — generic two-char strings would match everything.
  static const int _minCommonSubstringLength = 4;

  static final RegExp _wordRegex = RegExp(r'([^a-zA-Z0-9_\u4e00-\u9fa5]+)');
  static final RegExp _htmlRegex = RegExp(r'<[^>]*>|&[^;]+;');

  /// Non-music categories excluded outright (音Mad / 音乐现场 / 翻唱 / 学科普
  /// / 运动综合 in the reference). Search answers carry the category name.
  static const List<String> _excludedTnames = ['音Mad', '音乐现场', '翻唱', '学科科普', '运动综合'];

  /// Music categories the reference boosts (MV / 音乐综合 / 电台).
  static const List<String> _preferredTnames = ['MV', '音乐综合', '电台'];

  static String stripHtml(String text) => text.replaceAll(_htmlRegex, '');

  static List<String> _words(String text) =>
      text.toLowerCase().split(_wordRegex).where((e) => e.isNotEmpty).toList();

  static bool _containsSubarrayKMP(List<String> mainList, List<String> subList) {
    if (subList.isEmpty) return true;
    if (subList.length > mainList.length) return false;

    final lps = _buildLPS(subList);
    int i = 0, j = 0;
    while (i < mainList.length) {
      if (mainList[i] == subList[j]) {
        i++;
        j++;
        if (j == subList.length) {
          return true;
        }
      } else {
        if (j != 0) {
          j = lps[j - 1];
        } else {
          i++;
        }
      }
    }
    return false;
  }

  static List<int> _buildLPS(List<String> pattern) {
    final lps = List<int>.filled(pattern.length, 0);
    int length = 0;
    for (int i = 1; i < pattern.length; i++) {
      while (length > 0 && pattern[i] != pattern[length]) {
        length = lps[length - 1];
      }
      if (pattern[i] == pattern[length]) {
        length++;
      }
      lps[i] = length;
    }
    return lps;
  }

  /// Longest common Chinese substring between the query and the title — the
  /// reference's fallback for titles the tokenizer cannot word-match.
  static bool _hasLongChineseRun(String a, String b) {
    final ca = RegExp(r'[\u4e00-\u9fa5]+').allMatches(a).map((m) => m.group(0)!).join();
    final cb = RegExp(r'[\u4e00-\u9fa5]+').allMatches(b).map((m) => m.group(0)!).join();
    int maxLen = 0;
    final dp = List.generate(ca.length + 1, (_) => List<int>.filled(cb.length + 1, 0));
    for (int i = 1; i <= ca.length; i++) {
      for (int j = 1; j <= cb.length; j++) {
        if (ca[i - 1] == cb[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLen) {
            maxLen = dp[i][j];
            if (maxLen >= _minCommonSubstringLength) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// The best bilibili archive for one imported track triple, or null when
  /// nothing scored.
  static Future<MusicArchive?> match(String track, String artist, int duration) async {
    final matches = await searchMatches(track, artist, duration);
    if (matches.isEmpty) return null;
    return matches.reduce((a, b) => a.$2 > b.$2 ? a : b).$1;
  }

  /// Scored candidates for one track, best first. The pair is (archive, score)
  /// so a caller can show the match quality.
  static Future<List<(MusicArchive, int)>> searchMatches(String track, String artist, int duration) async {
    final searchString = '$track - $artist';
    final results = await BilibiliMusicApi.instance.searchVideos(searchString, pageSize: 20);

    final trackWords = _words(track);
    final artistWords = _words(artist);
    final searchWordsSet = _words(searchString).toSet();

    final scored = <(MusicArchive, int)>[];
    for (final video in results) {
      if (_excludedTnames.contains(video.tname)) continue;

      final durationDiff = (video.duration - duration).abs();
      final title = stripHtml(video.title);
      final titleWords = _words(title);

      double rankScore = 0;
      final hasTrack = _containsSubarrayKMP(titleWords, trackWords);
      final hasArtist = _containsSubarrayKMP(titleWords, artistWords);
      if (hasTrack && hasArtist) {
        rankScore = double.infinity;
      } else if (durationDiff > 20) {
        continue;
      } else if (hasTrack || hasArtist) {
        rankScore = 10;
      } else if (searchWordsSet.intersection(titleWords.toSet()).isNotEmpty) {
        rankScore = 5;
      } else if (_hasLongChineseRun('$track - $artist', title)) {
        rankScore = 0;
      } else {
        continue;
      }

      final priority = _preferredTnames.contains(video.tname) ? 1 : 0;
      final playLog = video.playCount > 0 ? (log(video.playCount) / log(10)) : 0.0;
      final score =
          ((rankScore.isInfinite ? 100000.0 : rankScore) + priority * 1000 - durationDiff + playLog * 5).round();

      scored.add((video, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored;
  }
}
