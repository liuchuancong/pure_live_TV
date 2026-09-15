import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Converts platform SDK quality codes into stable user-facing Chinese labels
/// without changing the opaque identifier used to request that stream.
class LiveQualityLabel {
  const LiveQualityLabel._();

  static String normalize({
    required String platform,
    required String rawLabel,
    Object? id,
    int? bitrate,
    String? resolution,
  }) {
    final raw = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (_containsCjk(raw)) return raw;

    final token = _token(raw.isNotEmpty ? raw : id?.toString() ?? '');
    final platformToken = platform.trim().toLowerCase();
    final mapped = switch (platformToken) {
      'bilibili' => _bilibili(token, id),
      'douyin' => _douyin(token),
      'douyu' || 'huya' || 'kuaishou' || 'cc' || 'yy' => _generic(token),
      'soop' => _soop(token),
      'twitch' => _twitch(raw, token),
      'iptv' => token == 'default' ? i18n('default_option') : null,
      _ => _generic(token),
    };
    if (mapped != null) return mapped;

    final resolutionLabel = _resolutionLabel(resolution);
    if (resolutionLabel != null) return resolutionLabel;
    if (raw.isNotEmpty) return raw;
    if (bitrate != null && bitrate > 0) return _bitrateLabel(bitrate);
    final idText = id?.toString().trim() ?? '';
    return idText.isEmpty
        ? i18n('default_option')
        : i18n('quality_numbered', args: {'value': idText});
  }

  static String? _bilibili(String token, Object? id) {
    final qn = int.tryParse(id?.toString() ?? token);
    return switch (qn) {
      30000 => i18n('ui_dolby'),
      20000 => '4K',
      10000 => i18n('prefer_resolution_option_original'),
      400 => i18n('ui_blu_ray'),
      250 => i18n('prefer_resolution_option_super_hd'),
      150 => i18n('ui_hd'),
      80 => i18n('prefer_resolution_option_smooth'),
      _ => _generic(token),
    };
  }

  static String? _douyin(String token) => switch (token) {
    'origin' || 'origion' || 'original' || 'source' => i18n('prefer_resolution_option_original'),
    'fullhd' || 'fullhd1' || 'uhd' || 'uhd1' || 'blue' || 'bluray' || 'blueray' => i18n('ui_blu_ray'),
    'fhd' || 'hd' || 'hd1' => i18n('prefer_resolution_option_super_hd'),
    'sd' || 'sd2' => i18n('ui_hd'),
    'ld' || 'sd1' => i18n('ui_sd'),
    'md' => i18n('prefer_resolution_option_smooth'),
    'auto' => i18n('recorder_auto'),
    _ => _generic(token),
  };

  static String? _soop(String token) => switch (token) {
    'original' || 'origin' || 'source' => i18n('prefer_resolution_option_original'),
    'master' || 'uhd' => i18n('ui_blu_ray'),
    'fullhd' || 'fhd' => i18n('prefer_resolution_option_super_hd'),
    'hd' => i18n('ui_hd'),
    'sd' || 'normal' => i18n('ui_sd'),
    'low' || 'ld' => i18n('prefer_resolution_option_smooth'),
    'auto' => i18n('recorder_auto'),
    _ => _generic(token),
  };

  static String? _generic(String token) => switch (token) {
    'original' || 'origin' || 'origion' || 'source' => i18n('prefer_resolution_option_original'),
    'blue' || 'bluray' || 'blueray' => i18n('ui_blu_ray'),
    'uhd' || 'super' || 'superhd' || 'fullhd' || 'fhd' => i18n('prefer_resolution_option_super_hd'),
    'hd' || 'high' => i18n('ui_hd'),
    'sd' || 'standard' || 'medium' => i18n('ui_sd'),
    'low' || 'ld' || 'smooth' || 'fluent' => i18n('prefer_resolution_option_smooth'),
    'auto' => i18n('recorder_auto'),
    'default' => i18n('default_option'),
    _ => null,
  };

  static String? _twitch(String raw, String token) {
    final source = token.contains('source');
    final match = RegExp(r'(\d{3,4})p(?:\s*(\d{2,3}))?', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      final fps = match.group(2) ?? '';
      return '${match.group(1)}P$fps${source ? i18n('ui_original') : ''}';
    }
    return source ? i18n('prefer_resolution_option_original') : _generic(token);
  }

  static String _token(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  static bool _containsCjk(String value) => RegExp(r'[\u3400-\u9fff]').hasMatch(value);

  static String? _resolutionLabel(String? value) {
    final match = RegExp(r'(\d{3,5})\s*[x×]\s*(\d{3,5})', caseSensitive: false).firstMatch(value ?? '');
    if (match == null) return null;
    final width = int.tryParse(match.group(1) ?? '') ?? 0;
    final height = int.tryParse(match.group(2) ?? '') ?? 0;
    final shortSide = width < height ? width : height;
    if (shortSide >= 2160) return '4K';
    if (shortSide >= 1440) return i18n('ui_2k_ultra_hd');
    if (shortSide >= 1080) return i18n('ui_1080p_hd');
    if (shortSide >= 720) return i18n('ui_720p_clear');
    if (shortSide >= 480) return i18n('ui_480p_smooth');
    if (shortSide >= 360) return i18n('ui_360p_fast');
    return '${shortSide}P';
  }

  static String _bitrateLabel(int bitsPerSecond) {
    if (bitsPerSecond >= 1000000) {
      final mbps = bitsPerSecond / 1000000;
      return '${mbps.toStringAsFixed(mbps == mbps.roundToDouble() ? 0 : 1)} Mbps';
    }
    return '${(bitsPerSecond / 1000).round()} Kbps';
  }
}
