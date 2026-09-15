import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/consts/icon_catalog.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';

/// The icon picker stores the chosen entry by its catalog *label*, so labels
/// must be unique and resolvable, and the catalog must be big enough to be a
/// real choice.
void main() {
  test('icon labels are unique', () {
    final labels = kIconCatalog.map((option) => option.label).toList();
    final duplicates = <String>[];
    for (final label in labels) {
      if (labels.where((other) => other == label).length > 1) duplicates.add(label);
    }
    expect(duplicates.toSet(), isEmpty, reason: 'a stored label would be ambiguous');
  });

  test('labels round-trip through the lookup', () {
    for (final option in kIconCatalog) {
      expect(iconOptionForLabel(option.label)?.icon.codePoint, option.icon.codePoint, reason: option.label);
    }
    expect(iconOptionForLabel('not-an-icon'), isNull);
  });

  test('the catalog is a real choice and every label is usable', () {
    expect(kIconCatalog.length, greaterThanOrEqualTo(80));
    for (final option in kIconCatalog) {
      expect(option.label.trim(), isNotEmpty);
      expect(option.label, option.label.trim());
    }
  });

  test('the same icon is not offered twice under different labels', () {
    final seen = <String, String>{};
    final repeats = <String>[];
    for (final option in kIconCatalog) {
      final key = '${option.icon.fontFamily ?? 'MaterialIcons'}:${option.icon.codePoint}';
      final existing = seen[key];
      if (existing != null) {
        repeats.add('$existing / ${option.label}');
      } else {
        seen[key] = option.label;
      }
    }
    expect(repeats, isEmpty);
  });
}
