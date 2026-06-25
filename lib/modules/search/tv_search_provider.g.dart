// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TvSearchNotifier)
final tvSearchNotifierProvider = TvSearchNotifierProvider._();

final class TvSearchNotifierProvider
    extends $NotifierProvider<TvSearchNotifier, TvSearchState> {
  TvSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tvSearchNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tvSearchNotifierHash();

  @$internal
  @override
  TvSearchNotifier create() => TvSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TvSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TvSearchState>(value),
    );
  }
}

String _$tvSearchNotifierHash() => r'6751f60e2133cf0a503dbace2d70f48e8906ca8d';

abstract class _$TvSearchNotifier extends $Notifier<TvSearchState> {
  TvSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TvSearchState, TvSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TvSearchState, TvSearchState>,
              TvSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
