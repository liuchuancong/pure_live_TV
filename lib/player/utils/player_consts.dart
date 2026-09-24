import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart' as media_core_media_kit;

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
  /// Scoring instead of a plain `contains` keeps `blu-ray 8m` from being picked when
  /// the user asked for `blu-ray 4m`, which shares the shorter `blu-ray` alias.
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

  /// Raw mpv option catalogs.
  ///
  /// These three tables are the *only* part of this file that media_core
  /// already owns, so they are re-exported from
  /// `media_core_media_kit`'s `PlayerConsts` instead of being duplicated
  /// here — two copies of the same driver list drift, and the platform
  /// normaliser in the package reads its own copy anyway.
  ///
  /// Everything else in this class (engine keys, resolution preferences,
  /// the labelled option lists below) is app-specific and stays here.
  static const videoOutputDrivers = media_core_media_kit.PlayerConsts.videoOutputDrivers;

  static const audioOutputDrivers = media_core_media_kit.PlayerConsts.audioOutputDrivers;

  static const hardwareDecoder = media_core_media_kit.PlayerConsts.hardwareDecoder;

  /// Hardware decoders available to mpv.
  ///
  /// Keys, order and labels mirror the mobile app
  /// (hardwareDecodersList in pure_live's player_consts.dart),
  /// so raw mpv keys never reach the settings page. Each platform shows its own subset.
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

  /// Audio output drivers available to mpv, mirroring the mobile app's list.
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

  /// Video renderers available to mpv, mirroring the mobile app's list.
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
  static String optionLabelFor(List<Map<String, String>> options, String key, String languageCode, {String? fallback}) {
    for (final option in options) {
      if (option['key'] == key) return optionLabel(option, languageCode);
    }
    return fallback ?? key;
  }
}
