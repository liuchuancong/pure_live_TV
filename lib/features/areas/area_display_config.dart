import 'package:pure_live/shared/models/live_area/live_area.dart';
import 'package:pure_live/shared/models/live_category/live_category.dart';

/// Per-site display configuration for the areas directory.
///
/// [`LiveSite.getCategores`] always returns a two-level structure (top-level
/// categories with children). The areas page shows a second tab bar per
/// top-level category by default; for sites with only a handful of categories
/// that tab layer fragments the content - rendering all children in one flat
/// grid at once reads better.
///
/// Sites listed in [flatAreaSites] render flat; unlisted sites keep the
/// two-level tabs.
const Set<String> flatAreaSites = <String>{
  'bigo',
  'zhanqi',
  'showroom',
};

/// Whether the areas directory of one site should render flat.
///
/// Two cases:
/// * the site returns a single top-level category - flattening just spreads
///   its children, and an empty tab layer carries no information, so this
///   applies automatically;
/// * the site is listed in [flatAreaSites] - several groups but few entries
///   overall, showing everything at once beats switching tabs.
bool shouldFlattenCategories(String siteId, List<LiveCategory> categories) =>
    categories.length <= 1 || isFlatAreaSite(siteId);

/// Whether [siteId] opted into the flat directory rendering.
bool isFlatAreaSite(String siteId) => flatAreaSites.contains(siteId.trim().toLowerCase());

/// Flattens the two-level category directory into one list.
///
/// Every entry keeps the name of its top-level group ([LiveArea.typeName] is
/// filled by the site layer); flattening only expands, it never reorders.
List<LiveArea> flattenCategories(List<LiveCategory> categories) {
  return <LiveArea>[
    for (final category in categories) ...category.children,
  ];
}
