// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iptv_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IptvSettingsController)
final iptvSettingsControllerProvider = IptvSettingsControllerProvider._();

final class IptvSettingsControllerProvider
    extends $NotifierProvider<IptvSettingsController, IptvSettingsModel> {
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
    r'cd6e0d7c87468e33a8484990fdebb3bbb2765d84';

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
