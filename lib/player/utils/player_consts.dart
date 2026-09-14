import 'package:flutter/material.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class PlayerConsts {
  static final String defaultKey = 'mpv';

  static final Map<String, PlayerEngine> engines = {
    'mpv': PlayerEngine.mediaKit,
    'ijk': PlayerEngine.fijk,
    'exo': PlayerEngine.betterPlayer,
  };

  static final Map<String, String> names = {'mpv': 'player_mpv', 'ijk': 'player_ijk', 'exo': 'player_exo'};

  static String getKeyByI18nKey(String i18nKey) {
    return names.entries.firstWhere((e) => e.value == i18nKey, orElse: () => names.entries.first).key;
  }

  /// Stable identifiers of the resolution preference, in display order.
  ///
  /// The preference is stored as one of these keys instead of a display label,
  /// so switching the interface language no longer changes the stored value.
  static const List<String> resolutionKeys = [
    'prefer_resolution_option_original',
    'prefer_resolution_option_blu_ray_8m',
    'prefer_resolution_option_blu_ray_4m',
    'prefer_resolution_option_super_hd',
    'prefer_resolution_option_smooth',
  ];

  /// Labels live platforms use for each preference, including the Chinese
  /// labels the site APIs keep returning in every interface language.
  static const Map<String, List<String>> resolutionAliases = {
    'prefer_resolution_option_original': ['原画', 'original', 'source'],
    'prefer_resolution_option_blu_ray_8m': ['蓝光8m', 'blu-ray 8m'],
    'prefer_resolution_option_blu_ray_4m': ['蓝光4m', '蓝光', 'blu-ray 4m'],
    'prefer_resolution_option_super_hd': ['超清', 'high definition', 'super hd'],
    'prefer_resolution_option_smooth': ['流畅', 'smooth'],
  };

  static final List<String> resolutions = [for (final key in resolutionKeys) i18n(key)];
  static final Map<String, String> resolutionLabelKeys = {for (final key in resolutionKeys) i18n(key): key};

  static String? resolutionLabelKey(String value) => resolutionLabelKeys[value];

  /// Canonical key for a stored preference that may be a key, a localized label
  /// or a label written by an older build.
  static String normalizeResolutionKey(String value) {
    final trimmed = value.trim();
    if (resolutionKeys.contains(trimmed)) return trimmed;
    final byLabel = resolutionLabelKeys[trimmed];
    if (byLabel != null) return byLabel;
    final lower = trimmed.toLowerCase();
    for (final key in resolutionKeys) {
      if (resolutionAliases[key]!.any((alias) => alias.toLowerCase() == lower)) return key;
    }
    return resolutionKeys.first;
  }

  /// How well a platform quality label satisfies the preferred resolution.
  ///
  /// 3 means an exact alias, 2 a label that merely contains one and 0 no match.
  /// Scoring instead of a plain `contains` keeps `蓝光8M` from being picked when
  /// the user asked for `蓝光4M`, which shares the shorter `蓝光` alias.
  static int resolutionMatchScore(String preferenceKey, String qualityLabel) {
    final key = normalizeResolutionKey(preferenceKey);
    final label = qualityLabel.trim().toLowerCase();
    if (label.isEmpty) return 0;
    var score = 0;
    for (final alias in resolutionAliases[key]!) {
      final normalizedAlias = alias.toLowerCase();
      if (label == normalizedAlias) return 3;
      if (label.contains(normalizedAlias)) score = 2;
    }
    return score;
  }

  static String resolutionLabel(String key) => i18n(normalizeResolutionKey(key));

  static Map<String, Color> themeColors = {
    "Crimson": const Color.fromARGB(255, 220, 20, 60),
    "Orange": Colors.orange,
    "Chrome": const Color.fromARGB(255, 230, 184, 0),
    "Grass": Colors.lightGreen,
    "Teal": Colors.teal,
    "SeaFoam": const Color.fromARGB(255, 112, 193, 207),
    "Ice": const Color.fromARGB(255, 115, 155, 208),
    "Blue": Colors.blue,
    "Indigo": Colors.indigo,
    "Violet": Colors.deepPurple,
    "Primary": const Color(0xFF6200EE),
    "Orchid": const Color.fromARGB(255, 218, 112, 214),
    "Variant": const Color(0xFF3700B3),
    "Secondary": const Color(0xFF03DAC6),
  };
  static const videoOutputDrivers = {
    "gpu": "gpu",
    "gpu-next": "gpu-next",
    "xv": "xv (X11 only)",
    "x11": "x11 (X11 only)",
    "vdpau": "vdpau (X11 only)",
    "direct3d": "direct3d (Windows only)",
    "sdl": "sdl",
    "dmabuf-wayland": "dmabuf-wayland",
    "vaapi": "vaapi",
    "null": "null",
    "libmpv": "libmpv",
    "mediacodec_embed": "mediacodec_embed (Android only)",
  };

  static const audioOutputDrivers = {
    "null": "null (No audio output)",
    "pulse": "pulse (Linux, uses PulseAudio)",
    "pipewire": "pipewire (Linux, via Pulse compatibility or native)",
    "alsa": "alsa (Linux only)",
    "oss": "oss (Linux only)",
    "jack": "jack (Linux/macOS, low-latency audio)",
    "directsound": "directsound (Windows only)",
    "wasapi": "wasapi (Windows only)",
    "winmm": "winmm (Windows only, legacy API)",
    "audiounit": "audiounit (iOS only)",
    "coreaudio": "coreaudio (macOS only)",
    "opensles": "opensles (Android only)",
    "audiotrack": "audiotrack (Android only)",
    "aaudio": "aaudio (Android only)",
    "pcm": "pcm (Cross-platform)",
    "sdl": "sdl (Cross-platform, via SDL library)",
    "openal": "openal (Cross-platform, OpenAL backend)",
    "libao": "libao (Cross-platform, uses libao library)",
    "auto": "auto (Automatic fallback)",
  };

  static const hardwareDecoder = {
    "no": "no",
    "auto": "auto",
    "auto-safe": "auto-safe",
    "yes": "yes",
    "auto-copy": "auto-copy",
    "d3d11va": "d3d11va",
    "d3d11va-copy": "d3d11va-copy",
    "videotoolbox": "videotoolbox",
    "videotoolbox-copy": "videotoolbox-copy",
    "vaapi": "vaapi",
    "vaapi-copy": "vaapi-copy",
    "nvdec": "nvdec",
    "nvdec-copy": "nvdec-copy",
    "drm": "drm",
    "drm-copy": "drm-copy",
    "vulkan": "vulkan",
    "vulkan-copy": "vulkan-copy",
    "dxva2": "dxva2",
    "dxva2-copy": "dxva2-copy",
    "vdpau": "vdpau",
    "vdpau-copy": "vdpau-copy",
    "mediacodec": "mediacodec",
    "mediacodec-copy": "mediacodec-copy",
    "cuda": "cuda",
    "cuda-copy": "cuda-copy",
    "crystalhd": "crystalhd",
    "rkmpp": "rkmpp",
  };
}
