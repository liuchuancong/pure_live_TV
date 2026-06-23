// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryModel {

 List<LiveRoom> get historyRooms;
/// Create a copy of HistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryModelCopyWith<HistoryModel> get copyWith => _$HistoryModelCopyWithImpl<HistoryModel>(this as HistoryModel, _$identity);

  /// Serializes this HistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryModel&&const DeepCollectionEquality().equals(other.historyRooms, historyRooms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(historyRooms));

@override
String toString() {
  return 'HistoryModel(historyRooms: $historyRooms)';
}


}

/// @nodoc
abstract mixin class $HistoryModelCopyWith<$Res>  {
  factory $HistoryModelCopyWith(HistoryModel value, $Res Function(HistoryModel) _then) = _$HistoryModelCopyWithImpl;
@useResult
$Res call({
 List<LiveRoom> historyRooms
});




}
/// @nodoc
class _$HistoryModelCopyWithImpl<$Res>
    implements $HistoryModelCopyWith<$Res> {
  _$HistoryModelCopyWithImpl(this._self, this._then);

  final HistoryModel _self;
  final $Res Function(HistoryModel) _then;

/// Create a copy of HistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? historyRooms = null,}) {
  return _then(_self.copyWith(
historyRooms: null == historyRooms ? _self.historyRooms : historyRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryModel].
extension HistoryModelPatterns on HistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _HistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LiveRoom> historyRooms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryModel() when $default != null:
return $default(_that.historyRooms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LiveRoom> historyRooms)  $default,) {final _that = this;
switch (_that) {
case _HistoryModel():
return $default(_that.historyRooms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LiveRoom> historyRooms)?  $default,) {final _that = this;
switch (_that) {
case _HistoryModel() when $default != null:
return $default(_that.historyRooms);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryModel implements HistoryModel {
  const _HistoryModel({final  List<LiveRoom> historyRooms = const []}): _historyRooms = historyRooms;
  factory _HistoryModel.fromJson(Map<String, dynamic> json) => _$HistoryModelFromJson(json);

 final  List<LiveRoom> _historyRooms;
@override@JsonKey() List<LiveRoom> get historyRooms {
  if (_historyRooms is EqualUnmodifiableListView) return _historyRooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyRooms);
}


/// Create a copy of HistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryModelCopyWith<_HistoryModel> get copyWith => __$HistoryModelCopyWithImpl<_HistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryModel&&const DeepCollectionEquality().equals(other._historyRooms, _historyRooms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_historyRooms));

@override
String toString() {
  return 'HistoryModel(historyRooms: $historyRooms)';
}


}

/// @nodoc
abstract mixin class _$HistoryModelCopyWith<$Res> implements $HistoryModelCopyWith<$Res> {
  factory _$HistoryModelCopyWith(_HistoryModel value, $Res Function(_HistoryModel) _then) = __$HistoryModelCopyWithImpl;
@override @useResult
$Res call({
 List<LiveRoom> historyRooms
});




}
/// @nodoc
class __$HistoryModelCopyWithImpl<$Res>
    implements _$HistoryModelCopyWith<$Res> {
  __$HistoryModelCopyWithImpl(this._self, this._then);

  final _HistoryModel _self;
  final $Res Function(_HistoryModel) _then;

/// Create a copy of HistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? historyRooms = null,}) {
  return _then(_HistoryModel(
historyRooms: null == historyRooms ? _self._historyRooms : historyRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,
  ));
}


}

// dart format on
