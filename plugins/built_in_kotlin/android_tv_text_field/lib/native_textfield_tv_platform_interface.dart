import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_textfield_tv_method_channel.dart';

abstract class NativeTextfieldTvPlatform extends PlatformInterface {
  /// Constructs a NativeTextfieldTvPlatform.
  NativeTextfieldTvPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeTextfieldTvPlatform _instance = MethodChannelNativeTextfieldTv();

  /// The default instance of [NativeTextfieldTvPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeTextfieldTv].
  static NativeTextfieldTvPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeTextfieldTvPlatform] when
  /// they register themselves.
  static set instance(NativeTextfieldTvPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
