// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_paged_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BasePagedState<T> {

 BaseControllerState get controllerState; List<T> get items; List<T> get allLocalItems; int get currentPage; int get pageSize; bool get canLoadMore; int? get totalCount;
/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasePagedStateCopyWith<T, BasePagedState<T>> get copyWith => _$BasePagedStateCopyWithImpl<T, BasePagedState<T>>(this as BasePagedState<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasePagedState<T>&&(identical(other.controllerState, controllerState) || other.controllerState == controllerState)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.allLocalItems, allLocalItems)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.canLoadMore, canLoadMore) || other.canLoadMore == canLoadMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}


@override
int get hashCode => Object.hash(runtimeType,controllerState,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(allLocalItems),currentPage,pageSize,canLoadMore,totalCount);

@override
String toString() {
  return 'BasePagedState<$T>(controllerState: $controllerState, items: $items, allLocalItems: $allLocalItems, currentPage: $currentPage, pageSize: $pageSize, canLoadMore: $canLoadMore, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class $BasePagedStateCopyWith<T,$Res>  {
  factory $BasePagedStateCopyWith(BasePagedState<T> value, $Res Function(BasePagedState<T>) _then) = _$BasePagedStateCopyWithImpl;
@useResult
$Res call({
 BaseControllerState controllerState, List<T> items, List<T> allLocalItems, int currentPage, int pageSize, bool canLoadMore, int? totalCount
});


$BaseControllerStateCopyWith<$Res> get controllerState;

}
/// @nodoc
class _$BasePagedStateCopyWithImpl<T,$Res>
    implements $BasePagedStateCopyWith<T, $Res> {
  _$BasePagedStateCopyWithImpl(this._self, this._then);

  final BasePagedState<T> _self;
  final $Res Function(BasePagedState<T>) _then;

/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? controllerState = null,Object? items = null,Object? allLocalItems = null,Object? currentPage = null,Object? pageSize = null,Object? canLoadMore = null,Object? totalCount = freezed,}) {
  return _then(_self.copyWith(
controllerState: null == controllerState ? _self.controllerState : controllerState // ignore: cast_nullable_to_non_nullable
as BaseControllerState,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,allLocalItems: null == allLocalItems ? _self.allLocalItems : allLocalItems // ignore: cast_nullable_to_non_nullable
as List<T>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,canLoadMore: null == canLoadMore ? _self.canLoadMore : canLoadMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: freezed == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaseControllerStateCopyWith<$Res> get controllerState {
  
  return $BaseControllerStateCopyWith<$Res>(_self.controllerState, (value) {
    return _then(_self.copyWith(controllerState: value));
  });
}
}


/// Adds pattern-matching-related methods to [BasePagedState].
extension BasePagedStatePatterns<T> on BasePagedState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasePagedState<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasePagedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasePagedState<T> value)  $default,){
final _that = this;
switch (_that) {
case _BasePagedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasePagedState<T> value)?  $default,){
final _that = this;
switch (_that) {
case _BasePagedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BaseControllerState controllerState,  List<T> items,  List<T> allLocalItems,  int currentPage,  int pageSize,  bool canLoadMore,  int? totalCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasePagedState() when $default != null:
return $default(_that.controllerState,_that.items,_that.allLocalItems,_that.currentPage,_that.pageSize,_that.canLoadMore,_that.totalCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BaseControllerState controllerState,  List<T> items,  List<T> allLocalItems,  int currentPage,  int pageSize,  bool canLoadMore,  int? totalCount)  $default,) {final _that = this;
switch (_that) {
case _BasePagedState():
return $default(_that.controllerState,_that.items,_that.allLocalItems,_that.currentPage,_that.pageSize,_that.canLoadMore,_that.totalCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BaseControllerState controllerState,  List<T> items,  List<T> allLocalItems,  int currentPage,  int pageSize,  bool canLoadMore,  int? totalCount)?  $default,) {final _that = this;
switch (_that) {
case _BasePagedState() when $default != null:
return $default(_that.controllerState,_that.items,_that.allLocalItems,_that.currentPage,_that.pageSize,_that.canLoadMore,_that.totalCount);case _:
  return null;

}
}

}

/// @nodoc


class _BasePagedState<T> implements BasePagedState<T> {
  const _BasePagedState({required this.controllerState, final  List<T> items = const [], final  List<T> allLocalItems = const [], this.currentPage = 1, this.pageSize = 20, this.canLoadMore = false, this.totalCount}): _items = items,_allLocalItems = allLocalItems;
  

@override final  BaseControllerState controllerState;
 final  List<T> _items;
@override@JsonKey() List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<T> _allLocalItems;
@override@JsonKey() List<T> get allLocalItems {
  if (_allLocalItems is EqualUnmodifiableListView) return _allLocalItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allLocalItems);
}

@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  bool canLoadMore;
@override final  int? totalCount;

/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasePagedStateCopyWith<T, _BasePagedState<T>> get copyWith => __$BasePagedStateCopyWithImpl<T, _BasePagedState<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasePagedState<T>&&(identical(other.controllerState, controllerState) || other.controllerState == controllerState)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._allLocalItems, _allLocalItems)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.canLoadMore, canLoadMore) || other.canLoadMore == canLoadMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}


@override
int get hashCode => Object.hash(runtimeType,controllerState,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_allLocalItems),currentPage,pageSize,canLoadMore,totalCount);

@override
String toString() {
  return 'BasePagedState<$T>(controllerState: $controllerState, items: $items, allLocalItems: $allLocalItems, currentPage: $currentPage, pageSize: $pageSize, canLoadMore: $canLoadMore, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class _$BasePagedStateCopyWith<T,$Res> implements $BasePagedStateCopyWith<T, $Res> {
  factory _$BasePagedStateCopyWith(_BasePagedState<T> value, $Res Function(_BasePagedState<T>) _then) = __$BasePagedStateCopyWithImpl;
@override @useResult
$Res call({
 BaseControllerState controllerState, List<T> items, List<T> allLocalItems, int currentPage, int pageSize, bool canLoadMore, int? totalCount
});


@override $BaseControllerStateCopyWith<$Res> get controllerState;

}
/// @nodoc
class __$BasePagedStateCopyWithImpl<T,$Res>
    implements _$BasePagedStateCopyWith<T, $Res> {
  __$BasePagedStateCopyWithImpl(this._self, this._then);

  final _BasePagedState<T> _self;
  final $Res Function(_BasePagedState<T>) _then;

/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? controllerState = null,Object? items = null,Object? allLocalItems = null,Object? currentPage = null,Object? pageSize = null,Object? canLoadMore = null,Object? totalCount = freezed,}) {
  return _then(_BasePagedState<T>(
controllerState: null == controllerState ? _self.controllerState : controllerState // ignore: cast_nullable_to_non_nullable
as BaseControllerState,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,allLocalItems: null == allLocalItems ? _self._allLocalItems : allLocalItems // ignore: cast_nullable_to_non_nullable
as List<T>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,canLoadMore: null == canLoadMore ? _self.canLoadMore : canLoadMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: freezed == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of BasePagedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BaseControllerStateCopyWith<$Res> get controllerState {
  
  return $BaseControllerStateCopyWith<$Res>(_self.controllerState, (value) {
    return _then(_self.copyWith(controllerState: value));
  });
}
}

// dart format on
