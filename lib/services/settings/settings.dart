import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/startUp/startup_controller.dart';
import 'package:pure_live/models/background/back_ground_config.dart';
import 'package:pure_live/services/background/background_controller.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get to => _instance;
  SettingsService._internal();

  late final ProviderContainer _container;

  void init(ProviderContainer container) {
    _container = container;
  }

  BackgroundConfigModel get bgState => _container.read(backgroundControllerProvider);
  BackgroundController get bg => _container.read(backgroundControllerProvider.notifier);
  bool get isFirstInApp => _container.read(startupControllerProvider);
  StartupController get startup => _container.read(startupControllerProvider.notifier);
  dynamic get app => throw UnimplementedError('等待重构为Riverpod');
  dynamic get exit => throw UnimplementedError('等待重构为Riverpod');
  dynamic get player => throw UnimplementedError('等待重构为Riverpod');
  dynamic get danmaku => throw UnimplementedError('等待重构为Riverpod');
  dynamic get font => throw UnimplementedError('等待重构为Riverpod');
  dynamic get window => throw UnimplementedError('等待重构为Riverpod');
  dynamic get fav => throw UnimplementedError('等待重构为Riverpod');
  dynamic get history => throw UnimplementedError('等待重构为Riverpod');
  dynamic get cache => throw UnimplementedError('等待重构为Riverpod');
  dynamic get cookieManager => throw UnimplementedError('等待重构为Riverpod');
  dynamic get webdav => throw UnimplementedError('等待重构为Riverpod');
  dynamic get iptv => throw UnimplementedError('等待重构为Riverpod');
  dynamic get vol => throw UnimplementedError('等待重构为Riverpod');
  dynamic get theme => throw UnimplementedError('等待重构为Riverpod');
  dynamic get proxy => throw UnimplementedError('等待重构为Riverpod');
  dynamic get backup => throw UnimplementedError('等待重构为Riverpod');
  dynamic get refreshConfig => throw UnimplementedError('等待重构为Riverpod');
  dynamic get page => throw UnimplementedError('等待重构为Riverpod');
  dynamic get log => throw UnimplementedError('等待重构为Riverpod');
  dynamic get tagManagement => throw UnimplementedError('等待重构为Riverpod');
  dynamic get tvTheme => throw UnimplementedError('等待重构为Riverpod');
}
