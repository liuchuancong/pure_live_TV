import 'dart:convert';

import 'openrec_api.dart';

class OpenrecHlsQuality {
  OpenrecHlsQuality({
    required this.id,
    required this.label,
    required this.family,
    required this.rank,
    required Iterable<String> urls,
  }) : urls = List.unmodifiable(urls);
  final String id;
  final String label;
  final String family;
  final int rank;
  final List<String> urls;
}

List<OpenrecHlsQuality> parseOpenrecHls(String text, OpenrecMedia source) {
  final master = Uri.parse(OpenrecApi.mediaUrl(source.url));
  if (!{'hls', 'low-latency-hls', 'public-hls'}.contains(source.id) ||
      text.length > OpenrecApi.responseLimit ||
      utf8.encode(text).length > OpenrecApi.responseLimit ||
      text.trimLeft().split('\n').first.trim() != '#EXTM3U') {
    throw const OpenrecException(OpenrecFailure.schema);
  }
  final groups = <String, ({String label, int rank, Set<String> urls})>{};
  Map<String, String>? pending;
  var externalRendition = false;
  var mediaSegment = false;
  var expectingSegment = false;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line == '#EXT-X-ENDLIST' || line == '#EXT-X-PLAYLIST-TYPE:VOD') {
      throw const OpenrecException(OpenrecFailure.mediaUnavailable);
    }
    if (line.startsWith('#EXT-X-KEY:') || line.startsWith('#EXT-X-SESSION-KEY:')) {
      final attrs = _attributes(line.substring(line.indexOf(':') + 1));
      if (attrs['METHOD'] != 'NONE') throw const OpenrecException(OpenrecFailure.restricted);
    }
    if (line.startsWith('#EXT-X-MEDIA:')) {
      final attrs = _attributes(line.substring(13));
      if (attrs['URI'] != null) {
        OpenrecApi.mediaUrl(master.resolve(attrs['URI']!).toString());
        externalRendition = true;
      }
    }
    if (line.startsWith('#EXTINF:')) {
      if (pending != null || groups.isNotEmpty || expectingSegment) throw const OpenrecException(OpenrecFailure.schema);
      final seconds = double.tryParse(line.substring(8).split(',').first);
      if (seconds == null || !seconds.isFinite || seconds <= 0) throw const OpenrecException(OpenrecFailure.schema);
      expectingSegment = true;
    }
    if (line.startsWith('#EXT-X-STREAM-INF:')) {
      if (pending != null || mediaSegment || expectingSegment) throw const OpenrecException(OpenrecFailure.schema);
      pending = _attributes(line.substring(18));
      continue;
    }
    if (line.isEmpty || line.startsWith('#')) continue;
    if (pending == null) {
      if (!expectingSegment) throw const OpenrecException(OpenrecFailure.schema);
      final segment = master.resolve(line);
      // Validate the authority using a playlist path without changing any URL
      // passed to the player; a media playlist keeps its original master URL.
      OpenrecApi.mediaUrl(segment.replace(path: '/validation.m3u8').toString());
      expectingSegment = false;
      mediaSegment = true;
      continue;
    }
    final attrs = pending;
    pending = null;
    final resolved = master.resolve(line);
    final url = line.startsWith('https://') ? line : resolved.toString();
    OpenrecApi.mediaUrl(url);
    final rate = int.tryParse(attrs['BANDWIDTH'] ?? '');
    final size = attrs['RESOLUTION'] ?? '';
    final match = RegExp(r'^([1-9][0-9]{0,4})x([1-9][0-9]{0,4})$').firstMatch(size);
    final fps = double.tryParse(attrs['FRAME-RATE'] ?? '0');
    if (rate == null ||
        rate <= 0 ||
        (size.isNotEmpty && match == null) ||
        fps == null ||
        !fps.isFinite ||
        fps < 0 ||
        fps > 1000) {
      throw const OpenrecException(OpenrecFailure.schema);
    }
    // Signed URL, CDN and changing bandwidth do not identify a known rendition.
    final id = jsonEncode([
      source.id,
      size,
      fps,
      attrs['CODECS'],
      attrs['VIDEO'],
      attrs['AUDIO'],
      if (match == null) rate,
    ]);
    final label = match == null
        ? 'HLS ${(rate / 1000000).toStringAsFixed(1)} Mbps'
        : '${match[2]}p${fps > 0 ? ' ${fps == fps.roundToDouble() ? fps.toInt() : fps}fps' : ''}';
    final previous = groups[id];
    groups[id] = (
      label: label,
      rank: rate > (previous?.rank ?? 0) ? rate : previous!.rank,
      urls: {...?previous?.urls, url},
    );
    if (groups.length > 1000) throw const OpenrecException(OpenrecFailure.schema);
  }
  if (pending != null || expectingSegment || (groups.isEmpty && !mediaSegment)) {
    throw const OpenrecException(OpenrecFailure.schema);
  }
  // Selecting a naked video child could drop separately declared audio/video.
  if (externalRendition || groups.isEmpty) {
    return [
      OpenrecHlsQuality(id: '${source.id}:auto', label: 'HLS Auto', family: source.id, rank: 0, urls: [source.url]),
    ];
  }
  return List.unmodifiable(
    groups.entries.map(
      (e) =>
          OpenrecHlsQuality(id: e.key, label: e.value.label, family: source.id, rank: e.value.rank, urls: e.value.urls),
    ),
  );
}

Map<String, String> _attributes(String text) {
  final result = <String, String>{};
  var offset = 0;
  final pattern = RegExp(r'([A-Z0-9-]+)=("[^"]*"|[^,\s]+)(?:,|$)');
  while (offset < text.length) {
    final match = pattern.matchAsPrefix(text, offset);
    if (match == null || result.containsKey(match[1])) throw const OpenrecException(OpenrecFailure.schema);
    final value = match[2]!;
    result[match[1]!] = value.startsWith('"') ? value.substring(1, value.length - 1) : value;
    offset = match.end;
  }
  return result;
}
