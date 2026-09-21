import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_textfield_tv_platform_interface.dart';

/// An implementation of [NativeTextfieldTvPlatform] that uses method channels.
class MethodChannelNativeTextfieldTv extends NativeTextfieldTvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_textfield_tv');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
