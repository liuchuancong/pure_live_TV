import 'package:flutter/foundation.dart';
import 'package:pure_live/player/utils/player_consts.dart';

const Map<String, String> _iosVideoOutputDrivers = <String, String>{'libmpv': 'libmpv'};
const Map<String, String> _iosAudioOutputDrivers = <String, String>{
  'auto': 'auto',
  'audiounit': 'audiounit (iOS only)',
  'null': 'null (No audio output)',
};
const Map<String, String> _androidAudioOutputDrivers = <String, String>{
  'auto': 'auto (Automatic fallback)',
  'audiotrack': 'audiotrack (Android AudioTrack)',
  'aaudio': 'aaudio (Android 8.0+)',
  'opensles': 'opensles (Legacy fallback)',
  'null': 'null (No audio output)',
};
const Map<String, String> _iosHardwareDecoders = <String, String>{
  'auto': 'auto',
  'auto-safe': 'auto-safe',
  'auto-copy': 'auto-copy',
  'no': 'no',
  'videotoolbox': 'videotoolbox',
  'videotoolbox-copy': 'videotoolbox-copy',
};

/// Returns only native MPV outputs that the current settings UI may persist.
///
/// media_kit owns the iOS Flutter texture through `vo=libmpv`. Android exposes
/// only drivers compiled into the bundled libmpv instead of mixing Windows and
/// Linux choices into the phone settings menu.
Map<String, String> mpvVideoOutputDriversForPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? _iosVideoOutputDrivers : PlayerConsts.videoOutputDrivers;

Map<String, String> mpvAudioOutputDriversForPlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => _androidAudioOutputDrivers,
  TargetPlatform.iOS => _iosAudioOutputDrivers,
  _ => PlayerConsts.audioOutputDrivers,
};

Map<String, String> mpvHardwareDecodersForPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? _iosHardwareDecoders : PlayerConsts.hardwareDecoder;

String defaultMpvVideoOutputDriverForPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? 'libmpv' : 'gpu';

String normalizeMpvVideoOutputDriverForPlatform(String value, TargetPlatform platform) => _normalizeMpvOption(
  value,
  mpvVideoOutputDriversForPlatform(platform),
  defaultMpvVideoOutputDriverForPlatform(platform),
);

String normalizeMpvAudioOutputDriverForPlatform(String value, TargetPlatform platform) =>
    _normalizeMpvOption(value, mpvAudioOutputDriversForPlatform(platform), 'auto');

/// Native audio preference applied when expert output overrides are disabled.
///
/// The bundled Android libmpv contains all three drivers. Prefer AudioTrack's
/// platform mixer path, retain AAudio and OpenSL ES as ordered fallbacks, then
/// let mpv probe any remaining compiled driver. Linux retains the existing
/// explicit ALSA default; other platforms keep media_kit's native default.
String? defaultMpvAudioOutputDriverForPlatform(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => 'audiotrack,aaudio,opensles,',
  TargetPlatform.linux => 'alsa',
  _ => null,
};

/// Resolves the value sent to libmpv after applying the platform contract.
///
/// Android's bundled libmpv exposes several concrete backends. Treat the
/// user-facing `auto` choice as the same ordered chain used by the safe
/// default instead of passing a pseudo-driver which has produced video with no
/// audio device on real Android builds.
String? effectiveMpvAudioOutputDriverForPlatform({
  required bool customOutput,
  required String configuredDriver,
  required TargetPlatform platform,
}) {
  if (!customOutput) return defaultMpvAudioOutputDriverForPlatform(platform);
  final normalized = normalizeMpvAudioOutputDriverForPlatform(configuredDriver, platform);
  if (platform == TargetPlatform.android && normalized == 'auto') {
    return defaultMpvAudioOutputDriverForPlatform(platform);
  }
  return normalized;
}

bool isMpvAudioOutputDisabledForPlatform({
  required bool customOutput,
  required String configuredDriver,
  required TargetPlatform platform,
}) => customOutput && normalizeMpvAudioOutputDriverForPlatform(configuredDriver, platform) == 'null';

String normalizeMpvHardwareDecoderForPlatform(String value, TargetPlatform platform) =>
    _normalizeMpvOption(value, mpvHardwareDecodersForPlatform(platform), 'auto');

String _normalizeMpvOption(String value, Map<String, String> available, String fallback) =>
    available.containsKey(value) ? value : fallback;
