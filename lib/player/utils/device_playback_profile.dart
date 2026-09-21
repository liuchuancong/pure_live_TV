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
/// when Android itself flags it ([AndroidDeviceInfo.isLowRamDevice]), its total
/// RAM is at most [lowRamThresholdMb], or its SoC has **no 64-bit ABI at all**.
/// An unreadable report never downgrades a device, so a failed probe leaves
/// playback exactly as it was.
///
/// The 32-bit rule exists because RAM alone misses the worst boxes: plenty of
/// arm32 Android TVs report 2 GB and therefore looked "capable", while their
/// Cortex-A7/A53-class SoC has to drop frames on a 1080p60 stream. A device
/// that advertises no 64-bit ABI is from that generation by definition.
@immutable
final class DevicePlaybackProfile {
  /// Creates a profile.
  const DevicePlaybackProfile({
    required this.lowEnd,
    required this.cpuCores,
    this.totalRamMb,
    this.is32BitOnly = false,
  });

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

  /// Whether the SoC itself has no 64-bit ABI (arm32-only box).
  ///
  /// Read from the *device* ({@code supported64BitAbis}), not from the running
  /// process: a 64-bit TV that happens to run our armeabi-v7a APK is fine and
  /// must keep the normal pipeline.
  final bool is32BitOnly;

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
    bool is32BitOnly = false,
  }) {
    final bool ramKnown = physicalRamSizeMb > 0;
    return DevicePlaybackProfile(
      lowEnd: isLowRamDevice || (ramKnown && physicalRamSizeMb <= lowRamThresholdMb) || is32BitOnly,
      cpuCores: cpuCores,
      totalRamMb: ramKnown ? physicalRamSizeMb : null,
      is32BitOnly: is32BitOnly,
    );
  }

  /// Whether one Android ABI report describes a 32-bit-only SoC.
  ///
  /// An empty [AndroidDeviceInfo.supported64BitAbis] means the *device* cannot
  /// run 64-bit code at all. An empty [AndroidDeviceInfo.supportedAbis] is a
  /// report we could not read, and must not downgrade anything.
  @visibleForTesting
  static bool isArm32OnlyDevice(AndroidDeviceInfo info) =>
      info.supportedAbis.isNotEmpty && info.supported64BitAbis.isEmpty;

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
        is32BitOnly: isArm32OnlyDevice(info),
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
