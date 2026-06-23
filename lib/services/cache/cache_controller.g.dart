// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CacheController)
final cacheControllerProvider = CacheControllerProvider._();

final class CacheControllerProvider
    extends $NotifierProvider<CacheController, CacheModel> {
  CacheControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheControllerHash();

  @$internal
  @override
  CacheController create() => CacheController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheModel>(value),
    );
  }
}

String _$cacheControllerHash() => r'6a784194b9d765d707e6950221d9628fdd0f3b1b';

abstract class _$CacheController extends $Notifier<CacheModel> {
  CacheModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CacheModel, CacheModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CacheModel, CacheModel>,
              CacheModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
