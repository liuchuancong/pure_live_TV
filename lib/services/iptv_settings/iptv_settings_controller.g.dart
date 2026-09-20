// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iptv_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// IPTV auto-sync configuration.

@ProviderFor(IptvSettingsController)
final iptvSettingsControllerProvider = IptvSettingsControllerProvider._();

/// IPTV auto-sync configuration.
final class IptvSettingsControllerProvider
    extends $NotifierProvider<IptvSettingsController, IptvSettingsModel> {
  /// IPTV auto-sync configuration.
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
    r'31020696dfcb1a149283d67872bb692af1f61ba7';

/// IPTV auto-sync configuration.

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
