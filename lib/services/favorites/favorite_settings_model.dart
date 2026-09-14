import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/exports/common_export.dart';

part 'favorite_settings_model.freezed.dart';
part 'favorite_settings_model.g.dart';

@freezed
abstract class FavoriteSettingsModel with _$FavoriteSettingsModel {
  const factory FavoriteSettingsModel({
    @Default([]) List<String> shieldList,
    @Default([]) List<String> blockedDanmakuUsers,
    @Default(0) int siteCatalogMigration,
    @Default([]) List<String> hotAreasList,
    @Default('') String preferPlatform,
    @Default([]) List<LiveRoom> favoriteRooms,
    @Default([]) List<LiveArea> favoriteAreas,
  }) = _FavoriteSettingsModel;

  factory FavoriteSettingsModel.fromJson(Map<String, dynamic> json) => _$FavoriteSettingsModelFromJson(json);
}
