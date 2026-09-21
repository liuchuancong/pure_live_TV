import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/player/utils/device_playback_profile.dart';
import 'package:pure_live/player/utils/live_buffer_policy.dart';

/// 低配设备的解码预算：盒子的内存与核心数决定 mpv 能花多少解码成本。
///
/// 这里锁住两条规则。第一，只有 Android 自己报告内存不足（`isLowRamDevice`）或总内存
/// ≤2GB 才降级，内存读不到时绝不降级——探测失败不能让一台好设备被悄悄调低画质。
/// 第二，缓冲区只有**字节上限**随设备收紧；时间维度的余量（`demuxer-readahead-secs`、
/// `cache-secs`、`cache-pause-wait`）在所有设备上完全一致，因为当初修好卡顿的正是那
/// 几个值，低配设备不能把它们一起改小。
void main() {
  group('low-end detection', () {
    test('an Android low-RAM flag is enough on its own', () {
      final DevicePlaybackProfile profile = DevicePlaybackProfile.fromAndroidReport(
        isLowRamDevice: true,
        physicalRamSizeMb: 8192,
        cpuCores: 8,
      );

      expect(profile.lowEnd, isTrue);
    });

    test('2 GB or less counts as low-end', () {
      expect(
        DevicePlaybackProfile.fromAndroidReport(
          isLowRamDevice: false,
          physicalRamSizeMb: DevicePlaybackProfile.lowRamThresholdMb,
          cpuCores: 4,
        ).lowEnd,
        isTrue,
      );
      expect(
        DevicePlaybackProfile.fromAndroidReport(isLowRamDevice: false, physicalRamSizeMb: 1024, cpuCores: 4).lowEnd,
        isTrue,
      );
    });

    test('more than 2 GB is never downgraded by the RAM rule', () {
      expect(
        DevicePlaybackProfile.fromAndroidReport(isLowRamDevice: false, physicalRamSizeMb: 4096, cpuCores: 4).lowEnd,
        isFalse,
      );
    });

    test('an unreadable RAM figure never downgrades a device', () {
      final DevicePlaybackProfile profile = DevicePlaybackProfile.fromAndroidReport(
        isLowRamDevice: false,
        physicalRamSizeMb: 0,
        cpuCores: 2,
      );

      expect(profile.lowEnd, isFalse);
      expect(profile.totalRamMb, isNull);
    });

    test('decode threads stay inside the codec-friendly range', () {
      expect(const DevicePlaybackProfile(lowEnd: true, cpuCores: 1).softwareDecodeThreads, 2);
      expect(const DevicePlaybackProfile(lowEnd: true, cpuCores: 4).softwareDecodeThreads, 4);
      expect(const DevicePlaybackProfile(lowEnd: true, cpuCores: 16).softwareDecodeThreads, 6);
    });
  });

  group('buffer budget', () {
    const DevicePlaybackProfile lowEnd = DevicePlaybackProfile(lowEnd: true, cpuCores: 4);
    const DevicePlaybackProfile capable = DevicePlaybackProfile(lowEnd: false, cpuCores: 8);

    test('a low-RAM device gets the smaller byte ceiling', () {
      expect(LiveBufferPolicy.forwardBytesFor(lowEnd), LiveBufferPolicy.lowEndForwardBytes);
      expect(LiveBufferPolicy.backBytesFor(lowEnd), LiveBufferPolicy.lowEndBackBytes);
      expect(LiveBufferPolicy.forwardBytesFor(lowEnd), lessThan(LiveBufferPolicy.forwardBytes));
      expect(LiveBufferPolicy.backBytesFor(lowEnd), lessThan(LiveBufferPolicy.backBytes));
    });

    test('a capable device, and an unknown one, keep the tuned default', () {
      expect(LiveBufferPolicy.forwardBytesFor(capable), LiveBufferPolicy.forwardBytes);
      expect(LiveBufferPolicy.backBytesFor(capable), LiveBufferPolicy.backBytes);
      expect(LiveBufferPolicy.forwardBytesFor(null), LiveBufferPolicy.forwardBytes);
      expect(LiveBufferPolicy.backBytesFor(null), LiveBufferPolicy.backBytes);
    });

    test('the time-based headroom is identical on every device', () async {
      Future<Map<String, String>> collect(DevicePlaybackProfile? profile) async {
        final Map<String, String> values = <String, String>{};
        await LiveBufferPolicy.apply((String name, String value) async {
          values[name] = value;
        }, profile: profile);
        return values;
      }

      final Map<String, String> low = await collect(lowEnd);
      final Map<String, String> high = await collect(capable);

      for (final String key in const <String>[
        'cache',
        'cache-on-disk',
        'cache-secs',
        'demuxer-readahead-secs',
        'demuxer-donate-buffer',
        'cache-pause',
        'cache-pause-wait',
        'demuxer-thread',
        'framedrop',
      ]) {
        expect(low[key], high[key], reason: key);
      }
      expect(low['demuxer-max-bytes'], LiveBufferPolicy.lowEndForwardBytes.toString());
      expect(high['demuxer-max-bytes'], LiveBufferPolicy.forwardBytes.toString());
    });
  });

  group('probe', () {
    test('never throws and caches its answer', () async {
      DevicePlaybackProfile.debugSetProfile(null);
      addTearDown(() => DevicePlaybackProfile.debugSetProfile(null));

      final DevicePlaybackProfile first = await DevicePlaybackProfile.ensureLoaded();
      final DevicePlaybackProfile second = await DevicePlaybackProfile.ensureLoaded();

      // A plugin-less test host must not turn into a failure: the platform
      // channel throws and the probe falls back to the conservative profile.
      expect(identical(first, second), isTrue);
      expect(DevicePlaybackProfile.current, same(first));
    });
  });
}
