import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';

/// The 排序 page's promise: **who you pick is who moves, and you say where it
/// goes.**
///
/// The rule is pure (`AppSettingsController.reorderMenuIds`), so it is pinned here
/// without the preference store: the chosen entry lands exactly on the position
/// the user named, the entries it passes shift by one, and nothing is lost.
void main() {
  final List<String> defaults = HomeMenu.defaultOrder;

  test('the chosen entry lands exactly on the named position', () {
    // Pick the last entry and name position 1.
    final moved = AppSettingsController.reorderMenuIds(defaults, defaults.last, 0);
    expect(moved.first, defaults.last);

    // Everything it passed shifted down by one, in order.
    expect(moved.sublist(1), defaults.sublist(0, defaults.length - 1));
  });

  test('moving forwards shifts the entries it passes up', () {
    final moved = AppSettingsController.reorderMenuIds(defaults, defaults.first, defaults.length - 1);
    expect(moved.last, defaults.first);
    expect(moved.sublist(0, moved.length - 1), defaults.sublist(1));
  });

  test('no entry is lost or duplicated, whatever the move', () {
    for (final id in defaults) {
      for (int target = 0; target < defaults.length; target++) {
        final moved = AppSettingsController.reorderMenuIds(defaults, id, target);
        expect(moved, hasLength(defaults.length), reason: '$id -> $target');
        expect(moved.toSet(), defaults.toSet(), reason: '$id -> $target');
        expect(moved.indexOf(id), target, reason: '$id -> $target');
      }
    }
  });

  test('naming the position an entry already holds changes nothing', () {
    final moved = AppSettingsController.reorderMenuIds(defaults, defaults[2], 2);
    expect(moved, defaults);
  });

  test('an out-of-range position clamps, and an unknown entry is a no-op', () {
    expect(AppSettingsController.reorderMenuIds(defaults, defaults[1], 99).last, defaults[1]);
    expect(AppSettingsController.reorderMenuIds(defaults, defaults[1], -5).first, defaults[1]);
    expect(AppSettingsController.reorderMenuIds(defaults, 'not-a-menu', 0), defaults);
    expect(AppSettingsController.reorderMenuIds(const <String>[], 'favorite', 0), isEmpty);
  });

  test('the helper never mutates the list it was given', () {
    final original = List<String>.from(defaults);
    AppSettingsController.reorderMenuIds(original, original.first, 3);
    expect(original, defaults);
  });
}
