import 'dart:convert';

enum ZhanqiLayoutFailure { schema, identity }

class ZhanqiLayoutException implements Exception {
  const ZhanqiLayoutException(this.kind);
  final ZhanqiLayoutFailure kind;
  @override
  String toString() => 'Zhanqi player layout ${kind.name}';
}

/// One enabled matrix cell, before guest signing and CDN routing. The quality
/// label is not a measured resolution; a cell is not proof of available media.
class ZhanqiPlayerCell {
  const ZhanqiPlayerCell({
    required this.lineIndex,
    required this.qualityIndex,
    required this.cdnKey,
    required this.suffix,
  });
  final int lineIndex;
  final int qualityIndex;
  final int cdnKey;
  final String suffix;
}

/// Public v3 player configuration. Preserve positional indices, including
/// disabled columns, instead of turning every label into a selectable quality.
/// No URLs are guessed from CDN ids; the remote CDN map/signing is a later step.
class ZhanqiPlayerLayout {
  ZhanqiPlayerLayout._({
    required this.videoId,
    required this.defaultQualityIndex,
    required List<String> lineNames,
    required List<String> qualityNames,
    required List<String> suffixes,
    required List<ZhanqiPlayerCell> cells,
  }) : lineNames = List.unmodifiable(lineNames),
       qualityNames = List.unmodifiable(qualityNames),
       suffixes = List.unmodifiable(suffixes),
       cells = List.unmodifiable(cells);

  final String videoId;
  final int defaultQualityIndex;
  final List<String> lineNames;
  final List<String> qualityNames;
  final List<String> suffixes;
  final List<ZhanqiPlayerCell> cells;

  List<int> get enabledQualityIndices =>
      List.unmodifiable(cells.map((cell) => cell.qualityIndex).toSet().toList()..sort());
  bool get defaultQualityEnabled => cells.any((cell) => cell.qualityIndex == defaultQualityIndex);

  // Different logical lines may select exactly the same CDN and suffix. Keep
  // their indices in cells, but expose identity groups for consumer deduplication.
  Map<(int, String), List<ZhanqiPlayerCell>> get sourceGroups {
    final result = <(int, String), List<ZhanqiPlayerCell>>{};
    for (final cell in cells) {
      result.putIfAbsent((cell.cdnKey, cell.suffix), () => []).add(cell);
    }
    return Map.unmodifiable(result.map((key, cells) => MapEntry(key, List<ZhanqiPlayerCell>.unmodifiable(cells))));
  }

  static ZhanqiPlayerLayout parseEncoded(
    String encoded, {
    required String expectedRoomId,
    required String expectedVideoId,
  }) {
    if (!RegExp(r'^[1-9][0-9]{0,19}$').hasMatch(expectedRoomId) ||
        !RegExp('^${RegExp.escape(expectedRoomId)}_[A-Za-z0-9_-]{1,64}\$').hasMatch(expectedVideoId)) {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.identity);
    }
    if (encoded.isEmpty || encoded.length > 65536) throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(encoded)));
      if (decoded is! Map<String, dynamic>) throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
      data = decoded;
    } on FormatException {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    }
    if (data['vid'] != expectedVideoId) throw const ZhanqiLayoutException(ZhanqiLayoutFailure.identity);
    if (data['ver'] != '3.0' || data['status'] is! int || data['status'] != 4) {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    }
    // trule changes matrix membership by region. Preserve an explicit gap until
    // that branch has a verified contract; don't publish the unmodified matrix.
    if (data.containsKey('trule')) throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    final lines = _strings(data['line']);
    final rates = _strings(data['rate']);
    final suffixes = _strings(data['suffix']);
    if (rates.length != suffixes.length ||
        suffixes.any((suffix) => !RegExp(r'^(|_[A-Za-z0-9_-]{1,32})$').hasMatch(suffix))) {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    }
    final defaultIndex = data['rateIndex'];
    final matrix = data['square'];
    if (defaultIndex is! int ||
        defaultIndex < 0 ||
        defaultIndex >= rates.length ||
        matrix is! List ||
        matrix.length != lines.length) {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    }
    final cells = <ZhanqiPlayerCell>[];
    for (var line = 0; line < matrix.length; line++) {
      final row = matrix[line];
      if (row is! List || row.length > rates.length) throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
      for (var quality = 0; quality < row.length; quality++) {
        final cdn = row[quality];
        if (cdn is! int || cdn < 0 || cdn > 9999) {
          throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
        }
        if (cdn == 0) continue;
        cells.add(ZhanqiPlayerCell(lineIndex: line, qualityIndex: quality, cdnKey: cdn, suffix: suffixes[quality]));
      }
    }
    return ZhanqiPlayerLayout._(
      videoId: expectedVideoId,
      defaultQualityIndex: defaultIndex,
      lineNames: lines,
      qualityNames: rates,
      suffixes: suffixes,
      cells: cells,
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List ||
        value.isEmpty ||
        value.length > 16 ||
        value.any((item) => item is! String || item.length > 256)) {
      throw const ZhanqiLayoutException(ZhanqiLayoutFailure.schema);
    }
    return List<String>.from(value);
  }
}
