// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 同步自 pure_live FavoriteRoomController：
/// 收藏/屏蔽词/弹幕屏蔽用户/站点目录迁移与身份去重逻辑。

@ProviderFor(FavoriteRoomController)
final favoriteRoomControllerProvider = FavoriteRoomControllerProvider._();

/// 同步自 pure_live FavoriteRoomController：
/// 收藏/屏蔽词/弹幕屏蔽用户/站点目录迁移与身份去重逻辑。
final class FavoriteRoomControllerProvider
    extends $NotifierProvider<FavoriteRoomController, FavoriteSettingsModel> {
  /// 同步自 pure_live FavoriteRoomController：
  /// 收藏/屏蔽词/弹幕屏蔽用户/站点目录迁移与身份去重逻辑。
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
    r'c210fee23e89ba521a42e3840a47db159829f531';

/// 同步自 pure_live FavoriteRoomController：
/// 收藏/屏蔽词/弹幕屏蔽用户/站点目录迁移与身份去重逻辑。

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
