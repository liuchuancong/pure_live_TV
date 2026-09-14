// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppSettingsController)
final appSettingsControllerProvider = AppSettingsControllerProvider._();

final class AppSettingsControllerProvider
    extends $NotifierProvider<AppSettingsController, AppSettingsModel> {
  AppSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingsControllerHash();

  @$internal
  @override
  AppSettingsController create() => AppSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettingsModel>(value),
    );
  }
}

String _$appSettingsControllerHash() =>
    r'3c521b9c0a029dbc485fbb088af488ae1b620f98';

abstract class _$AppSettingsController extends $Notifier<AppSettingsModel> {
  AppSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppSettingsModel, AppSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettingsModel, AppSettingsModel>,
              AppSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
