// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'to_view_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToViewItem {

 MusicArchive get archive; int get cid; int get addAt;
/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToViewItemCopyWith<ToViewItem> get copyWith => _$ToViewItemCopyWithImpl<ToViewItem>(this as ToViewItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ToViewItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToViewItem&&(identical(other.archive, _this.archive) || other.archive == _this.archive)&&(identical(other.cid, _this.cid) || other.cid == _this.cid)&&(identical(other.addAt, _this.addAt) || other.addAt == _this.addAt));
}


@override
int get hashCode {
  final _this = this as ToViewItem;
  return Object.hash(runtimeType,_this.archive,_this.cid,_this.addAt);
}

@override
String toString() {
  final _this = this as ToViewItem;
  return 'ToViewItem(archive: ${_this.archive}, cid: ${_this.cid}, addAt: ${_this.addAt})';
}


}

/// @nodoc
abstract mixin class $ToViewItemCopyWith<$Res>  {
  factory $ToViewItemCopyWith(ToViewItem value, $Res Function(ToViewItem) _then) = _$ToViewItemCopyWithImpl;
@useResult
$Res call({
 MusicArchive archive, int cid, int addAt
});


$MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class _$ToViewItemCopyWithImpl<$Res>
    implements $ToViewItemCopyWith<$Res> {
  _$ToViewItemCopyWithImpl(this._self, this._then);

  final ToViewItem _self;
  final $Res Function(ToViewItem) _then;

/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? archive = null,Object? cid = null,Object? addAt = null,}) {
  return _then(ToViewItem(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,addAt: null == addAt ? _self.addAt : addAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}


/// Adds pattern-matching-related methods to [ToViewItem].
extension ToViewItemPatterns on ToViewItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToViewItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToViewItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToViewItem value)  $default,){
final _that = this;
switch (_that) {
case _ToViewItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToViewItem value)?  $default,){
final _that = this;
switch (_that) {
case _ToViewItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MusicArchive archive,  int cid,  int addAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToViewItem() when $default != null:
return $default(_that.archive,_that.cid,_that.addAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MusicArchive archive,  int cid,  int addAt)  $default,) {final _that = this;
switch (_that) {
case _ToViewItem():
return $default(_that.archive,_that.cid,_that.addAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MusicArchive archive,  int cid,  int addAt)?  $default,) {final _that = this;
switch (_that) {
case _ToViewItem() when $default != null:
return $default(_that.archive,_that.cid,_that.addAt);case _:
  return null;

}
}

}

/// @nodoc


class _ToViewItem implements ToViewItem {
  const _ToViewItem({required this.archive, this.cid = 0, this.addAt = 0});
  

@override final  MusicArchive archive;
@override@JsonKey() final  int cid;
@override@JsonKey() final  int addAt;

/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToViewItemCopyWith<_ToViewItem> get copyWith => __$ToViewItemCopyWithImpl<_ToViewItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToViewItem&&(identical(other.archive, archive) || other.archive == archive)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.addAt, addAt) || other.addAt == addAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,archive,cid,addAt);
}

@override
String toString() {
    return 'ToViewItem(archive: $archive, cid: $cid, addAt: $addAt)';
}


}

/// @nodoc
abstract mixin class _$ToViewItemCopyWith<$Res> implements $ToViewItemCopyWith<$Res> {
  factory _$ToViewItemCopyWith(_ToViewItem value, $Res Function(_ToViewItem) _then) = __$ToViewItemCopyWithImpl;
@override @useResult
$Res call({
 MusicArchive archive, int cid, int addAt
});


@override $MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class __$ToViewItemCopyWithImpl<$Res>
    implements _$ToViewItemCopyWith<$Res> {
  __$ToViewItemCopyWithImpl(this._self, this._then);

  final _ToViewItem _self;
  final $Res Function(_ToViewItem) _then;

/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? archive = null,Object? cid = null,Object? addAt = null,}) {
  return _then(_ToViewItem(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,addAt: null == addAt ? _self.addAt : addAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ToViewItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}

// dart format on
