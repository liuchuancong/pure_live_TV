// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exit_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExitSettingsController)
final exitSettingsControllerProvider = ExitSettingsControllerProvider._();

final class ExitSettingsControllerProvider
    extends $NotifierProvider<ExitSettingsController, ExitSettingsModel> {
  ExitSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exitSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exitSettingsControllerHash();

  @$internal
  @override
  ExitSettingsController create() => ExitSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExitSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExitSettingsModel>(value),
    );
  }
}

String _$exitSettingsControllerHash() =>
    r'94a3274c239c57412c9a5cabc04aa972fa35dee5';

abstract class _$ExitSettingsController extends $Notifier<ExitSettingsModel> {
  ExitSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExitSettingsModel, ExitSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExitSettingsModel, ExitSettingsModel>,
              ExitSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
