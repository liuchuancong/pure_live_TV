// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeSettingsController)
final themeSettingsControllerProvider = ThemeSettingsControllerProvider._();

final class ThemeSettingsControllerProvider
    extends $NotifierProvider<ThemeSettingsController, ThemeSettingsModel> {
  ThemeSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSettingsControllerHash();

  @$internal
  @override
  ThemeSettingsController create() => ThemeSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeSettingsModel>(value),
    );
  }
}

String _$themeSettingsControllerHash() =>
    r'3654240a8f367eb93f0b1927b759cfbf4733e1ab';

abstract class _$ThemeSettingsController extends $Notifier<ThemeSettingsModel> {
  ThemeSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeSettingsModel, ThemeSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeSettingsModel, ThemeSettingsModel>,
              ThemeSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
