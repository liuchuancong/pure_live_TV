// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TvThemeController)
final tvThemeControllerProvider = TvThemeControllerProvider._();

final class TvThemeControllerProvider
    extends $NotifierProvider<TvThemeController, TvThemeData> {
  TvThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvThemeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvThemeControllerHash();

  @$internal
  @override
  TvThemeController create() => TvThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TvThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TvThemeData>(value),
    );
  }
}

String _$tvThemeControllerHash() => r'5578e2d0e7b7dfc2635d9c23fda30b0c2ac0feca';

abstract class _$TvThemeController extends $Notifier<TvThemeData> {
  TvThemeData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TvThemeData, TvThemeData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TvThemeData, TvThemeData>,
              TvThemeData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
