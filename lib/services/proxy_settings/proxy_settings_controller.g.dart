// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProxySettingsController)
final proxySettingsControllerProvider = ProxySettingsControllerProvider._();

final class ProxySettingsControllerProvider
    extends $NotifierProvider<ProxySettingsController, ProxySettingsModel> {
  ProxySettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proxySettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proxySettingsControllerHash();

  @$internal
  @override
  ProxySettingsController create() => ProxySettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProxySettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProxySettingsModel>(value),
    );
  }
}

String _$proxySettingsControllerHash() =>
    r'a836a26f23e4e08193b6d0cee3b39159fed58c5d';

abstract class _$ProxySettingsController extends $Notifier<ProxySettingsModel> {
  ProxySettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProxySettingsModel, ProxySettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProxySettingsModel, ProxySettingsModel>,
              ProxySettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
