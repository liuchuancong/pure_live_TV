// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fav_folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FavFolder {

 int get id; String get title; int get mediaCount; String get cover; bool get isPublic;
/// Create a copy of FavFolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavFolderCopyWith<FavFolder> get copyWith => _$FavFolderCopyWithImpl<FavFolder>(this as FavFolder, _$identity);

  /// Serializes this FavFolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FavFolder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavFolder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.mediaCount, _this.mediaCount) || other.mediaCount == _this.mediaCount)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavFolder;
  return Object.hash(runtimeType,_this.id,_this.title,_this.mediaCount,_this.cover,_this.isPublic);
}

@override
String toString() {
  final _this = this as FavFolder;
  return 'FavFolder(id: ${_this.id}, title: ${_this.title}, mediaCount: ${_this.mediaCount}, cover: ${_this.cover}, isPublic: ${_this.isPublic})';
}


}

/// @nodoc
abstract mixin class $FavFolderCopyWith<$Res>  {
  factory $FavFolderCopyWith(FavFolder value, $Res Function(FavFolder) _then) = _$FavFolderCopyWithImpl;
@useResult
$Res call({
 int id, String title, int mediaCount, String cover, bool isPublic
});




}
/// @nodoc
class _$FavFolderCopyWithImpl<$Res>
    implements $FavFolderCopyWith<$Res> {
  _$FavFolderCopyWithImpl(this._self, this._then);

  final FavFolder _self;
  final $Res Function(FavFolder) _then;

/// Create a copy of FavFolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mediaCount = null,Object? cover = null,Object? isPublic = null,}) {
  return _then(FavFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaCount: null == mediaCount ? _self.mediaCount : mediaCount // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FavFolder].
extension FavFolderPatterns on FavFolder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavFolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavFolder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavFolder value)  $default,){
final _that = this;
switch (_that) {
case _FavFolder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavFolder value)?  $default,){
final _that = this;
switch (_that) {
case _FavFolder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  int mediaCount,  String cover,  bool isPublic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavFolder() when $default != null:
return $default(_that.id,_that.title,_that.mediaCount,_that.cover,_that.isPublic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  int mediaCount,  String cover,  bool isPublic)  $default,) {final _that = this;
switch (_that) {
case _FavFolder():
return $default(_that.id,_that.title,_that.mediaCount,_that.cover,_that.isPublic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  int mediaCount,  String cover,  bool isPublic)?  $default,) {final _that = this;
switch (_that) {
case _FavFolder() when $default != null:
return $default(_that.id,_that.title,_that.mediaCount,_that.cover,_that.isPublic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavFolder implements FavFolder {
  const _FavFolder({this.id = 0, this.title = '', this.mediaCount = 0, this.cover = '', this.isPublic = true});
  factory _FavFolder.fromJson(Map<String, dynamic> json) => _$FavFolderFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String title;
@override@JsonKey() final  int mediaCount;
@override@JsonKey() final  String cover;
@override@JsonKey() final  bool isPublic;

/// Create a copy of FavFolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavFolderCopyWith<_FavFolder> get copyWith => __$FavFolderCopyWithImpl<_FavFolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavFolderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaCount, mediaCount) || other.mediaCount == mediaCount)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,mediaCount,cover,isPublic);
}

@override
String toString() {
    return 'FavFolder(id: $id, title: $title, mediaCount: $mediaCount, cover: $cover, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class _$FavFolderCopyWith<$Res> implements $FavFolderCopyWith<$Res> {
  factory _$FavFolderCopyWith(_FavFolder value, $Res Function(_FavFolder) _then) = __$FavFolderCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, int mediaCount, String cover, bool isPublic
});




}
/// @nodoc
class __$FavFolderCopyWithImpl<$Res>
    implements _$FavFolderCopyWith<$Res> {
  __$FavFolderCopyWithImpl(this._self, this._then);

  final _FavFolder _self;
  final $Res Function(_FavFolder) _then;

/// Create a copy of FavFolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mediaCount = null,Object? cover = null,Object? isPublic = null,}) {
  return _then(_FavFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaCount: null == mediaCount ? _self.mediaCount : mediaCount // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
