// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CookieController)
final cookieControllerProvider = CookieControllerProvider._();

final class CookieControllerProvider
    extends $NotifierProvider<CookieController, CookieModel> {
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

String _$cookieControllerHash() => r'69afd8178228a2f94921b56cd036e65a4a8fe579';

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
