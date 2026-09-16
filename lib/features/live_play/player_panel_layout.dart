import 'package:flutter/foundation.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Layout of the player's side panels: which edge, how far from it, and how big
/// the text is.
///
/// Stored in preferences (not in the settings models, which are generated) so the
/// player can adjust it from inside the panel without a codegen run. A
/// [ValueNotifier] lets the player rebuild when a value changes.
class PlayerPanelLayout {
  PlayerPanelLayout._();

  static const String _sideKey = 'playerPanelSide';
  static const String _offsetKey = 'playerPanelOffset';
  static const String _fontSizeKey = 'playerPanelFontSize';

  /// Bumped on every change so listeners can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// `'right'` (default) or `'left'`.
  static String get side => HivePrefUtil.getString(_sideKey) ?? 'right';
  static bool get isLeft => side == 'left';

  /// Distance from that edge, in design pixels.
  static int get offset => HivePrefUtil.getInt(_offsetKey) ?? 24;

  /// Panel text scale, 1.0 = the default size.
  static double get fontSize => HivePrefUtil.getDouble(_fontSizeKey) ?? 1.0;

  static void setSide(String value) {
    HivePrefUtil.setString(_sideKey, value == 'left' ? 'left' : 'right');
    revision.value++;
  }

  static void toggleSide() => setSide(isLeft ? 'right' : 'left');

  static const List<int> offsetSteps = <int>[0, 8, 16, 24, 32, 48, 64];

  static void setOffset(int value) {
    HivePrefUtil.setInt(_offsetKey, value.clamp(0, 200));
    revision.value++;
  }

  static void stepOffset({required bool forward}) {
    final int current = offset;
    final List<int> steps = offsetSteps;
    int index = steps.indexOf(current);
    if (index < 0) {
      // A value set elsewhere (a migrated profile) is kept: the next step moves
      // to the next entry above/below it instead of snapping to a preset.
      final Iterable<int> larger = steps.where((value) => value > current);
      final Iterable<int> smaller = steps.where((value) => value < current).toList().reversed;
      setOffset(forward ? (larger.isEmpty ? current : larger.first) : (smaller.isEmpty ? current : smaller.first));
      return;
    }
    index = (index + (forward ? 1 : -1)).clamp(0, steps.length - 1);
    setOffset(steps[index]);
  }

  static const List<double> fontSizeSteps = <double>[0.8, 0.9, 1.0, 1.1, 1.25, 1.5];

  static void stepFontSize({required bool forward}) {
    final double current = fontSize;
    int index = fontSizeSteps.indexOf(current);
    if (index < 0) {
      final Iterable<double> larger = fontSizeSteps.where((value) => value > current);
      final Iterable<double> smaller = fontSizeSteps.where((value) => value < current).toList().reversed;
      final double next = forward ? (larger.isEmpty ? current : larger.first) : (smaller.isEmpty ? current : smaller.first);
      HivePrefUtil.setDouble(_fontSizeKey, next.clamp(0.6, 2.0));
      revision.value++;
      return;
    }
    index = (index + (forward ? 1 : -1)).clamp(0, fontSizeSteps.length - 1);
    HivePrefUtil.setDouble(_fontSizeKey, fontSizeSteps[index]);
    revision.value++;
  }

  static String get fontSizeLabel => '${(fontSize * 100).round()}%';
}
