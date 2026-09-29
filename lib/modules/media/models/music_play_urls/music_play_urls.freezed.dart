// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_play_urls.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicPlayUrls {

/// The stream to hand the player as the primary source. For DASH this is
/// the video-only m4s (the audio rides along through the player's
/// audio-file input); for the mp4 fallback it is the muxed file.
 String get videoUrl;/// The DASH audio m4s. Null for the muxed mp4 fallback (and for
/// audio-only playback the audio URL itself becomes the primary source).
 String? get audioUrl; List<String> get videoBackupUrls;/// The quality id actually served.
 int get quality; bool get isDash;/// Every quality the current answer can serve, AVC-preferred per tier.
 List<MusicStreamOption> get videoOptions;
/// Create a copy of MusicPlayUrls
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicPlayUrlsCopyWith<MusicPlayUrls> get copyWith => _$MusicPlayUrlsCopyWithImpl<MusicPlayUrls>(this as MusicPlayUrls, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MusicPlayUrls;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicPlayUrls&&(identical(other.videoUrl, _this.videoUrl) || other.videoUrl == _this.videoUrl)&&(identical(other.audioUrl, _this.audioUrl) || other.audioUrl == _this.audioUrl)&&const DeepCollectionEquality().equals(other.videoBackupUrls, _this.videoBackupUrls)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.isDash, _this.isDash) || other.isDash == _this.isDash)&&const DeepCollectionEquality().equals(other.videoOptions, _this.videoOptions));
}


@override
int get hashCode {
  final _this = this as MusicPlayUrls;
  return Object.hash(runtimeType,_this.videoUrl,_this.audioUrl,const DeepCollectionEquality().hash(_this.videoBackupUrls),_this.quality,_this.isDash,const DeepCollectionEquality().hash(_this.videoOptions));
}

@override
String toString() {
  final _this = this as MusicPlayUrls;
  return 'MusicPlayUrls(videoUrl: ${_this.videoUrl}, audioUrl: ${_this.audioUrl}, videoBackupUrls: ${_this.videoBackupUrls}, quality: ${_this.quality}, isDash: ${_this.isDash}, videoOptions: ${_this.videoOptions})';
}


}

/// @nodoc
abstract mixin class $MusicPlayUrlsCopyWith<$Res>  {
  factory $MusicPlayUrlsCopyWith(MusicPlayUrls value, $Res Function(MusicPlayUrls) _then) = _$MusicPlayUrlsCopyWithImpl;
@useResult
$Res call({
 String videoUrl, String? audioUrl, List<String> videoBackupUrls, int quality, bool isDash, List<MusicStreamOption> videoOptions
});




}
/// @nodoc
class _$MusicPlayUrlsCopyWithImpl<$Res>
    implements $MusicPlayUrlsCopyWith<$Res> {
  _$MusicPlayUrlsCopyWithImpl(this._self, this._then);

  final MusicPlayUrls _self;
  final $Res Function(MusicPlayUrls) _then;

/// Create a copy of MusicPlayUrls
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoUrl = null,Object? audioUrl = freezed,Object? videoBackupUrls = null,Object? quality = null,Object? isDash = null,Object? videoOptions = null,}) {
  return _then(MusicPlayUrls(
videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,videoBackupUrls: null == videoBackupUrls ? _self.videoBackupUrls : videoBackupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,isDash: null == isDash ? _self.isDash : isDash // ignore: cast_nullable_to_non_nullable
as bool,videoOptions: null == videoOptions ? _self.videoOptions : videoOptions // ignore: cast_nullable_to_non_nullable
as List<MusicStreamOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicPlayUrls].
extension MusicPlayUrlsPatterns on MusicPlayUrls {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicPlayUrls value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicPlayUrls() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicPlayUrls value)  $default,){
final _that = this;
switch (_that) {
case _MusicPlayUrls():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicPlayUrls value)?  $default,){
final _that = this;
switch (_that) {
case _MusicPlayUrls() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String videoUrl,  String? audioUrl,  List<String> videoBackupUrls,  int quality,  bool isDash,  List<MusicStreamOption> videoOptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicPlayUrls() when $default != null:
return $default(_that.videoUrl,_that.audioUrl,_that.videoBackupUrls,_that.quality,_that.isDash,_that.videoOptions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String videoUrl,  String? audioUrl,  List<String> videoBackupUrls,  int quality,  bool isDash,  List<MusicStreamOption> videoOptions)  $default,) {final _that = this;
switch (_that) {
case _MusicPlayUrls():
return $default(_that.videoUrl,_that.audioUrl,_that.videoBackupUrls,_that.quality,_that.isDash,_that.videoOptions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String videoUrl,  String? audioUrl,  List<String> videoBackupUrls,  int quality,  bool isDash,  List<MusicStreamOption> videoOptions)?  $default,) {final _that = this;
switch (_that) {
case _MusicPlayUrls() when $default != null:
return $default(_that.videoUrl,_that.audioUrl,_that.videoBackupUrls,_that.quality,_that.isDash,_that.videoOptions);case _:
  return null;

}
}

}

/// @nodoc


class _MusicPlayUrls implements MusicPlayUrls {
  const _MusicPlayUrls({required this.videoUrl, this.audioUrl,  List<String> videoBackupUrls = const [], this.quality = 0, this.isDash = true,  List<MusicStreamOption> videoOptions = const []}): _videoBackupUrls = videoBackupUrls,_videoOptions = videoOptions;
  

/// The stream to hand the player as the primary source. For DASH this is
/// the video-only m4s (the audio rides along through the player's
/// audio-file input); for the mp4 fallback it is the muxed file.
@override final  String videoUrl;
/// The DASH audio m4s. Null for the muxed mp4 fallback (and for
/// audio-only playback the audio URL itself becomes the primary source).
@override final  String? audioUrl;
 final  List<String> _videoBackupUrls;
@override@JsonKey() List<String> get videoBackupUrls {
  if (_videoBackupUrls is EqualUnmodifiableListView) return _videoBackupUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoBackupUrls);
}

/// The quality id actually served.
@override@JsonKey() final  int quality;
@override@JsonKey() final  bool isDash;
/// Every quality the current answer can serve, AVC-preferred per tier.
 final  List<MusicStreamOption> _videoOptions;
/// Every quality the current answer can serve, AVC-preferred per tier.
@override@JsonKey() List<MusicStreamOption> get videoOptions {
  if (_videoOptions is EqualUnmodifiableListView) return _videoOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoOptions);
}


/// Create a copy of MusicPlayUrls
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicPlayUrlsCopyWith<_MusicPlayUrls> get copyWith => __$MusicPlayUrlsCopyWithImpl<_MusicPlayUrls>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicPlayUrls&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&const DeepCollectionEquality().equals(other.videoBackupUrls, _videoBackupUrls)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.isDash, isDash) || other.isDash == isDash)&&const DeepCollectionEquality().equals(other.videoOptions, _videoOptions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,videoUrl,audioUrl,const DeepCollectionEquality().hash(_videoBackupUrls),quality,isDash,const DeepCollectionEquality().hash(_videoOptions));
}

@override
String toString() {
    return 'MusicPlayUrls(videoUrl: $videoUrl, audioUrl: $audioUrl, videoBackupUrls: $videoBackupUrls, quality: $quality, isDash: $isDash, videoOptions: $videoOptions)';
}


}

/// @nodoc
abstract mixin class _$MusicPlayUrlsCopyWith<$Res> implements $MusicPlayUrlsCopyWith<$Res> {
  factory _$MusicPlayUrlsCopyWith(_MusicPlayUrls value, $Res Function(_MusicPlayUrls) _then) = __$MusicPlayUrlsCopyWithImpl;
@override @useResult
$Res call({
 String videoUrl, String? audioUrl, List<String> videoBackupUrls, int quality, bool isDash, List<MusicStreamOption> videoOptions
});




}
/// @nodoc
class __$MusicPlayUrlsCopyWithImpl<$Res>
    implements _$MusicPlayUrlsCopyWith<$Res> {
  __$MusicPlayUrlsCopyWithImpl(this._self, this._then);

  final _MusicPlayUrls _self;
  final $Res Function(_MusicPlayUrls) _then;

/// Create a copy of MusicPlayUrls
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoUrl = null,Object? audioUrl = freezed,Object? videoBackupUrls = null,Object? quality = null,Object? isDash = null,Object? videoOptions = null,}) {
  return _then(_MusicPlayUrls(
videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,videoBackupUrls: null == videoBackupUrls ? _self._videoBackupUrls : videoBackupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,isDash: null == isDash ? _self.isDash : isDash // ignore: cast_nullable_to_non_nullable
as bool,videoOptions: null == videoOptions ? _self._videoOptions : videoOptions // ignore: cast_nullable_to_non_nullable
as List<MusicStreamOption>,
  ));
}


}

// dart format on
