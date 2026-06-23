import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';

part 'favorite_settings_model.freezed.dart';
part 'favorite_settings_model.g.dart';

@freezed
abstract class FavoriteSettingsModel with _$FavoriteSettingsModel {
  const factory FavoriteSettingsModel({
    @Default([]) List<String> shieldList,
    @Default([]) List<String> hotAreasList,
    @Default('') String preferPlatform,
    @Default([]) List<LiveRoom> favoriteRooms,
    @Default([]) List<LiveArea> favoriteAreas,
  }) = _FavoriteSettingsModel;

  factory FavoriteSettingsModel.fromJson(Map<String, dynamic> json) => _$FavoriteSettingsModelFromJson(json);
}
