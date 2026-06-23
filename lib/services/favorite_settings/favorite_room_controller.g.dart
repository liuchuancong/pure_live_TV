// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FavoriteRoomController)
final favoriteRoomControllerProvider = FavoriteRoomControllerProvider._();

final class FavoriteRoomControllerProvider
    extends $NotifierProvider<FavoriteRoomController, FavoriteSettingsModel> {
  FavoriteRoomControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRoomControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRoomControllerHash();

  @$internal
  @override
  FavoriteRoomController create() => FavoriteRoomController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteSettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteSettingsModel>(value),
    );
  }
}

String _$favoriteRoomControllerHash() =>
    r'a19fb373fc95a292a4a69b134dcfd34002187008';

abstract class _$FavoriteRoomController
    extends $Notifier<FavoriteSettingsModel> {
  FavoriteSettingsModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FavoriteSettingsModel, FavoriteSettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoriteSettingsModel, FavoriteSettingsModel>,
              FavoriteSettingsModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
