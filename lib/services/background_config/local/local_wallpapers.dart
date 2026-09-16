/// Sources that need no index download at all.
///
/// * **Solid colours and gradients** are a fixed table, compiled into the app
///   ([kSolidGradients]); nothing about them changes, so fetching them from a
///   git mirror on every visit only added latency and a failure mode.
/// * **deepin** is 26 files under the public iTab CDN.
///
/// Live wallpapers used to live here too, but `/wallpaper/video/list` answers
/// without a token, so they page from the API like every other browser source.
library;

import 'package:pure_live/services/background_config/local/solid_gradients.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// Public CDN holding the deepin wallpaper set.
const String kItabFilesBase = 'https://files.itab.link';

/// Server-side resize preset used for grid thumbnails.
const String kThumbProcess = 'x-oss-process=image/resize,limit_0,m_fill,w_400,h_225/quality,q_72/format,webp';

/// The 26 deepin/UOS wallpapers, named by hand from the artwork.
const Map<int, String> kDeepinNames = <int, String>{
  0: 'Purple Salt Flats Sunset',
  1: 'Antelope Canyon Waves',
  2: 'Autumn Forest Canopy',
  3: 'Sunset Mountain Ridge',
  4: 'Deepin Logo Gradient',
  5: 'Deepin Logo Ribbons',
  6: 'Neon Vortex Glow',
  7: 'Aurora Borealis Night',
  8: 'Sandstone Canyon Passage',
  9: 'Starry Desert Dunes',
  10: 'Desert Dunes at Dawn',
  11: 'White Facade Blue Sky',
  12: 'Blue Betta Fish',
  13: 'Vestrahorn Beach Reflection',
  14: 'Snowy Ridges at Dusk',
  15: 'Emerald Coast Aerial',
  16: 'Peak Above the Clouds',
  17: 'Dune Ripples at Sunset',
  18: 'Crescent Dune Moonlight',
  19: 'Misty Lake at Dawn',
  20: 'Foggy Pine Forest',
  21: 'Frozen Lake Sunrise',
  22: 'Snow Peak at Sunset',
  23: 'Jellyfish in Blue Water',
  24: 'Eagle Over the Falls',
  25: 'Mountain Lake Reflection',
};

/// `https://…/x.jpg` → `https://…/x.jpg?x-oss-process=…` (or `&…` if it already
/// carries a query). A URL that is already processed is left alone.
String cdnThumb(String url) {
  if (url.isEmpty || url.contains('x-oss-process')) return url;
  final separator = url.contains('?') ? '&' : '?';
  return '$url$separator$kThumbProcess';
}

/// The compiled-in solid colours and gradients.
class LocalWallpapers {
  const LocalWallpapers._();

  /// Flat swatches first, then the 139 gradients.
  static final List<BackgroundItem> solidItems = <BackgroundItem>[
    for (var i = 0; i < kSolidPalette.length; i++)
      BackgroundItem(
        id: 'flat-$i',
        name: kSolidPalette[i],
        file: 'solid-color#flat-$i',
        css: 'solid ${kSolidPalette[i]}',
        gradient: <BackgroundGradientStop>[
          BackgroundGradientStop(color: kSolidPalette[i], pos: 0),
          BackgroundGradientStop(color: kSolidPalette[i], pos: 100),
        ],
      ),
    for (var i = 0; i < kSolidGradients.length; i++)
      BackgroundItem(
        id: 'gradient-$i',
        name: kSolidGradients[i].name,
        file: 'solid-color#gradient-$i',
        css: kSolidGradients[i].stops.map((s) => '${s.$1} ${s.$2.round()}%').join(', '),
        deg: kSolidGradients[i].deg,
        gradient: <BackgroundGradientStop>[
          for (final (color, pos) in kSolidGradients[i].stops)
            BackgroundGradientStop(color: color, pos: pos),
        ],
      ),
  ];

  /// The deepin/UOS set.
  static final List<BackgroundItem> deepinItems = <BackgroundItem>[
    for (final entry in kDeepinNames.entries)
      BackgroundItem(
        id: '${entry.key}',
        name: entry.value,
        file: '$kItabFilesBase/wallpaper/deepin/${entry.key}.jpg',
        thumb: cdnThumb('$kItabFilesBase/wallpaper/deepin/${entry.key}.jpg'),
      ),
  ];

  /// The list belonging to one local source id, or empty for a server source.
  static List<BackgroundItem> of(String sourceId) => switch (sourceId) {
    BackgroundSourceIds.solidColor => solidItems,
    BackgroundSourceIds.deepin => deepinItems,
    _ => const <BackgroundItem>[],
  };
}
