// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PageSettingsController)
final pageSettingsControllerProvider = PageSettingsControllerProvider._();

final class PageSettingsControllerProvider
    extends $NotifierProvider<PageSettingsController, PageSettingsModel> {
  PageSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageSettingsControllerHash();

  @$internal
  @override
  PageSettingsController create() => PageSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageSettingsModel>(value),
    );
  }
}

String _$pageSettingsControllerHash() =>
    r'3cf29b6b3807603356c24289f5a2d344b24127e9';

abstract class _$PageSettingsController extends $Notifier<PageSettingsModel> {
  PageSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PageSettingsModel, PageSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PageSettingsModel, PageSettingsModel>,
              PageSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
