// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iptv_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步自 pure_live IptvSettingsController：IPTV 源选择与自动同步配置。

@ProviderFor(IptvSettingsController)
final iptvSettingsControllerProvider = IptvSettingsControllerProvider._();

/// 同步自 pure_live IptvSettingsController：IPTV 源选择与自动同步配置。
final class IptvSettingsControllerProvider
    extends $NotifierProvider<IptvSettingsController, IptvSettingsModel> {
  /// 同步自 pure_live IptvSettingsController：IPTV 源选择与自动同步配置。
  IptvSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iptvSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iptvSettingsControllerHash();

  @$internal
  @override
  IptvSettingsController create() => IptvSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IptvSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IptvSettingsModel>(value),
    );
  }
}

String _$iptvSettingsControllerHash() =>
    r'b9e743b83d759f6f565c9a20a0ce52587ed5df10';

/// 同步自 pure_live IptvSettingsController：IPTV 源选择与自动同步配置。

abstract class _$IptvSettingsController extends $Notifier<IptvSettingsModel> {
  IptvSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<IptvSettingsModel, IptvSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IptvSettingsModel, IptvSettingsModel>,
              IptvSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
