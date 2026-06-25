// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_areas_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteAreasNotifier)
final favoriteAreasProvider = FavoriteAreasNotifierProvider._();

final class FavoriteAreasNotifierProvider
    extends $NotifierProvider<FavoriteAreasNotifier, FavoriteAreasState> {
  FavoriteAreasNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteAreasProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteAreasNotifierHash();

  @$internal
  @override
  FavoriteAreasNotifier create() => FavoriteAreasNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteAreasState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteAreasState>(value),
    );
  }
}

String _$favoriteAreasNotifierHash() =>
    r'bb48ece4c8dfc84af3177c13f54dca197db8c84c';

abstract class _$FavoriteAreasNotifier extends $Notifier<FavoriteAreasState> {
  FavoriteAreasState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FavoriteAreasState, FavoriteAreasState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoriteAreasState, FavoriteAreasState>,
              FavoriteAreasState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
