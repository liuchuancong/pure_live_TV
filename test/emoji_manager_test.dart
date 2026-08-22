import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/plugins/emoji_manager.dart';

Future<ui.Image> _createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, 10, 10),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(10, 10);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EmojiManager.instance.clearCache();
  });

  test('cache eviction keeps at most 100 entries', () async {
    final manager = EmojiManager.instance;

    for (int i = 0; i < 101; i++) {
      final img = await _createTestImage();
      manager.addToCacheForTesting('emoji_$i', img);
    }

    expect(manager.cache.length, equals(100));
    expect(manager.insertionOrder.length, equals(100));
    // Oldest (emoji_0) should have been evicted
    expect(manager.cache.containsKey('emoji_0'), isFalse);
    // Newest (emoji_100) should still be present
    expect(manager.cache.containsKey('emoji_100'), isTrue);
  });

  test('clearCache empties cache and insertionOrder', () async {
    final manager = EmojiManager.instance;

    for (int i = 0; i < 10; i++) {
      final img = await _createTestImage();
      manager.addToCacheForTesting('emoji_$i', img);
    }

    expect(manager.cache.length, equals(10));
    expect(manager.insertionOrder.length, equals(10));

    manager.clearCache();

    expect(manager.cache.length, equals(0));
    expect(manager.insertionOrder.length, equals(0));
  });

  test('insertionOrder stays in sync with cache', () async {
    final manager = EmojiManager.instance;

    for (int i = 0; i < 50; i++) {
      final img = await _createTestImage();
      manager.addToCacheForTesting('emoji_$i', img);
    }

    expect(manager.cache.length, equals(manager.insertionOrder.length));
    expect(
      manager.cache.keys.toSet(),
      equals(manager.insertionOrder.toSet()),
    );
  });

  test('emoji decode size is 40x40 for memory optimization', () {
    // Verify the decode dimensions are set to 40x40 (was 80x80)
    // 40x40 RGBA = 6.4KB per emoji vs 25.6KB at 80x80
    expect(EmojiManager.maxDecodeWidth, equals(40));
    expect(EmojiManager.maxDecodeHeight, equals(40));
  });
}
