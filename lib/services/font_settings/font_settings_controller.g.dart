// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FontSettingsController)
final fontSettingsControllerProvider = FontSettingsControllerProvider._();

final class FontSettingsControllerProvider
    extends $AsyncNotifierProvider<FontSettingsController, FontSettingsModel> {
  FontSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontSettingsControllerHash();

  @$internal
  @override
  FontSettingsController create() => FontSettingsController();
}

String _$fontSettingsControllerHash() =>
    r'f9fb22a8aaa1c36ede27a044ee06b3f72a43d44c';

abstract class _$FontSettingsController
    extends $AsyncNotifier<FontSettingsModel> {
  FutureOr<FontSettingsModel> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<FontSettingsModel>, FontSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FontSettingsModel>, FontSettingsModel>,
              AsyncValue<FontSettingsModel>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
