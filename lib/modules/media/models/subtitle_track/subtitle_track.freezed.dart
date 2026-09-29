// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleTrack {

 String get lan;@JsonKey(name: 'lan_doc') String get lanDoc;@JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) String get url;
/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<SubtitleTrack> get copyWith => _$SubtitleTrackCopyWithImpl<SubtitleTrack>(this as SubtitleTrack, _$identity);

  /// Serializes this SubtitleTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrack&&(identical(other.lan, _this.lan) || other.lan == _this.lan)&&(identical(other.lanDoc, _this.lanDoc) || other.lanDoc == _this.lanDoc)&&(identical(other.url, _this.url) || other.url == _this.url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleTrack;
  return Object.hash(runtimeType,_this.lan,_this.lanDoc,_this.url);
}

@override
String toString() {
  final _this = this as SubtitleTrack;
  return 'SubtitleTrack(lan: ${_this.lan}, lanDoc: ${_this.lanDoc}, url: ${_this.url})';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackCopyWith<$Res>  {
  factory $SubtitleTrackCopyWith(SubtitleTrack value, $Res Function(SubtitleTrack) _then) = _$SubtitleTrackCopyWithImpl;
@useResult
$Res call({
 String lan,@JsonKey(name: 'lan_doc') String lanDoc,@JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) String url
});




}
/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._self, this._then);

  final SubtitleTrack _self;
  final $Res Function(SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lan = null,Object? lanDoc = null,Object? url = null,}) {
  return _then(SubtitleTrack(
lan: null == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String,lanDoc: null == lanDoc ? _self.lanDoc : lanDoc // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrack].
extension SubtitleTrackPatterns on SubtitleTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrack value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrack value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc, @JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf)  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.lan,_that.lanDoc,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc, @JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf)  String url)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack():
return $default(_that.lan,_that.lanDoc,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lan, @JsonKey(name: 'lan_doc')  String lanDoc, @JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf)  String url)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.lan,_that.lanDoc,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleTrack implements SubtitleTrack {
  const _SubtitleTrack({this.lan = '', @JsonKey(name: 'lan_doc') this.lanDoc = '', @JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) this.url = ''});
  factory _SubtitleTrack.fromJson(Map<String, dynamic> json) => _$SubtitleTrackFromJson(json);

@override@JsonKey() final  String lan;
@override@JsonKey(name: 'lan_doc') final  String lanDoc;
@override@JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) final  String url;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackCopyWith<_SubtitleTrack> get copyWith => __$SubtitleTrackCopyWithImpl<_SubtitleTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleTrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrack&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.lanDoc, lanDoc) || other.lanDoc == lanDoc)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lan,lanDoc,url);
}

@override
String toString() {
    return 'SubtitleTrack(lan: $lan, lanDoc: $lanDoc, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackCopyWith<$Res> implements $SubtitleTrackCopyWith<$Res> {
  factory _$SubtitleTrackCopyWith(_SubtitleTrack value, $Res Function(_SubtitleTrack) _then) = __$SubtitleTrackCopyWithImpl;
@override @useResult
$Res call({
 String lan,@JsonKey(name: 'lan_doc') String lanDoc,@JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) String url
});




}
/// @nodoc
class __$SubtitleTrackCopyWithImpl<$Res>
    implements _$SubtitleTrackCopyWith<$Res> {
  __$SubtitleTrackCopyWithImpl(this._self, this._then);

  final _SubtitleTrack _self;
  final $Res Function(_SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lan = null,Object? lanDoc = null,Object? url = null,}) {
  return _then(_SubtitleTrack(
lan: null == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String,lanDoc: null == lanDoc ? _self.lanDoc : lanDoc // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
