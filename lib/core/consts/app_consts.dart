import 'package:collection/collection.dart';

/// Home side-menu entries. The persisted `savedMenuIds` list holds the visible
/// entries in display order; an empty list means "show everything in default
/// order".
enum HomeMenu {
  favorite('favorite'),
  hot('hot'),
  areas('areas'),
  favoriteAreas('favoriteAreas'),
  moviePlayback('moviePlayback'),
  search('search'),
  history('history');

  final String id;
  const HomeMenu(this.id);

  static List<String> get defaultOrder => HomeMenu.values.map((e) => e.id).toList(growable: false);

  static HomeMenu? fromId(String id) => HomeMenu.values.firstWhereOrNull((e) => e.id == id);
}
