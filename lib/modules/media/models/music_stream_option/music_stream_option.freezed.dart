// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_stream_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicStreamOption {

 int get quality; String get url; String get codecs; List<String> get backupUrls;
/// Create a copy of MusicStreamOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicStreamOptionCopyWith<MusicStreamOption> get copyWith => _$MusicStreamOptionCopyWithImpl<MusicStreamOption>(this as MusicStreamOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MusicStreamOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicStreamOption&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.codecs, _this.codecs) || other.codecs == _this.codecs)&&const DeepCollectionEquality().equals(other.backupUrls, _this.backupUrls));
}


@override
int get hashCode {
  final _this = this as MusicStreamOption;
  return Object.hash(runtimeType,_this.quality,_this.url,_this.codecs,const DeepCollectionEquality().hash(_this.backupUrls));
}

@override
String toString() {
  final _this = this as MusicStreamOption;
  return 'MusicStreamOption(quality: ${_this.quality}, url: ${_this.url}, codecs: ${_this.codecs}, backupUrls: ${_this.backupUrls})';
}


}

/// @nodoc
abstract mixin class $MusicStreamOptionCopyWith<$Res>  {
  factory $MusicStreamOptionCopyWith(MusicStreamOption value, $Res Function(MusicStreamOption) _then) = _$MusicStreamOptionCopyWithImpl;
@useResult
$Res call({
 int quality, String url, String codecs, List<String> backupUrls
});




}
/// @nodoc
class _$MusicStreamOptionCopyWithImpl<$Res>
    implements $MusicStreamOptionCopyWith<$Res> {
  _$MusicStreamOptionCopyWithImpl(this._self, this._then);

  final MusicStreamOption _self;
  final $Res Function(MusicStreamOption) _then;

/// Create a copy of MusicStreamOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quality = null,Object? url = null,Object? codecs = null,Object? backupUrls = null,}) {
  return _then(MusicStreamOption(
quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,codecs: null == codecs ? _self.codecs : codecs // ignore: cast_nullable_to_non_nullable
as String,backupUrls: null == backupUrls ? _self.backupUrls : backupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicStreamOption].
extension MusicStreamOptionPatterns on MusicStreamOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicStreamOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicStreamOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicStreamOption value)  $default,){
final _that = this;
switch (_that) {
case _MusicStreamOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicStreamOption value)?  $default,){
final _that = this;
switch (_that) {
case _MusicStreamOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int quality,  String url,  String codecs,  List<String> backupUrls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicStreamOption() when $default != null:
return $default(_that.quality,_that.url,_that.codecs,_that.backupUrls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int quality,  String url,  String codecs,  List<String> backupUrls)  $default,) {final _that = this;
switch (_that) {
case _MusicStreamOption():
return $default(_that.quality,_that.url,_that.codecs,_that.backupUrls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int quality,  String url,  String codecs,  List<String> backupUrls)?  $default,) {final _that = this;
switch (_that) {
case _MusicStreamOption() when $default != null:
return $default(_that.quality,_that.url,_that.codecs,_that.backupUrls);case _:
  return null;

}
}

}

/// @nodoc


class _MusicStreamOption implements MusicStreamOption {
  const _MusicStreamOption({required this.quality, required this.url, this.codecs = '',  List<String> backupUrls = const []}): _backupUrls = backupUrls;
  

@override final  int quality;
@override final  String url;
@override@JsonKey() final  String codecs;
 final  List<String> _backupUrls;
@override@JsonKey() List<String> get backupUrls {
  if (_backupUrls is EqualUnmodifiableListView) return _backupUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backupUrls);
}


/// Create a copy of MusicStreamOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicStreamOptionCopyWith<_MusicStreamOption> get copyWith => __$MusicStreamOptionCopyWithImpl<_MusicStreamOption>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicStreamOption&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.url, url) || other.url == url)&&(identical(other.codecs, codecs) || other.codecs == codecs)&&const DeepCollectionEquality().equals(other.backupUrls, _backupUrls));
}


@override
int get hashCode {
    return Object.hash(runtimeType,quality,url,codecs,const DeepCollectionEquality().hash(_backupUrls));
}

@override
String toString() {
    return 'MusicStreamOption(quality: $quality, url: $url, codecs: $codecs, backupUrls: $backupUrls)';
}


}

/// @nodoc
abstract mixin class _$MusicStreamOptionCopyWith<$Res> implements $MusicStreamOptionCopyWith<$Res> {
  factory _$MusicStreamOptionCopyWith(_MusicStreamOption value, $Res Function(_MusicStreamOption) _then) = __$MusicStreamOptionCopyWithImpl;
@override @useResult
$Res call({
 int quality, String url, String codecs, List<String> backupUrls
});




}
/// @nodoc
class __$MusicStreamOptionCopyWithImpl<$Res>
    implements _$MusicStreamOptionCopyWith<$Res> {
  __$MusicStreamOptionCopyWithImpl(this._self, this._then);

  final _MusicStreamOption _self;
  final $Res Function(_MusicStreamOption) _then;

/// Create a copy of MusicStreamOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quality = null,Object? url = null,Object? codecs = null,Object? backupUrls = null,}) {
  return _then(_MusicStreamOption(
quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,codecs: null == codecs ? _self.codecs : codecs // ignore: cast_nullable_to_non_nullable
as String,backupUrls: null == backupUrls ? _self._backupUrls : backupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
