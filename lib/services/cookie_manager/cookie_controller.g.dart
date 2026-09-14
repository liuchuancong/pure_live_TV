// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Normalizes and validates per-platform cookie values.

@ProviderFor(CookieController)
final cookieControllerProvider = CookieControllerProvider._();

/// Normalizes and validates per-platform cookie values.
final class CookieControllerProvider
    extends $NotifierProvider<CookieController, CookieModel> {
  /// Normalizes and validates per-platform cookie values.
  CookieControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookieControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookieControllerHash();

  @$internal
  @override
  CookieController create() => CookieController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookieModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookieModel>(value),
    );
  }
}

String _$cookieControllerHash() => r'041b2f4f470b6540cd4bc3668135f66801708963';

/// Normalizes and validates per-platform cookie values.

abstract class _$CookieController extends $Notifier<CookieModel> {
  CookieModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CookieModel, CookieModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CookieModel, CookieModel>,
              CookieModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
