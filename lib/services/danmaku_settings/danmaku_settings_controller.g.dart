// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DanmakuSettingsController)
final danmakuSettingsControllerProvider = DanmakuSettingsControllerProvider._();

final class DanmakuSettingsControllerProvider
    extends $NotifierProvider<DanmakuSettingsController, DanmakuSettingsModel> {
  DanmakuSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'danmakuSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$danmakuSettingsControllerHash();

  @$internal
  @override
  DanmakuSettingsController create() => DanmakuSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DanmakuSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DanmakuSettingsModel>(value),
    );
  }
}

String _$danmakuSettingsControllerHash() =>
    r'6487a21891f508b7caef27d6e24affd47aea305a';

abstract class _$DanmakuSettingsController
    extends $Notifier<DanmakuSettingsModel> {
  DanmakuSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DanmakuSettingsModel, DanmakuSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DanmakuSettingsModel, DanmakuSettingsModel>,
              DanmakuSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
