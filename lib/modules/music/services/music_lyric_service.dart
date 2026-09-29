import 'package:hive_ce/hive.dart';
import 'package:pure_live/modules/vod/api/bilibili_lyric_api.dart';
import 'package:pure_live/modules/music/api/third_party_lyric_api.dart';
import 'package:pure_live/core/utils/string_similarity.dart';

/// One selectable lyric for a track: where it came from and whose song it says
/// it is. The picker dialog lists these; the one the viewer picks becomes the
/// track's default.
class MusicLyricCandidate {
  const MusicLyricCandidate({required this.source, required this.title, required this.lyric, this.artist = ''});

  /// Short source label shown as the row's badge.
  final String source;

  /// The song name the candidate claims to be.
  final String title;
  final String artist;
  final String lyric;

  bool sameLyric(MusicLyricCandidate other) => lyric.trim() == other.lyric.trim();
}

/// Lyrics for music mode, ported from the bilibilimusic reference project's
/// chain plus the netease fallback this app already had:
///
/// 1. bilibili BGM (official music library): [BilibiliLyricApi]'s
///    `bgm_info.music_id` → BGM detail lyric — the source the reference app
///    prefers, because it is the uploader's own BGM metadata;
/// 2. third-party LRC APIs ([ThirdPartyLyricApi], the reference's
///    `lyricApiList`);
/// 3. netease search + lyric ([ThirdPartyLyricApi], this app's original
///    fallback).
///
/// The endpoints live in the media/api layer; this service owns the policy
/// around them: caching, the title cleaning, and the verification that drops
/// a candidate whose own metadata names another song.
///
/// **Every candidate is checked against the track before its lyric is used.** The
/// APIs answer with their best fuzzy guess, and a compilation's part name
/// a wrong lyric is worse than none, so an unmatched candidate is dropped and the
///
/// All results are cached per title for the session — misses too, so a
/// lyric-less track does not refetch every open.
class MusicLyricService {
  MusicLyricService._();

  static final MusicLyricService instance = MusicLyricService._();

  final Map<String, String?> _cache = {};

  static const String _cacheBox = 'musicLyricCacheV1';
  static const String _manualBox = 'musicLyricManualV1';

  /// The lyric the viewer picked by hand, or null. Highest priority: a manual
  /// choice outranks every automatic source, for this track and every future
  /// session.
  String? manualLyric(String title) {
    final query = cleanTitle(title);
    if (query.isEmpty) return null;
    return _readBox(_manualBox, query);
  }

  /// Remembers [lyric] as the viewer's choice for [title].
  void saveManualLyric(String title, String lyric) {
    final query = cleanTitle(title);
    if (query.isEmpty) return;
    _writeBox(_manualBox, query, lyric);
    _cache[title] = lyric;
  }

  /// Drops the viewer's manual choice for [title] — the automatic chain
  /// answers again on the next load.
  void clearManualLyric(String title) {
    final query = cleanTitle(title);
    if (query.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_manualBox)) Hive.openBox<String>(_manualBox);
      Hive.box<String>(_manualBox).delete(query);
    } catch (_) {}
    _cache.remove(title);
  }

  /// Reads one of the persistent lyric boxes. Hive is opened lazily: the music
  /// page may be the first thing that touches them.
  static String? _readBox(String name, String key) {
    try {
      if (!Hive.isBoxOpen(name)) Hive.openBox<String>(name);
      return Hive.box<String>(name).get(key);
    } catch (_) {
      return null;
    }
  }

  static void _writeBox(String name, String key, String value) {
    try {
      if (!Hive.isBoxOpen(name)) Hive.openBox<String>(name);
      Hive.box<String>(name).put(key, value);
    } catch (_) {}
  }

  /// LRC text for the track. [title] is the part name; [hint] joins the query
  /// when the bare title is too generic; [aid]/[bvid]/[cid] enable the bilibili
  /// BGM chain when available.
  Future<String?> fetchLyric(
    String title, {
    String hint = '',
    int aid = 0,
    String bvid = '',
    int cid = 0,
  }) async {
    final key = title;
    if (_cache.containsKey(key)) return _cache[key];

    // and every source below would otherwise search for that literal string.
    final query = cleanTitle(title);
    if (query.isEmpty) {
      _cache[key] = null;
      return null;
    }

    // A hand-picked lyric outranks the chain, across sessions.
    final manual = manualLyric(title);
    if (manual != null) {
      _cache[key] = manual;
      return manual;
    }

    // What an earlier session already fetched: no network on a replay.
    final stored = _readBox(_cacheBox, query);
    if (stored != null) {
      _cache[key] = stored;
      return stored;
    }

    String? lyric;
    try {
      lyric = await _fetchBgmLyric(query, aid: aid, bvid: bvid, cid: cid);
    } catch (_) {}
    lyric ??= await _fetchLrcApiLyric(query, hint);
    lyric ??= await _fetchNeteaseLyric(query, hint);
    _cache[key] = lyric;
    // Misses persist too: a lyric-less track must not refetch on every open.
    if (lyric != null) _writeBox(_cacheBox, query, lyric);
    return lyric;
  }

  /// Every candidate the chain can name for the track, for the picker dialog.
  ///
  /// Unlike [fetchLyric] this does not stop at the first hit: the netease search
  /// list and the LRC-endpoint candidate lists are walked, each entry's lyric is
  /// fetched (network, capped), and duplicates of an already-collected body are
  /// dropped. The manual choice, when there is one, leads the list so the
  /// current default stays visible and re-pickable.
  Future<List<MusicLyricCandidate>> fetchLyricCandidates(
    String title, {
    String hint = '',
    int aid = 0,
    String bvid = '',
    int cid = 0,
    int perSourceLimit = 6,
  }) async {
    final query = cleanTitle(title);
    if (query.isEmpty) return const [];

    final candidates = <MusicLyricCandidate>[];
    void add(String source, String songTitle, String artist, String? lyric) {
      final text = _normalize(lyric ?? '');
      if (text == null) return;
      final candidate = MusicLyricCandidate(source: source, title: songTitle, artist: artist, lyric: text);
      if (candidates.any((existing) => candidate.sameLyric(existing))) return;
      candidates.add(candidate);
    }

    final manual = manualLyric(title);
    if (manual != null) {
      candidates.add(MusicLyricCandidate(source: 'manual', title: query, lyric: manual));
    }

    try {
      final bgm = await _fetchBgmLyric(query, aid: aid, bvid: bvid, cid: cid);
      if (bgm != null) add('B站BGM', query, '', bgm);
    } catch (_) {}

    // The LRC endpoints: lrc.cx answers one plain-text body, rangotec a JSON
    // list whose entries name their own song — the picker can show what it
    // actually found.
    final cx = await ThirdPartyLyricApi.instance.fetchLrcCx(title: query, artist: hint);
    if (cx != null) {
      final single = verified(query, _normalize(cx));
      if (single != null) add('LRC', query, '', single);
    }
    for (final entry in await ThirdPartyLyricApi.instance.fetchRangotec(title: query, artist: hint, limit: perSourceLimit)) {
      add('LRC', entry.title.isEmpty ? query : entry.title, entry.artist, entry.lrc);
    }

    // The netease search list, lyric fetched per hit up to the cap.
    final songs = await _searchSongs(query, hint, limit: perSourceLimit);
    for (final song in songs) {
      final lyric = await ThirdPartyLyricApi.instance.fetchNeteaseLyric(song.id);
      add('网易云', song.name, song.artist, lyric);
    }

    return candidates;
  }

  /// The bilibili BGM chain: the archive's own background-music metadata.
  ///
  /// Checked like the others — a compilation's BGM is whatever the uploader laid
  /// under the video, not the track that plays, so a BGM whose own title
  /// disagrees with the part is not this part's lyric.
  Future<String?> _fetchBgmLyric(
    String query, {
    required int aid,
    required String bvid,
    required int cid,
  }) async {
    final info = await BilibiliLyricApi.instance.fetchBgmInfo(aid: aid, bvid: bvid, cid: cid);
    if (info == null) return null;
    if (info.title.isNotEmpty && !plausible(query, info.title)) return null;
    final lyric = await BilibiliLyricApi.instance.fetchBgmLyric(musicId: info.musicId);
    return verified(query, _normalize(lyric ?? ''));
  }

  /// The third-party LRC list: first endpoint that answers with something that
  /// looks like timed lyrics for *this* track wins.
  Future<String?> _fetchLrcApiLyric(String query, String hint) async {
    final cx = await ThirdPartyLyricApi.instance.fetchLrcCx(title: query, artist: hint);
    if (cx != null) {
      final lyric = verified(query, _normalize(cx));
      if (lyric != null) return lyric;
    }
    for (final entry in await ThirdPartyLyricApi.instance.fetchRangotec(title: query, artist: hint)) {
      if (entry.title.isNotEmpty && !plausible(query, entry.title)) continue;
      final lyric = verified(query, _normalize(entry.lrc));
      if (lyric != null) return lyric;
    }
    return null;
  }

  /// The netease chain this app shipped first.
  Future<String?> _fetchNeteaseLyric(String query, String hint) async {
    final hits = await _searchSongs(query, hint, limit: 1);
    if (hits.isEmpty) return null;
    final lyric = await ThirdPartyLyricApi.instance.fetchNeteaseLyric(hits.first.id);
    return verified(query, _normalize(lyric ?? ''));
  }

  /// The search hits whose name actually is the track, best first.
  ///
  Future<List<({String id, String name, String artist})>> _searchSongs(
    String query,
    String hint, {
    int limit = 6,
  }) async {
    final hits = <({String id, String name, String artist})>[];
    final seen = <String>{};
    for (final text in [query, if (hint.isNotEmpty && hint != query) '$query $hint']) {
      final songs = await ThirdPartyLyricApi.instance.searchNeteaseSongs(text: text);
      for (final song in songs) {
        if (!plausible(query, song.name)) continue;
        if (!seen.add(song.id)) continue;
        hits.add(song);
        if (hits.length >= limit) return hits;
      }
      if (hits.isNotEmpty) break;
    }
    return hits;
  }

  /// Drops an LRC whose own `[ti:]` tag names another song.
  ///
  /// These files carry the title they were made for; when that title does not
  /// line up with the track, the file belongs to something else. Files without
  /// the tag cannot be checked and stay.
  static String? verified(String query, String? lyric) {
    if (lyric == null) return null;
    final tag = _tagValue(lyric, 'ti');
    if (tag == null) return lyric;
    return plausible(query, tag) ? lyric : null;
  }

  static String? _tagValue(String lrc, String name) {
    final match = RegExp('\\[$name:([^\\]]*)\\]', caseSensitive: false).firstMatch(lrc);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Whether [candidate] plausibly names the same song as [query].
  ///
  static bool plausible(String query, String candidate) {
    final a = _fold(query);
    final b = _fold(candidate);
    if (a.isEmpty || b.isEmpty) return true;
    if (a == b || a.startsWith(b) || b.startsWith(a)) return true;
    return compareTwoStrings(a, b) >= 0.7;
  }

  static String _fold(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  /// Accepts only text with timed lines, and normalizes the timestamp shapes
  /// the reference project converts (`[mm:ss,mmm]`, `[hh:mm:ss.mmm]`) into the
  /// `[mm:ss.xx]` flutter_lyric parses.
  String? _normalize(String raw) {
    if (raw.trim().isEmpty || !raw.contains('[00:')) return null;
    var text = raw.replaceAll('\r\n', '\n');
    text = text.replaceAllMapped(RegExp(r'\[(\d{1,2}):(\d{1,2})[,:.](\d{1,3})\]'), (m) {
      final mm = m.group(1)!.padLeft(2, '0');
      final ss = m.group(2)!.padLeft(2, '0');
      var frac = m.group(3)!;
      // 1-3 digit fraction → centiseconds.
      final fracMs = int.tryParse(frac.padRight(3, '0').substring(0, 3)) ?? 0;
      final cs = (fracMs / 10).round().clamp(0, 99).toString().padLeft(2, '0');
      return '[$mm:$ss.$cs]';
    });
    return text.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]')) ? text : null;
  }

  /// The track name inside a part's title.
  ///
  /// finds nothing, and the fuzzy APIs answer with a wrong song.
  static String cleanTitle(String title) {
    var text = title.trim();
    // decoration is gone.
    text = text.replaceAll(RegExp(r'【[^】]*】|\([^)]*\)|\[[^\]]*\]'), ' ').trim();
    // and leave the classifier behind.
    text = text.replaceFirst(RegExp(r'^第\s*[0-9一二三四五六七八九十]{1,3}\s*[首曲集部]?\s*'), '');
    text = text.replaceFirst(RegExp(r'^p\s*\d{1,3}\s*[\.、\-—_:：]?\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^(?:\d{1,3}\s*[\.、\-—_:：]\s*|0\d{1,2}\s+)'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? title.trim() : text;
  }
}
