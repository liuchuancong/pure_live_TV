// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteNotifier)
final favoriteProvider = FavoriteNotifierProvider._();

final class FavoriteNotifierProvider
    extends $NotifierProvider<FavoriteNotifier, FavoriteState> {
  FavoriteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteNotifierHash();

  @$internal
  @override
  FavoriteNotifier create() => FavoriteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteState>(value),
    );
  }
}

String _$favoriteNotifierHash() => r'5f3812c1b70b4ea7ab612b6c749c913d8ec8cc5d';

abstract class _$FavoriteNotifier extends $Notifier<FavoriteState> {
  FavoriteState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FavoriteState, FavoriteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoriteState, FavoriteState>,
              FavoriteState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
