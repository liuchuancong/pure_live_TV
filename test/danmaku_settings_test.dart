import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_config_builder.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_option_steps.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';

/// 弹幕设置 → flame_barrage: every setting the UI offers has to reach the engine, in the
/// unit the engine expects.
///
/// The reported symptom was "设置改了但弹幕没变化". Two causes lived here: the speed was
/// stored on the legacy 4-32 "level" scale while `BarrageConfig.baseSpeed` is px/s (so a
/// level of 8 froze the danmaku), and the bottom inset was handed a 0.0-0.8 *ratio* while
/// `bottomAreaDistance` is measured in pixels (so the slider did nothing at all).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A model where every appearance field is set to a distinctive value.
  DanmakuSettingsModel distinctive() => const DanmakuSettingsModel(
    danmakuFontSize: 27,
    danmakuFontWeight: 700,
    danmakuArea: 0.63,
    danmakuTopArea: 41,
    danmakuBottomArea: 137,
    danmakuSpeed: 260,
    danmakuOpacity: 0.42,
    danmakuFontBorder: 3,
    enableDanmakuStroke: false,
    noEmojiMode: true,
    danmakuFps: 90,
    danmakuAutoFps: false,
  );

  group('the engine config carries every appearance setting', () {
    test('each field lands on its BarrageConfig counterpart', () {
      final config = buildDanmakuConfig(distinctive(), fontFamily: 'SourceHanSans');

      expect(config.fontSize, 27);
      expect(config.fontWeight, FontWeight.w700);
      expect(config.area, 0.63);
      expect(config.topAreaDistance, 41);
      expect(config.bottomAreaDistance, 137);
      expect(config.baseSpeed, 260, reason: 'px/s, exactly what the UI shows');
      expect(config.opacity, 0.42);
      expect(config.strokeWidth, 3);
      expect(config.showStroke, isFalse);
      expect(config.noEmojiMode, isTrue);
      expect(config.fps, 90);
      expect(config.fontFamily, 'SourceHanSans');
      // The derived metrics move with the font size, and the caps stay in place.
      expect(config.trackHeight, closeTo(27 * 1.55, 0.001));
      expect(config.emojiSize, closeTo(27 * 1.3, 0.001));
      expect(config.maxVisibleCount, 48);
      expect(config.emitInterval, 0.05);
    });

    test('out-of-range values cannot reach the renderer', () {
      const hostile = DanmakuSettingsModel(
        danmakuSpeed: 3,
        danmakuTopArea: -5,
        danmakuBottomArea: 9000,
        danmakuArea: 4,
        danmakuOpacity: -1,
        danmakuFontSize: 400,
        danmakuFontWeight: 12,
      );

      final config = buildDanmakuConfig(hostile);

      expect(config.baseSpeed, greaterThanOrEqualTo(DanmakuSettingsModel.minSpeed));
      expect(config.topAreaDistance, DanmakuSettingsModel.minDistance);
      expect(config.bottomAreaDistance, DanmakuSettingsModel.maxDistance);
      expect(config.area, lessThanOrEqualTo(DanmakuSettingsModel.maxArea));
      expect(config.opacity, greaterThanOrEqualTo(0.05));
      expect(config.fontWeight.value, greaterThanOrEqualTo(100));
    });
  });

  group('stored values are normalised into the engine units', () {
    test('a legacy "level" speed becomes the default speed, not a frozen danmaku', () {
      // 8 was the old level scale; as px/s it would take a minute to cross the screen.
      expect(DanmakuSettingsModel.normalizeSpeed(8), DanmakuSettingsModel.defaultSpeed);
      expect(DanmakuSettingsModel.normalizeSpeed(0), DanmakuSettingsModel.defaultSpeed);
      expect(DanmakuSettingsModel.normalizeSpeed(null), DanmakuSettingsModel.defaultSpeed);
      // Real speeds survive, and are bounded.
      expect(DanmakuSettingsModel.normalizeSpeed(150), 150);
      expect(DanmakuSettingsModel.normalizeSpeed(9999), DanmakuSettingsModel.maxSpeed);
    });

    test('a legacy ratio inset becomes no inset instead of half a pixel', () {
      expect(DanmakuSettingsModel.normalizeDistance(0.5), 0);
      expect(DanmakuSettingsModel.normalizeDistance(0), 0);
      expect(DanmakuSettingsModel.normalizeDistance(120), 120);
      expect(DanmakuSettingsModel.normalizeDistance(-4), 0);
      expect(DanmakuSettingsModel.normalizeDistance(1000), DanmakuSettingsModel.maxDistance);
    });

    test('font weights snap to the hundreds the engine exposes', () {
      expect(DanmakuSettingsModel.normalizeFontWeight(537), 500);
      expect(DanmakuSettingsModel.normalizeFontWeight(880), 800);
      expect(DanmakuSettingsModel.normalizeFontWeight(null), 500);
    });
  });

  group('the controls agree with the engine', () {
    test('the panel candidates sit inside the model bounds', () {
      for (final double speed in DanmakuOptionSteps.speed) {
        expect(speed, greaterThanOrEqualTo(DanmakuSettingsModel.minSpeed));
        expect(speed, lessThanOrEqualTo(DanmakuSettingsModel.maxSpeed));
      }
      for (final double distance in DanmakuOptionSteps.distance) {
        expect(distance, greaterThanOrEqualTo(DanmakuSettingsModel.minDistance));
        expect(distance, lessThanOrEqualTo(DanmakuSettingsModel.maxDistance));
      }
      for (final double stroke in DanmakuOptionSteps.stroke) {
        expect(stroke, inInclusiveRange(0, 8));
      }
      expect(DanmakuOptionSteps.speed, contains(DanmakuSettingsModel.defaultSpeed));
    });

    test('labels show the value the engine receives', () {
      expect(DanmakuOptionSteps.speedLabel(120), '120 px/s');
      expect(DanmakuOptionSteps.pixelLabel(3), '3 px', reason: 'stroke is not 2x+2 any more');
      expect(DanmakuOptionSteps.percent(0.42), '42%');
    });

    test('auto fps follows the panel, manual fps is used as-is', () {
      const auto = DanmakuSettingsModel(danmakuAutoFps: true);
      const manual = DanmakuSettingsModel(danmakuAutoFps: false, danmakuFps: 90);

      expect(resolveDanmakuFps(auto, refreshRate: 120), 120);
      expect(resolveDanmakuFps(auto, refreshRate: 59.94), 60);
      expect(resolveDanmakuFps(auto, refreshRate: 0), 60, reason: 'unknown panel rate');
      expect(resolveDanmakuFps(manual, refreshRate: 120), 90);
    });
  });

  group('flame_barrage api coverage', () {
    test('every BarrageConfig field is read by the engine', () {
      final File config = File('plugins/flame_barrage/lib/src/core/barrage_config.dart');
      final Directory plugin = Directory('plugins/flame_barrage/lib');
      if (!config.existsSync() || !plugin.existsSync()) {
        markTestSkipped('flame_barrage sources not found relative to ${Directory.current.path}');
        return;
      }

      final declared = <String>{
        for (final match in RegExp(r'^\s+final [\w<>, ?\.]+ (\w+);', multiLine: true)
            .allMatches(config.readAsStringSync()))
          match.group(1)!,
      };
      expect(declared, isNotEmpty);

      final engine = StringBuffer();
      for (final entity in plugin.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('barrage_config.dart')) continue;
        engine.write(entity.readAsStringSync());
      }
      final usage = engine.toString();

      final unused = <String>[
        for (final field in declared)
          // `copyWith` re-lists the fields but never reads them off a config instance.
          if (!usage.contains('config.$field')) field,
      ];
      expect(
        unused,
        isEmpty,
        reason: 'a config field no code reads is a setting that can never take effect: $unused',
      );
    });
  });
}
