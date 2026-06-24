// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LogSettingsController)
final logSettingsControllerProvider = LogSettingsControllerProvider._();

final class LogSettingsControllerProvider
    extends $NotifierProvider<LogSettingsController, LogSettingsModel> {
  LogSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logSettingsControllerHash();

  @$internal
  @override
  LogSettingsController create() => LogSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogSettingsModel>(value),
    );
  }
}

String _$logSettingsControllerHash() =>
    r'3827fd205a5c778ca9f85ba904c04330177a2945';

abstract class _$LogSettingsController extends $Notifier<LogSettingsModel> {
  LogSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LogSettingsModel, LogSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LogSettingsModel, LogSettingsModel>,
              LogSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
