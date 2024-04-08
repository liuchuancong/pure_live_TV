import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'm3u_load_options.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pure_live/core/iptv/src/m3u_item.dart';
import 'package:pure_live/core/iptv/src/m3u_header.dart';
import 'package:pure_live/core/iptv/src/text_utils.dart';
import 'package:pure_live/core/iptv/src/text_utils_string_extension.dart';

class M3uList {
  M3uList._internal();

  M3uLoadOptions _loadOptions = M3uLoadOptions();
  M3uItem? _lastItem;
  String _lastGroupTitle = '';

  M3uHeader? _header;
  final List<M3uItem> _items = <M3uItem>[];
  Set<String>? _groupTitles;

  M3uHeader? get header => _header;

  UnmodifiableListView<M3uItem> get items => UnmodifiableListView(_items);

  UnmodifiableListView<String> get groupTitles {
    _groupTitles ??= _items
        .where((a) => a.groupTitle.isNotEmpty)
        .map((a) => a.groupTitle)
        .toSet();
    return UnmodifiableListView(_groupTitles!);
  }

  static M3uList load(String source, {M3uLoadOptions? options}) {
    final m3uList = M3uList._internal();
    m3uList._load(source, options ?? M3uLoadOptions());
    return m3uList;
  }

  static Future<String> loadJsonFromAssets(String assetsPath) async {
    return await rootBundle.loadString(assetsPath);
  }

  static Future<M3uList> loadFromAssets(String path,
      {M3uLoadOptions? options}) async {
    String jsonData = await loadJsonFromAssets(path);
    return load(jsonData, options: options);
  }

  static Future<M3uList> loadFromFile(String path,
      {M3uLoadOptions? options}) async {
    final file = File(path);
    final source = await file.readAsString();
    return load(source, options: options);
  }

  void _load(String source, M3uLoadOptions options) {
    _loadOptions = options;
    for (var line in LineSplitter.split(source)) {
      if (line.isNullEmptyOrWhitespace) {
        continue;
      }

      line = line.trim();

      if (_header == null) {
        _parseHeader(line);
        if (_header == null) {
          break;
        }
      } else {
        _parseLine(line);
      }
    }
  }

  final _headerPrefix = '#EXTM3U';
  final _itemPrefix = '#EXTINF:';

  final _itemRegex = RegExp(r'^(-?\d+)|([\s,].+=[^,]+)|((?<=[,\d])[^,]+$)',
      caseSensitive: false);

  void _parseHeader(String line) {
    if (!line.startsWith(_headerPrefix)) {
      return;
    }

    line = line.substring(_headerPrefix.length);

    _header = M3uHeader(attributes: getKeyValueList(line, [' ']));
  }

  void _parseLine(String line) {
    if (_lastItem != null) {
      _items.add(M3uItem.fromItem(_lastItem!, line));
      _lastItem = null;
      return;
    }

    if (!line.startsWith(_itemPrefix)) {
      return;
    }

    line = line.substring(_itemPrefix.length);
    final matches =
        _itemRegex.allMatches(line).map((a) => a[0]!.trim()).toList();

    if (matches.length > 1) {
      final attributes =
          matches.length > 2 ? getKeyValueList(matches[1], [' ']) : null;

      var groupTitle =
          attributes != null ? attributes[_loadOptions.groupTitleField] : null;
      groupTitle ??= _lastGroupTitle;
      _lastGroupTitle = groupTitle;
      _lastItem = M3uItem(
          duration: int.parse(matches[0]),
          title: matches.length > 2 ? matches[2] : matches[1],
          groupTitle: groupTitle,
          attributes: attributes);
    } else {
      _lastItem = M3uItem(
          duration: -1,
          title: _loadOptions.wrongItemTitle,
          groupTitle: _lastGroupTitle);
    }
  }
}
