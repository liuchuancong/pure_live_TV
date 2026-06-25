// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FavoriteState {

 int get tabSiteIndex; int get tabOnlineIndex; String get selectedTagId; List<LiveRoom> get onlineRooms; List<LiveRoom> get offlineRooms; List<LiveRoom> get replayRooms; List<LiveTag> get visibleTags; bool get isLoading;
/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteStateCopyWith<FavoriteState> get copyWith => _$FavoriteStateCopyWithImpl<FavoriteState>(this as FavoriteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteState&&(identical(other.tabSiteIndex, tabSiteIndex) || other.tabSiteIndex == tabSiteIndex)&&(identical(other.tabOnlineIndex, tabOnlineIndex) || other.tabOnlineIndex == tabOnlineIndex)&&(identical(other.selectedTagId, selectedTagId) || other.selectedTagId == selectedTagId)&&const DeepCollectionEquality().equals(other.onlineRooms, onlineRooms)&&const DeepCollectionEquality().equals(other.offlineRooms, offlineRooms)&&const DeepCollectionEquality().equals(other.replayRooms, replayRooms)&&const DeepCollectionEquality().equals(other.visibleTags, visibleTags)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,tabSiteIndex,tabOnlineIndex,selectedTagId,const DeepCollectionEquality().hash(onlineRooms),const DeepCollectionEquality().hash(offlineRooms),const DeepCollectionEquality().hash(replayRooms),const DeepCollectionEquality().hash(visibleTags),isLoading);

@override
String toString() {
  return 'FavoriteState(tabSiteIndex: $tabSiteIndex, tabOnlineIndex: $tabOnlineIndex, selectedTagId: $selectedTagId, onlineRooms: $onlineRooms, offlineRooms: $offlineRooms, replayRooms: $replayRooms, visibleTags: $visibleTags, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $FavoriteStateCopyWith<$Res>  {
  factory $FavoriteStateCopyWith(FavoriteState value, $Res Function(FavoriteState) _then) = _$FavoriteStateCopyWithImpl;
@useResult
$Res call({
 int tabSiteIndex, int tabOnlineIndex, String selectedTagId, List<LiveRoom> onlineRooms, List<LiveRoom> offlineRooms, List<LiveRoom> replayRooms, List<LiveTag> visibleTags, bool isLoading
});




}
/// @nodoc
class _$FavoriteStateCopyWithImpl<$Res>
    implements $FavoriteStateCopyWith<$Res> {
  _$FavoriteStateCopyWithImpl(this._self, this._then);

  final FavoriteState _self;
  final $Res Function(FavoriteState) _then;

/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tabSiteIndex = null,Object? tabOnlineIndex = null,Object? selectedTagId = null,Object? onlineRooms = null,Object? offlineRooms = null,Object? replayRooms = null,Object? visibleTags = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
tabSiteIndex: null == tabSiteIndex ? _self.tabSiteIndex : tabSiteIndex // ignore: cast_nullable_to_non_nullable
as int,tabOnlineIndex: null == tabOnlineIndex ? _self.tabOnlineIndex : tabOnlineIndex // ignore: cast_nullable_to_non_nullable
as int,selectedTagId: null == selectedTagId ? _self.selectedTagId : selectedTagId // ignore: cast_nullable_to_non_nullable
as String,onlineRooms: null == onlineRooms ? _self.onlineRooms : onlineRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,offlineRooms: null == offlineRooms ? _self.offlineRooms : offlineRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,replayRooms: null == replayRooms ? _self.replayRooms : replayRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,visibleTags: null == visibleTags ? _self.visibleTags : visibleTags // ignore: cast_nullable_to_non_nullable
as List<LiveTag>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteState].
extension FavoriteStatePatterns on FavoriteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteState value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteState value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tabSiteIndex,  int tabOnlineIndex,  String selectedTagId,  List<LiveRoom> onlineRooms,  List<LiveRoom> offlineRooms,  List<LiveRoom> replayRooms,  List<LiveTag> visibleTags,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
return $default(_that.tabSiteIndex,_that.tabOnlineIndex,_that.selectedTagId,_that.onlineRooms,_that.offlineRooms,_that.replayRooms,_that.visibleTags,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tabSiteIndex,  int tabOnlineIndex,  String selectedTagId,  List<LiveRoom> onlineRooms,  List<LiveRoom> offlineRooms,  List<LiveRoom> replayRooms,  List<LiveTag> visibleTags,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _FavoriteState():
return $default(_that.tabSiteIndex,_that.tabOnlineIndex,_that.selectedTagId,_that.onlineRooms,_that.offlineRooms,_that.replayRooms,_that.visibleTags,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tabSiteIndex,  int tabOnlineIndex,  String selectedTagId,  List<LiveRoom> onlineRooms,  List<LiveRoom> offlineRooms,  List<LiveRoom> replayRooms,  List<LiveTag> visibleTags,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
return $default(_that.tabSiteIndex,_that.tabOnlineIndex,_that.selectedTagId,_that.onlineRooms,_that.offlineRooms,_that.replayRooms,_that.visibleTags,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _FavoriteState implements FavoriteState {
  const _FavoriteState({this.tabSiteIndex = 0, this.tabOnlineIndex = 0, this.selectedTagId = 'all', final  List<LiveRoom> onlineRooms = const [], final  List<LiveRoom> offlineRooms = const [], final  List<LiveRoom> replayRooms = const [], final  List<LiveTag> visibleTags = const [], this.isLoading = false}): _onlineRooms = onlineRooms,_offlineRooms = offlineRooms,_replayRooms = replayRooms,_visibleTags = visibleTags;
  

@override@JsonKey() final  int tabSiteIndex;
@override@JsonKey() final  int tabOnlineIndex;
@override@JsonKey() final  String selectedTagId;
 final  List<LiveRoom> _onlineRooms;
@override@JsonKey() List<LiveRoom> get onlineRooms {
  if (_onlineRooms is EqualUnmodifiableListView) return _onlineRooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onlineRooms);
}

 final  List<LiveRoom> _offlineRooms;
@override@JsonKey() List<LiveRoom> get offlineRooms {
  if (_offlineRooms is EqualUnmodifiableListView) return _offlineRooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offlineRooms);
}

 final  List<LiveRoom> _replayRooms;
@override@JsonKey() List<LiveRoom> get replayRooms {
  if (_replayRooms is EqualUnmodifiableListView) return _replayRooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replayRooms);
}

 final  List<LiveTag> _visibleTags;
@override@JsonKey() List<LiveTag> get visibleTags {
  if (_visibleTags is EqualUnmodifiableListView) return _visibleTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_visibleTags);
}

@override@JsonKey() final  bool isLoading;

/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteStateCopyWith<_FavoriteState> get copyWith => __$FavoriteStateCopyWithImpl<_FavoriteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteState&&(identical(other.tabSiteIndex, tabSiteIndex) || other.tabSiteIndex == tabSiteIndex)&&(identical(other.tabOnlineIndex, tabOnlineIndex) || other.tabOnlineIndex == tabOnlineIndex)&&(identical(other.selectedTagId, selectedTagId) || other.selectedTagId == selectedTagId)&&const DeepCollectionEquality().equals(other._onlineRooms, _onlineRooms)&&const DeepCollectionEquality().equals(other._offlineRooms, _offlineRooms)&&const DeepCollectionEquality().equals(other._replayRooms, _replayRooms)&&const DeepCollectionEquality().equals(other._visibleTags, _visibleTags)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,tabSiteIndex,tabOnlineIndex,selectedTagId,const DeepCollectionEquality().hash(_onlineRooms),const DeepCollectionEquality().hash(_offlineRooms),const DeepCollectionEquality().hash(_replayRooms),const DeepCollectionEquality().hash(_visibleTags),isLoading);

@override
String toString() {
  return 'FavoriteState(tabSiteIndex: $tabSiteIndex, tabOnlineIndex: $tabOnlineIndex, selectedTagId: $selectedTagId, onlineRooms: $onlineRooms, offlineRooms: $offlineRooms, replayRooms: $replayRooms, visibleTags: $visibleTags, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$FavoriteStateCopyWith<$Res> implements $FavoriteStateCopyWith<$Res> {
  factory _$FavoriteStateCopyWith(_FavoriteState value, $Res Function(_FavoriteState) _then) = __$FavoriteStateCopyWithImpl;
@override @useResult
$Res call({
 int tabSiteIndex, int tabOnlineIndex, String selectedTagId, List<LiveRoom> onlineRooms, List<LiveRoom> offlineRooms, List<LiveRoom> replayRooms, List<LiveTag> visibleTags, bool isLoading
});




}
/// @nodoc
class __$FavoriteStateCopyWithImpl<$Res>
    implements _$FavoriteStateCopyWith<$Res> {
  __$FavoriteStateCopyWithImpl(this._self, this._then);

  final _FavoriteState _self;
  final $Res Function(_FavoriteState) _then;

/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tabSiteIndex = null,Object? tabOnlineIndex = null,Object? selectedTagId = null,Object? onlineRooms = null,Object? offlineRooms = null,Object? replayRooms = null,Object? visibleTags = null,Object? isLoading = null,}) {
  return _then(_FavoriteState(
tabSiteIndex: null == tabSiteIndex ? _self.tabSiteIndex : tabSiteIndex // ignore: cast_nullable_to_non_nullable
as int,tabOnlineIndex: null == tabOnlineIndex ? _self.tabOnlineIndex : tabOnlineIndex // ignore: cast_nullable_to_non_nullable
as int,selectedTagId: null == selectedTagId ? _self.selectedTagId : selectedTagId // ignore: cast_nullable_to_non_nullable
as String,onlineRooms: null == onlineRooms ? _self._onlineRooms : onlineRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,offlineRooms: null == offlineRooms ? _self._offlineRooms : offlineRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,replayRooms: null == replayRooms ? _self._replayRooms : replayRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,visibleTags: null == visibleTags ? _self._visibleTags : visibleTags // ignore: cast_nullable_to_non_nullable
as List<LiveTag>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
