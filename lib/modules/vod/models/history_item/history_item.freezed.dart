// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryItem {

 MusicArchive get archive; int get cid; int get page; int get progress; int get duration; int get viewAt;/// PGC rows carry an episode id; video-mode history mixes both.
 int get epid; int get seasonId;
/// Create a copy of HistoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryItemCopyWith<HistoryItem> get copyWith => _$HistoryItemCopyWithImpl<HistoryItem>(this as HistoryItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HistoryItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryItem&&(identical(other.archive, _this.archive) || other.archive == _this.archive)&&(identical(other.cid, _this.cid) || other.cid == _this.cid)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.viewAt, _this.viewAt) || other.viewAt == _this.viewAt)&&(identical(other.epid, _this.epid) || other.epid == _this.epid)&&(identical(other.seasonId, _this.seasonId) || other.seasonId == _this.seasonId));
}


@override
int get hashCode {
  final _this = this as HistoryItem;
  return Object.hash(runtimeType,_this.archive,_this.cid,_this.page,_this.progress,_this.duration,_this.viewAt,_this.epid,_this.seasonId);
}

@override
String toString() {
  final _this = this as HistoryItem;
  return 'HistoryItem(archive: ${_this.archive}, cid: ${_this.cid}, page: ${_this.page}, progress: ${_this.progress}, duration: ${_this.duration}, viewAt: ${_this.viewAt}, epid: ${_this.epid}, seasonId: ${_this.seasonId})';
}


}

/// @nodoc
abstract mixin class $HistoryItemCopyWith<$Res>  {
  factory $HistoryItemCopyWith(HistoryItem value, $Res Function(HistoryItem) _then) = _$HistoryItemCopyWithImpl;
@useResult
$Res call({
 MusicArchive archive, int cid, int page, int progress, int duration, int viewAt, int epid, int seasonId
});


$MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class _$HistoryItemCopyWithImpl<$Res>
    implements $HistoryItemCopyWith<$Res> {
  _$HistoryItemCopyWithImpl(this._self, this._then);

  final HistoryItem _self;
  final $Res Function(HistoryItem) _then;

/// Create a copy of HistoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? archive = null,Object? cid = null,Object? page = null,Object? progress = null,Object? duration = null,Object? viewAt = null,Object? epid = null,Object? seasonId = null,}) {
  return _then(HistoryItem(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,viewAt: null == viewAt ? _self.viewAt : viewAt // ignore: cast_nullable_to_non_nullable
as int,epid: null == epid ? _self.epid : epid // ignore: cast_nullable_to_non_nullable
as int,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HistoryItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryItem].
extension HistoryItemPatterns on HistoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryItem value)  $default,){
final _that = this;
switch (_that) {
case _HistoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MusicArchive archive,  int cid,  int page,  int progress,  int duration,  int viewAt,  int epid,  int seasonId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryItem() when $default != null:
return $default(_that.archive,_that.cid,_that.page,_that.progress,_that.duration,_that.viewAt,_that.epid,_that.seasonId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MusicArchive archive,  int cid,  int page,  int progress,  int duration,  int viewAt,  int epid,  int seasonId)  $default,) {final _that = this;
switch (_that) {
case _HistoryItem():
return $default(_that.archive,_that.cid,_that.page,_that.progress,_that.duration,_that.viewAt,_that.epid,_that.seasonId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MusicArchive archive,  int cid,  int page,  int progress,  int duration,  int viewAt,  int epid,  int seasonId)?  $default,) {final _that = this;
switch (_that) {
case _HistoryItem() when $default != null:
return $default(_that.archive,_that.cid,_that.page,_that.progress,_that.duration,_that.viewAt,_that.epid,_that.seasonId);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryItem extends HistoryItem {
  const _HistoryItem({required this.archive, this.cid = 0, this.page = 1, this.progress = 0, this.duration = 0, this.viewAt = 0, this.epid = 0, this.seasonId = 0}): super._();
  

@override final  MusicArchive archive;
@override@JsonKey() final  int cid;
@override@JsonKey() final  int page;
@override@JsonKey() final  int progress;
@override@JsonKey() final  int duration;
@override@JsonKey() final  int viewAt;
/// PGC rows carry an episode id; video-mode history mixes both.
@override@JsonKey() final  int epid;
@override@JsonKey() final  int seasonId;

/// Create a copy of HistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryItemCopyWith<_HistoryItem> get copyWith => __$HistoryItemCopyWithImpl<_HistoryItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryItem&&(identical(other.archive, archive) || other.archive == archive)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.page, page) || other.page == page)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.viewAt, viewAt) || other.viewAt == viewAt)&&(identical(other.epid, epid) || other.epid == epid)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,archive,cid,page,progress,duration,viewAt,epid,seasonId);
}

@override
String toString() {
    return 'HistoryItem(archive: $archive, cid: $cid, page: $page, progress: $progress, duration: $duration, viewAt: $viewAt, epid: $epid, seasonId: $seasonId)';
}


}

/// @nodoc
abstract mixin class _$HistoryItemCopyWith<$Res> implements $HistoryItemCopyWith<$Res> {
  factory _$HistoryItemCopyWith(_HistoryItem value, $Res Function(_HistoryItem) _then) = __$HistoryItemCopyWithImpl;
@override @useResult
$Res call({
 MusicArchive archive, int cid, int page, int progress, int duration, int viewAt, int epid, int seasonId
});


@override $MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class __$HistoryItemCopyWithImpl<$Res>
    implements _$HistoryItemCopyWith<$Res> {
  __$HistoryItemCopyWithImpl(this._self, this._then);

  final _HistoryItem _self;
  final $Res Function(_HistoryItem) _then;

/// Create a copy of HistoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? archive = null,Object? cid = null,Object? page = null,Object? progress = null,Object? duration = null,Object? viewAt = null,Object? epid = null,Object? seasonId = null,}) {
  return _then(_HistoryItem(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,viewAt: null == viewAt ? _self.viewAt : viewAt // ignore: cast_nullable_to_non_nullable
as int,epid: null == epid ? _self.epid : epid // ignore: cast_nullable_to_non_nullable
as int,seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HistoryItem
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
