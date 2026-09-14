// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VolumeSettingsController)
final volumeSettingsControllerProvider = VolumeSettingsControllerProvider._();

final class VolumeSettingsControllerProvider
    extends $NotifierProvider<VolumeSettingsController, VolumeSettingsModel> {
  VolumeSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'volumeSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$volumeSettingsControllerHash();

  @$internal
  @override
  VolumeSettingsController create() => VolumeSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VolumeSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VolumeSettingsModel>(value),
    );
  }
}

String _$volumeSettingsControllerHash() =>
    r'dd593259eb50b5e532f96bee0ffb51bdd2e4515b';

abstract class _$VolumeSettingsController
    extends $Notifier<VolumeSettingsModel> {
  VolumeSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VolumeSettingsModel, VolumeSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VolumeSettingsModel, VolumeSettingsModel>,
              VolumeSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
