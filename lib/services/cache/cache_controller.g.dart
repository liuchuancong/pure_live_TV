// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步自 pure_live CacheController：缓存分区扫描/清理/缩略图刷新。

@ProviderFor(CacheController)
final cacheControllerProvider = CacheControllerProvider._();

/// 同步自 pure_live CacheController：缓存分区扫描/清理/缩略图刷新。
final class CacheControllerProvider
    extends $NotifierProvider<CacheController, CacheModel> {
  /// 同步自 pure_live CacheController：缓存分区扫描/清理/缩略图刷新。
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

String _$cacheControllerHash() => r'f34e6802c77db5a37616bd1e4957933a111dbb9c';

/// 同步自 pure_live CacheController：缓存分区扫描/清理/缩略图刷新。

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
