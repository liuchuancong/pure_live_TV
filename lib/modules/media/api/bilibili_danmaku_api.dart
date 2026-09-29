import 'dart:convert' show utf8;

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:pure_live/modules/media/api/bilibili_api_client.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// Every danmaku endpoint the VOD player needs, in one place: the segmented
/// protobuf reads (one small request per ~6 minutes of video), the one-shot
/// XML fallback for parts the segment view API says nothing about, and the
/// send endpoint. Parsing lives here too — the widget only walks the
/// timeline.
class BilibiliDanmakuApi {
  BilibiliDanmakuApi._();

  static final BilibiliDanmakuApi instance = BilibiliDanmakuApi._();

  final BilibiliApiClient _client = BilibiliApiClient.instance;

  /// The number of danmaku segments for the part. `x/v2/dm/web/view` answers
  /// as protobuf (DmWebViewReply, non-WBI — newBV reads it the same way) whose
  /// field 4 carries the repeated dm_seg config; the first entry's field 2 is
  /// the segment total. Zero when the answer carries nothing — the caller
  /// falls back to the one-shot XML.
  Future<int> getDanmakuSegmentCount({required int aid, required int cid}) async {
    try {
      final response = await HttpClient.instance.dio.get<List<int>>(
        'https://api.bilibili.com/x/v2/dm/web/view',
        options: Options(responseType: ResponseType.bytes, headers: await _client.headers()),
        queryParameters: {'type': '1', 'oid': '$cid', 'pid': '$aid'},
      );
      return _pbSegmentTotal(response.data ?? const <int>[]);
    } catch (_) {
      return 0;
    }
  }

  /// One danmaku segment (`x/v2/dm/web/seg.so`) as protobuf. The response
  /// is a `DmSegMobileReply` whose repeated element (field 1) carries, per
  /// danmaku: progress (field 2, varint, milliseconds), mode (field 3,
  /// varint) and content (field 7, string) — the only fields this app uses.
  Future<List<({double time, String text})>> getDanmakuSegment({
    required int aid,
    required int cid,
    required int segment,
  }) async {
    // `/x/v2/dm/wbi/web/seg.so` — the WBI-signed web endpoint newBV uses
    // (`segment_index`, 1-based). The unsigned `dm/web/seg.so` answers an
    // empty reply to plain clients, which read as "no danmaku in this
    // segment".
    final base = 'https://api.bilibili.com/x/v2/dm/wbi/web/seg.so';
    final signed = await _client.wbiSign('$base?type=1&oid=$cid&pid=$aid&segment_index=$segment');
    final response = await HttpClient.instance.dio.get<List<int>>(
      base,
      options: Options(responseType: ResponseType.bytes, headers: await _client.headers()),
      queryParameters: signed,
    );
    return parseDanmakuSegment(response.data ?? const <int>[]);
  }

  /// The one-shot full XML (`x/v1/dm/list.so`) parsed to a sorted timeline —
  /// the fallback when [getDanmakuSegmentCount] answers zero. Throws on HTTP
  /// failure; the caller treats "no danmaku" as silent degradation.
  Future<List<({double time, String text})>> getDanmakuXml({required int cid}) async {
    final xml = await HttpClient.instance.getText(
      'https://api.bilibili.com/x/v1/dm/list.so?oid=$cid',
      header: await _client.headers(),
    );
    return parseDanmakuXml(xml);
  }

  /// Posts one danmaku comment to the archive's current part
  /// (`x/v2/dm/send`), the web shape with the csrf token.
  Future<void> sendDanmaku({required int aid, required int cid, required String message, String? bvid}) async {
    await _client.postForm('https://api.bilibili.com/x/v2/dm/send', {
      'aid': '$aid',
      'cid': '$cid',
      'bvid': bvid ?? '',
      'message': message,
      'mode': '1',
      'fontsize': '25',
      'color': '16777215',
      'pool': '0',
      'plat': '1',
      'progress': '0',
      'rnd': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    });
  }

  // ------------------------------------------------------------------- XML

  static final RegExp _line = RegExp(r'<d p="([^"]+)"[^>]*>([^<]+)</d>');
  static final RegExp _htmlTag = RegExp(r'<[^>]+>');
  static const Map<String, String> _entities = {
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&amp;': '&',
  };

  /// The `<d p="...">` rows of [xml], sorted by time; scroll modes only
  /// (mode <= 3), the same filter the live player applies.
  static List<({double time, String text})> parseDanmakuXml(String xml) {
    final parsed = <({double time, String text})>[];
    for (final match in _line.allMatches(xml)) {
      final fields = match.group(1)?.split(',') ?? const [];
      final time = double.tryParse(fields.elementAtOrNull(0) ?? '') ?? -1;
      final mode = int.tryParse(fields.elementAtOrNull(1) ?? '') ?? 1;
      if (time < 0 || mode > 3) continue;
      final text = _unescape(match.group(2) ?? '').trim();
      if (text.isEmpty) continue;
      parsed.add((time: time, text: text));
    }
    parsed.sort((a, b) => a.time.compareTo(b.time));
    return parsed;
  }

  static String _unescape(String raw) {
    var text = raw;
    for (final entry in _entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(_htmlTag, '');
  }

  // -------------------------------------------------------------- protobuf

  /// Reads one protobuf varint; returns (value, nextOffset).
  static (int, int) _pbVarint(List<int> source, int offset) {
    var value = 0;
    var shift = 0;
    var cursor = offset;
    while (cursor < source.length) {
      final b = source[cursor++];
      value |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) return (value, cursor);
      shift += 7;
    }
    throw const FormatException('truncated varint');
  }

  static int _pbSkip(List<int> source, int offset, int wire) {
    switch (wire) {
      case 0:
        return _pbVarint(source, offset).$2;
      case 1:
        return offset + 8;
      case 2:
        final (length, after) = _pbVarint(source, offset);
        return after + length;
      case 5:
        return offset + 4;
      default:
        throw const FormatException('unsupported wire type');
    }
  }

  /// Total segments from the first `dm_seg` config (DmWebViewReply field 4 →
  /// DmSegConfig field 2), or 0 when absent.
  static int _pbSegmentTotal(List<int> bytes) {
    try {
      var at = 0;
      while (at < bytes.length) {
        final (key, keyNext) = _pbVarint(bytes, at);
        final field = key >> 3;
        final wire = key & 7;
        if (field != 4 || wire != 2) {
          at = _pbSkip(bytes, keyNext, wire);
          continue;
        }
        final (configLength, configStart) = _pbVarint(bytes, keyNext);
        final config = bytes.sublist(configStart, configStart + configLength);

        var inner = 0;
        while (inner < config.length) {
          final (innerKey, innerNext) = _pbVarint(config, inner);
          if ((innerKey >> 3) == 2 && (innerKey & 7) == 0) {
            final (total, _) = _pbVarint(config, innerNext);
            return total;
          }
          inner = _pbSkip(config, innerNext, innerKey & 7);
        }
        return 0;
      }
    } on FormatException {
      // Fall through: malformed protobuf reads as "no segments".
    }
    return 0;
  }

  /// Minimal protobuf walk for [getDanmakuSegment] — no generated bindings;
  /// the three fields above are all the player needs. Anything malformed
  /// yields what was parsed so far; the overlay then shows fewer danmaku.
  static List<({double time, String text})> parseDanmakuSegment(List<int> bytes) {
    final out = <({double time, String text})>[];
    var at = 0;

    /// Reads one varint, returns (value, nextOffset).
    (int, int) varint(List<int> source, int offset) {
      var value = 0;
      var shift = 0;
      var cursor = offset;
      while (cursor < source.length) {
        final b = source[cursor++];
        value |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) return (value, cursor);
        shift += 7;
      }
      throw const FormatException('truncated varint');
    }

    int skip(int offset, int wire) {
      switch (wire) {
        case 0:
          return varint(bytes, offset).$2;
        case 1:
          return offset + 8;
        case 2:
          final (length, after) = varint(bytes, offset);
          return after + length;
        case 5:
          return offset + 4;
        default:
          throw const FormatException('unsupported wire type');
      }
    }

    try {
      while (at < bytes.length) {
        final (key, keyNext) = varint(bytes, at);
        final field = key >> 3;
        final wire = key & 7;
        if (field != 1 || wire != 2) {
          at = skip(keyNext, wire);
          continue;
        }
        final (elemLength, elemStart) = varint(bytes, keyNext);
        final elem = bytes.sublist(elemStart, elemStart + elemLength);
        at = elemStart + elemLength;

        var progressMs = 0;
        var mode = 1;
        var text = '';
        var inner = 0;
        while (inner < elem.length) {
          final (innerKey, innerNext) = varint(elem, inner);
          final innerField = innerKey >> 3;
          final innerWire = innerKey & 7;
          switch ((innerField, innerWire)) {
            case (2, 0):
              final (value, valueNext) = varint(elem, innerNext);
              progressMs = value;
              inner = valueNext;
            case (3, 0):
              final (modeValue, modeNext) = varint(elem, innerNext);
              mode = modeValue;
              inner = modeNext;
            case (7, 2):
              final (length, textStart) = varint(elem, innerNext);
              text = utf8.decode(elem.sublist(textStart, textStart + length), allowMalformed: true);
              inner = textStart + length;
            default:
              final (_, after) = varint(elem, inner); inner = after;
          }
        }
        if (text.isNotEmpty && mode <= 3) {
          out.add((time: progressMs / 1000.0, text: text));
        }
      }
    } on FormatException {
      return out;
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
