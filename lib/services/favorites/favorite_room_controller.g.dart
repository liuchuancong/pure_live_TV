// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Favorites, blocked words, blocked danmaku users and directory migration,
/// with identity-based de-duplication.

@ProviderFor(FavoriteRoomController)
final favoriteRoomControllerProvider = FavoriteRoomControllerProvider._();

/// Favorites, blocked words, blocked danmaku users and directory migration,
/// with identity-based de-duplication.
final class FavoriteRoomControllerProvider
    extends $NotifierProvider<FavoriteRoomController, FavoriteSettingsModel> {
  /// Favorites, blocked words, blocked danmaku users and directory migration,
  /// with identity-based de-duplication.
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
    r'254890ceb674431348b2c25598d146fb1ff4adb5';

/// Favorites, blocked words, blocked danmaku users and directory migration,
/// with identity-based de-duplication.

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
