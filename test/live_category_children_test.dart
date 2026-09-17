import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/models/live_category/live_category.dart';

/// 获取接口数据 → 数据加载失败：`Unsupported operation: Cannot add to an unmodifiable list`.
///
/// `LiveCategory` is a freezed model, so `children` is an unmodifiable view of the list
/// the category was built with: `children.addAll(...)` after construction throws. Five
/// platforms (虎牙 / 快手 / YY / Twitch / SOOP) built their category list first and filled
/// `children` afterwards, so the 分区 page showed that exception as 数据加载失败 the moment
/// one of them was selected. The sub-categories have to be passed to the constructor — or
/// the category rebuilt with `copyWith(children: …)`.
void main() {
  test('LiveCategory.children cannot be filled after construction', () {
    const LiveCategory category = LiveCategory(id: '1', name: 'hot');
    expect(category.children, isEmpty);
    expect(() => category.children.clear(), throwsUnsupportedError);
  });

  test('no platform fills a category children list in place', () {
    final Directory platforms = Directory('lib/platforms');
    if (!platforms.existsSync()) {
      markTestSkipped('platform sources not found relative to ${Directory.current.path}');
      return;
    }

    final RegExp mutation = RegExp(r'\.children\.(add|addAll|insert|remove|clear|sort)\s*\(');
    final List<String> offenders = <String>[];
    for (final FileSystemEntity entity in platforms.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final List<String> lines = entity.readAsLinesSync();
      for (int line = 0; line < lines.length; line++) {
        if (mutation.hasMatch(lines[line])) offenders.add('${entity.path}:${line + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'LiveCategory.children is an unmodifiable view: build the list first and pass '
          'it to the constructor (or copyWith) instead of mutating it',
    );
  });
}
