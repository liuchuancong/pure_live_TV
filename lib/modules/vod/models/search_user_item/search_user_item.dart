import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'search_user_item.freezed.dart';
part 'search_user_item.g.dart';

/// One search result of type `user` / `bili_user`.
@freezed
abstract class SearchUserItem with _$SearchUserItem {
  const factory SearchUserItem({
    @JsonKey(fromJson: lenientIntOf) @Default(0) int mid,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String uname,

    /// The WBI search row names the avatar `upic`; the relation shape says
    /// `face` — accept either.
    @JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) @Default('') String face,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String sign,
    @JsonKey(fromJson: lenientIntOf) @Default(0) int fans,
    @JsonKey(name: 'videos', fromJson: lenientIntOf) @Default(0) int videoCount,
  }) = _SearchUserItem;

  factory SearchUserItem.fromJson(Map<String, dynamic> json) => _$SearchUserItemFromJson(json);
}

dynamic _readUpicOrFace(Map<dynamic, dynamic> json, String key) => json['upic'] ?? json['face'];
