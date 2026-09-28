// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_playlist_sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicPlaylistSyncState {

/// Cached fav folders (created ones; collected folders sync on demand).
 List<FavFolder> get folders;/// Folder id → cached archives.
 Map<int, List<MusicArchive>> get folderTracks;/// Folder id → time of the last full sync.
 Map<int, DateTime> get syncedAt;/// The folder currently refreshing (0 = none).
 int get syncingFolderId;/// Last sync error, surfaced on the playlist page.
 String get error;
/// Create a copy of MusicPlaylistSyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicPlaylistSyncStateCopyWith<MusicPlaylistSyncState> get copyWith => _$MusicPlaylistSyncStateCopyWithImpl<MusicPlaylistSyncState>(this as MusicPlaylistSyncState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicPlaylistSyncState&&const DeepCollectionEquality().equals(other.folders, folders)&&const DeepCollectionEquality().equals(other.folderTracks, folderTracks)&&const DeepCollectionEquality().equals(other.syncedAt, syncedAt)&&(identical(other.syncingFolderId, syncingFolderId) || other.syncingFolderId == syncingFolderId)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(folders),const DeepCollectionEquality().hash(folderTracks),const DeepCollectionEquality().hash(syncedAt),syncingFolderId,error);

@override
String toString() {
  return 'MusicPlaylistSyncState(folders: $folders, folderTracks: $folderTracks, syncedAt: $syncedAt, syncingFolderId: $syncingFolderId, error: $error)';
}


}

/// @nodoc
abstract mixin class $MusicPlaylistSyncStateCopyWith<$Res>  {
  factory $MusicPlaylistSyncStateCopyWith(MusicPlaylistSyncState value, $Res Function(MusicPlaylistSyncState) _then) = _$MusicPlaylistSyncStateCopyWithImpl;
@useResult
$Res call({
 List<FavFolder> folders, Map<int, List<MusicArchive>> folderTracks, Map<int, DateTime> syncedAt, int syncingFolderId, String error
});




}
/// @nodoc
class _$MusicPlaylistSyncStateCopyWithImpl<$Res>
    implements $MusicPlaylistSyncStateCopyWith<$Res> {
  _$MusicPlaylistSyncStateCopyWithImpl(this._self, this._then);

  final MusicPlaylistSyncState _self;
  final $Res Function(MusicPlaylistSyncState) _then;

/// Create a copy of MusicPlaylistSyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? folders = null,Object? folderTracks = null,Object? syncedAt = null,Object? syncingFolderId = null,Object? error = null,}) {
  return _then(_self.copyWith(
folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as List<FavFolder>,folderTracks: null == folderTracks ? _self.folderTracks : folderTracks // ignore: cast_nullable_to_non_nullable
as Map<int, List<MusicArchive>>,syncedAt: null == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as Map<int, DateTime>,syncingFolderId: null == syncingFolderId ? _self.syncingFolderId : syncingFolderId // ignore: cast_nullable_to_non_nullable
as int,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicPlaylistSyncState].
extension MusicPlaylistSyncStatePatterns on MusicPlaylistSyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicPlaylistSyncState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicPlaylistSyncState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicPlaylistSyncState value)  $default,){
final _that = this;
switch (_that) {
case _MusicPlaylistSyncState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicPlaylistSyncState value)?  $default,){
final _that = this;
switch (_that) {
case _MusicPlaylistSyncState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FavFolder> folders,  Map<int, List<MusicArchive>> folderTracks,  Map<int, DateTime> syncedAt,  int syncingFolderId,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicPlaylistSyncState() when $default != null:
return $default(_that.folders,_that.folderTracks,_that.syncedAt,_that.syncingFolderId,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FavFolder> folders,  Map<int, List<MusicArchive>> folderTracks,  Map<int, DateTime> syncedAt,  int syncingFolderId,  String error)  $default,) {final _that = this;
switch (_that) {
case _MusicPlaylistSyncState():
return $default(_that.folders,_that.folderTracks,_that.syncedAt,_that.syncingFolderId,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FavFolder> folders,  Map<int, List<MusicArchive>> folderTracks,  Map<int, DateTime> syncedAt,  int syncingFolderId,  String error)?  $default,) {final _that = this;
switch (_that) {
case _MusicPlaylistSyncState() when $default != null:
return $default(_that.folders,_that.folderTracks,_that.syncedAt,_that.syncingFolderId,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _MusicPlaylistSyncState implements MusicPlaylistSyncState {
  const _MusicPlaylistSyncState({final  List<FavFolder> folders = const [], final  Map<int, List<MusicArchive>> folderTracks = const {}, final  Map<int, DateTime> syncedAt = const {}, this.syncingFolderId = 0, this.error = ''}): _folders = folders,_folderTracks = folderTracks,_syncedAt = syncedAt;
  

/// Cached fav folders (created ones; collected folders sync on demand).
 final  List<FavFolder> _folders;
/// Cached fav folders (created ones; collected folders sync on demand).
@override@JsonKey() List<FavFolder> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

/// Folder id → cached archives.
 final  Map<int, List<MusicArchive>> _folderTracks;
/// Folder id → cached archives.
@override@JsonKey() Map<int, List<MusicArchive>> get folderTracks {
  if (_folderTracks is EqualUnmodifiableMapView) return _folderTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_folderTracks);
}

/// Folder id → time of the last full sync.
 final  Map<int, DateTime> _syncedAt;
/// Folder id → time of the last full sync.
@override@JsonKey() Map<int, DateTime> get syncedAt {
  if (_syncedAt is EqualUnmodifiableMapView) return _syncedAt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_syncedAt);
}

/// The folder currently refreshing (0 = none).
@override@JsonKey() final  int syncingFolderId;
/// Last sync error, surfaced on the playlist page.
@override@JsonKey() final  String error;

/// Create a copy of MusicPlaylistSyncState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicPlaylistSyncStateCopyWith<_MusicPlaylistSyncState> get copyWith => __$MusicPlaylistSyncStateCopyWithImpl<_MusicPlaylistSyncState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicPlaylistSyncState&&const DeepCollectionEquality().equals(other._folders, _folders)&&const DeepCollectionEquality().equals(other._folderTracks, _folderTracks)&&const DeepCollectionEquality().equals(other._syncedAt, _syncedAt)&&(identical(other.syncingFolderId, syncingFolderId) || other.syncingFolderId == syncingFolderId)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_folderTracks),const DeepCollectionEquality().hash(_syncedAt),syncingFolderId,error);

@override
String toString() {
  return 'MusicPlaylistSyncState(folders: $folders, folderTracks: $folderTracks, syncedAt: $syncedAt, syncingFolderId: $syncingFolderId, error: $error)';
}


}

/// @nodoc
abstract mixin class _$MusicPlaylistSyncStateCopyWith<$Res> implements $MusicPlaylistSyncStateCopyWith<$Res> {
  factory _$MusicPlaylistSyncStateCopyWith(_MusicPlaylistSyncState value, $Res Function(_MusicPlaylistSyncState) _then) = __$MusicPlaylistSyncStateCopyWithImpl;
@override @useResult
$Res call({
 List<FavFolder> folders, Map<int, List<MusicArchive>> folderTracks, Map<int, DateTime> syncedAt, int syncingFolderId, String error
});




}
/// @nodoc
class __$MusicPlaylistSyncStateCopyWithImpl<$Res>
    implements _$MusicPlaylistSyncStateCopyWith<$Res> {
  __$MusicPlaylistSyncStateCopyWithImpl(this._self, this._then);

  final _MusicPlaylistSyncState _self;
  final $Res Function(_MusicPlaylistSyncState) _then;

/// Create a copy of MusicPlaylistSyncState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? folders = null,Object? folderTracks = null,Object? syncedAt = null,Object? syncingFolderId = null,Object? error = null,}) {
  return _then(_MusicPlaylistSyncState(
folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<FavFolder>,folderTracks: null == folderTracks ? _self._folderTracks : folderTracks // ignore: cast_nullable_to_non_nullable
as Map<int, List<MusicArchive>>,syncedAt: null == syncedAt ? _self._syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as Map<int, DateTime>,syncingFolderId: null == syncingFolderId ? _self.syncingFolderId : syncingFolderId // ignore: cast_nullable_to_non_nullable
as int,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
