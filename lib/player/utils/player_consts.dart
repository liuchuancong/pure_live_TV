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
    "wlshm": "wlshm (Wayland SHM, Linux only)",
    "vaapi": "vaapi",
    "drm": "drm (Linux only)",
    "caca": "caca (macOS / Linux only)",
    "avfoundation": "avfoundation (macOS / iOS only)",
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

  /// 可选硬件解码器。
  ///
  /// 键、顺序和中英文标签都取自移动端
  /// (`pure_live/lib/player/utils/player_consts.dart` 的 `hardwareDecodersList`)，
  /// 这样设置页显示的就不再是 mpv 的原始键。各平台只展示自己可用的子集。
  static const List<Map<String, String>> hardwareDecodersList = [
    {'key': 'auto', 'nameEn': 'Any Available Decoder', 'nameZh': '启用任意可用解码器'},
    {'key': 'auto-safe', 'nameEn': 'Best Decoder', 'nameZh': '启用最佳解码器'},
    {'key': 'auto-copy', 'nameEn': 'Best Decoder with Copy-Back', 'nameZh': '启用带拷贝功能的最佳解码器'},
    {'key': 'd3d11va', 'nameEn': 'DirectX 11 (Windows 8+)', 'nameZh': 'DirectX 11（Windows 8 及以上）'},
    {'key': 'd3d11va-copy', 'nameEn': 'DirectX 11 (Copy-Back)', 'nameZh': 'DirectX 11（非直通）'},
    {'key': 'videotoolbox', 'nameEn': 'VideoToolbox (macOS / iOS)', 'nameZh': 'VideoToolbox（macOS / iOS）'},
    {'key': 'videotoolbox-copy', 'nameEn': 'VideoToolbox (Copy-Back)', 'nameZh': 'VideoToolbox（非直通）'},
    {'key': 'vaapi', 'nameEn': 'VAAPI (Linux)', 'nameZh': 'VAAPI（Linux）'},
    {'key': 'vaapi-copy', 'nameEn': 'VAAPI (Copy-Back)', 'nameZh': 'VAAPI（非直通）'},
    {'key': 'nvdec', 'nameEn': 'NVDEC (NVIDIA Only)', 'nameZh': 'NVDEC（仅 NVIDIA）'},
    {'key': 'nvdec-copy', 'nameEn': 'NVDEC (NVIDIA Only, Copy-Back)', 'nameZh': 'NVDEC（仅 NVIDIA，非直通）'},
    {'key': 'drm', 'nameEn': 'DRM (Linux)', 'nameZh': 'DRM（Linux）'},
    {'key': 'drm-copy', 'nameEn': 'DRM (Copy-Back)', 'nameZh': 'DRM（非直通）'},
    {'key': 'vulkan', 'nameEn': 'Vulkan (Experimental)', 'nameZh': 'Vulkan（全平台，实验性）'},
    {'key': 'vulkan-copy', 'nameEn': 'Vulkan (Experimental, Copy-Back)', 'nameZh': 'Vulkan（全平台，实验性，非直通）'},
    {'key': 'dxva2', 'nameEn': 'DXVA2 (Windows 7+)', 'nameZh': 'DXVA2（Windows 7 及以上）'},
    {'key': 'dxva2-copy', 'nameEn': 'DXVA2 (Copy-Back)', 'nameZh': 'DXVA2（非直通）'},
    {'key': 'vdpau', 'nameEn': 'VDPAU (Linux)', 'nameZh': 'VDPAU（Linux）'},
    {'key': 'vdpau-copy', 'nameEn': 'VDPAU (Copy-Back)', 'nameZh': 'VDPAU（非直通）'},
    {'key': 'mediacodec', 'nameEn': 'MediaCodec (Android)', 'nameZh': 'MediaCodec（Android）'},
    {'key': 'mediacodec-copy', 'nameEn': 'MediaCodec (Copy-Back)', 'nameZh': 'MediaCodec（Android，非直通）'},
    {'key': 'cuda', 'nameEn': 'CUDA (NVIDIA Only, Deprecated)', 'nameZh': 'CUDA（仅 NVIDIA，已过时）'},
    {'key': 'cuda-copy', 'nameEn': 'CUDA (NVIDIA Only, Deprecated, Copy-Back)', 'nameZh': 'CUDA（仅 NVIDIA，已过时，非直通）'},
    {'key': 'crystalhd', 'nameEn': 'CrystalHD (Deprecated)', 'nameZh': 'CrystalHD（全平台，已过时）'},
    {'key': 'rkmpp', 'nameEn': 'Rockchip MPP (Selected Rockchip SoCs)', 'nameZh': 'Rockchip MPP（仅部分 Rockchip 芯片）'},
  ];

  /// 可选音频输出驱动（同移动端 `audio_output_settings_page.dart` 的列表）。
  static const List<Map<String, String>> audioOutputDriversList = [
    {'key': 'auto', 'nameEn': 'Auto', 'nameZh': '自动选择'},
    {'key': 'null', 'nameEn': 'Null (No Audio Output)', 'nameZh': 'Null（不输出音频）'},
    {'key': 'pulse', 'nameEn': 'PulseAudio (Linux)', 'nameZh': 'PulseAudio（Linux）'},
    {'key': 'pipewire', 'nameEn': 'PipeWire (Linux)', 'nameZh': 'PipeWire（Linux）'},
    {'key': 'alsa', 'nameEn': 'ALSA (Linux Only)', 'nameZh': 'ALSA（仅 Linux）'},
    {'key': 'oss', 'nameEn': 'OSS (Linux Only)', 'nameZh': 'OSS（仅 Linux）'},
    {'key': 'jack', 'nameEn': 'JACK (Linux / macOS, Low Latency)', 'nameZh': 'JACK（Linux / macOS，低延迟音频）'},
    {'key': 'directsound', 'nameEn': 'DirectSound (Windows Only)', 'nameZh': 'DirectSound（仅 Windows）'},
    {'key': 'wasapi', 'nameEn': 'WASAPI (Windows Only)', 'nameZh': 'WASAPI（仅 Windows）'},
    {'key': 'winmm', 'nameEn': 'WinMM (Windows Only, Legacy)', 'nameZh': 'WinMM（仅 Windows，旧版 API）'},
    {'key': 'audiounit', 'nameEn': 'AudioUnit (iOS Only)', 'nameZh': 'AudioUnit（仅 iOS）'},
    {'key': 'coreaudio', 'nameEn': 'CoreAudio (macOS Only)', 'nameZh': 'CoreAudio（仅 macOS）'},
    {'key': 'opensles', 'nameEn': 'OpenSL ES (Android Only)', 'nameZh': 'OpenSL ES（仅 Android）'},
    {'key': 'audiotrack', 'nameEn': 'AudioTrack (Android Only)', 'nameZh': 'AudioTrack（仅 Android）'},
    {'key': 'aaudio', 'nameEn': 'AAudio (Android Only)', 'nameZh': 'AAudio（仅 Android）'},
    {'key': 'pcm', 'nameEn': 'PCM (Cross-Platform)', 'nameZh': 'PCM（跨平台）'},
    {'key': 'sdl', 'nameEn': 'SDL (Cross-Platform)', 'nameZh': 'SDL（跨平台）'},
    {'key': 'openal', 'nameEn': 'OpenAL (Cross-Platform)', 'nameZh': 'OpenAL（跨平台）'},
    {'key': 'libao', 'nameEn': 'libao (Cross-Platform)', 'nameZh': 'libao（跨平台）'},
  ];

  /// 可选视频渲染器（同移动端 `renderer_settings.dart` 的列表）。
  static const List<Map<String, String>> videoRenderersList = [
    {'key': 'auto', 'nameEn': 'Auto', 'nameZh': '自动选择'},
    {'key': 'gpu', 'nameEn': 'GPU', 'nameZh': 'GPU'},
    {'key': 'gpu-next', 'nameEn': 'GPU Next', 'nameZh': 'GPU Next'},
    {'key': 'sdl', 'nameEn': 'SDL', 'nameZh': 'SDL'},
    {'key': 'null', 'nameEn': 'Null (No Video Output)', 'nameZh': 'Null（不输出视频）'},
    {'key': 'mediacodec_embed', 'nameEn': 'MediaCodec Embed (Android Only)', 'nameZh': 'MediaCodec Embed（仅 Android）'},
    {'key': 'direct3d', 'nameEn': 'Direct3D (Windows Only)', 'nameZh': 'Direct3D（仅 Windows）'},
    {'key': 'vaapi', 'nameEn': 'VA-API (Linux Only)', 'nameZh': 'VA-API（仅 Linux）'},
    {'key': 'vdpau', 'nameEn': 'VDPAU (Linux Only)', 'nameZh': 'VDPAU（仅 Linux）'},
    {'key': 'drm', 'nameEn': 'DRM (Linux Only)', 'nameZh': 'DRM（仅 Linux）'},
    {'key': 'wlshm', 'nameEn': 'Wayland SHM (Linux Only)', 'nameZh': 'Wayland SHM（仅 Linux）'},
    {'key': 'dmabuf-wayland', 'nameEn': 'DMABUF Wayland (Linux Only)', 'nameZh': 'DMABUF Wayland（仅 Linux）'},
    {'key': 'x11', 'nameEn': 'X11 (Linux Only)', 'nameZh': 'X11（仅 Linux）'},
    {'key': 'xv', 'nameEn': 'XVideo (Linux Only)', 'nameZh': 'XVideo（仅 Linux）'},
    {'key': 'caca', 'nameEn': 'CACA (macOS / Linux)', 'nameZh': 'CACA（macOS / Linux）'},
    {'key': 'avfoundation', 'nameEn': 'AVFoundation (macOS / iOS)', 'nameZh': 'AVFoundation（macOS / iOS）'},
  ];

  /// Label of one entry of an option list above.
  ///
  /// The lists carry both languages, exactly like the mobile app, so a settings
  /// page can show a translatable name instead of the raw mpv key.
  static String optionLabel(Map<String, String> option, String languageCode) =>
      languageCode == 'zh' ? option['nameZh']! : option['nameEn']!;

  /// Label of [key] inside [options]; [fallback] (then [key]) when it is absent.
  static String optionLabelFor(
    List<Map<String, String>> options,
    String key,
    String languageCode, {
    String? fallback,
  }) {
    for (final option in options) {
      if (option['key'] == key) return optionLabel(option, languageCode);
    }
    return fallback ?? key;
  }
}
