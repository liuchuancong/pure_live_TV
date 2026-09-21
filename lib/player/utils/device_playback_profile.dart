import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// What the current device can afford inside the MPV pipeline.
///
/// The TV build runs on Android boxes whose RAM is measured in single
/// gigabytes and whose SoC cannot always hardware-decode the stream a room
/// offers. This profile never changes *what* is played — it only decides how
/// much decode work and demuxer memory mpv may spend on it, so a box that has
/// to fall back to software decoding drops fewer frames instead of stuttering.
///
/// The probe is deliberately conservative: a device is only treated as low-end
/// when Android itself flags it ([AndroidDeviceInfo.isLowRamDevice]) or its
/// total RAM is at most [lowRamThresholdMb]. An unreadable RAM figure never
/// downgrades a device, so a failed probe leaves playback exactly as it was.
@immutable
final class DevicePlaybackProfile {
  /// Creates a profile.
  const DevicePlaybackProfile({required this.lowEnd, required this.cpuCores, this.totalRamMb});

  /// The profile used before [ensureLoaded] ran, or when the probe failed.
  ///
  /// Not low-end on purpose: an unknown device keeps today's behaviour instead
  /// of being silently tuned down.
  static const DevicePlaybackProfile unknown = DevicePlaybackProfile(lowEnd: false, cpuCores: 4);

  /// Total RAM ceiling, in megabytes, below which a device counts as low-end.
  ///
  /// 2 GB is where Android boxes stop being able to hold a 1080p decode
  /// pipeline plus the demuxer budget next to the rest of the app.
  static const int lowRamThresholdMb = 2048;

  /// Whether the device cannot be assumed to decode full-resolution video
  /// smoothly in software.
  final bool lowEnd;

  /// Logical CPU cores, used to size the software decoder's thread pool.
  final int cpuCores;

  /// Total physical RAM in megabytes, when the platform reports it.
  final int? totalRamMb;

  /// Threads handed to libavcodec for software decoding.
  ///
  /// mpv's own default is "auto", which resolves to roughly one thread per
  /// core but varies per codec; a low-end box has 2-4 slow cores, so using all
  /// of them is what keeps a 1080p fallback above real time. Capped at
  /// [maxSoftwareDecodeThreads] because past a handful of threads the decoder
  /// spends more time synchronising than decoding on these SoCs.
  int get softwareDecodeThreads => cpuCores.clamp(minSoftwareDecodeThreads, maxSoftwareDecodeThreads);

  /// Lower bound of [softwareDecodeThreads].
  static const int minSoftwareDecodeThreads = 2;

  /// Upper bound of [softwareDecodeThreads].
  static const int maxSoftwareDecodeThreads = 6;

  static DevicePlaybackProfile? _cached;

  /// The last probe result, or [unknown] when [ensureLoaded] has not run.
  static DevicePlaybackProfile get current => _cached ?? unknown;

  /// Probes the device once and caches the answer.
  ///
  /// Called from adapter initialization. Every platform plugin failure
  /// resolves to [unknown] so a probe problem can never block playback.
  static Future<DevicePlaybackProfile> ensureLoaded() async {
    final DevicePlaybackProfile? cached = _cached;
    if (cached != null) return cached;

    final int cores = _cpuCores();
    final DevicePlaybackProfile profile = defaultTargetPlatform == TargetPlatform.android
        ? await _probeAndroid(cores)
        : DevicePlaybackProfile(lowEnd: cores <= 2, cpuCores: cores);
    _cached = profile;
    return profile;
  }

  /// Applies the low-end rule to one Android hardware report.
  ///
  /// Split out from the plugin call so the rule itself is unit-testable.
  @visibleForTesting
  static DevicePlaybackProfile fromAndroidReport({
    required bool isLowRamDevice,
    required int physicalRamSizeMb,
    required int cpuCores,
  }) {
    final bool ramKnown = physicalRamSizeMb > 0;
    return DevicePlaybackProfile(
      lowEnd: isLowRamDevice || (ramKnown && physicalRamSizeMb <= lowRamThresholdMb),
      cpuCores: cpuCores,
      totalRamMb: ramKnown ? physicalRamSizeMb : null,
    );
  }

  /// Overrides the cached profile; tests only.
  @visibleForTesting
  static void debugSetProfile(DevicePlaybackProfile? profile) => _cached = profile;

  static Future<DevicePlaybackProfile> _probeAndroid(int cores) async {
    try {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      return fromAndroidReport(
        isLowRamDevice: info.isLowRamDevice,
        physicalRamSizeMb: info.physicalRamSize,
        cpuCores: cores,
      );
    } catch (_) {
      // A missing platform channel (tests, a stripped build) must not turn
      // into a tuned-down device.
      return DevicePlaybackProfile(lowEnd: cores <= 2, cpuCores: cores);
    }
  }

  static int _cpuCores() {
    try {
      return Platform.numberOfProcessors;
    } catch (_) {
      return unknown.cpuCores;
    }
  }
}
