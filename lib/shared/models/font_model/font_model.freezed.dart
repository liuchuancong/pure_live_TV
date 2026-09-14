// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'font_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FontModel {

 String get id; String get name; List<String> get files; String get desc; String get official; Map<String, dynamic> get license;
/// Create a copy of FontModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FontModelCopyWith<FontModel> get copyWith => _$FontModelCopyWithImpl<FontModel>(this as FontModel, _$identity);

  /// Serializes this FontModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FontModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.official, official) || other.official == official)&&const DeepCollectionEquality().equals(other.license, license));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(files),desc,official,const DeepCollectionEquality().hash(license));

@override
String toString() {
  return 'FontModel(id: $id, name: $name, files: $files, desc: $desc, official: $official, license: $license)';
}


}

/// @nodoc
abstract mixin class $FontModelCopyWith<$Res>  {
  factory $FontModelCopyWith(FontModel value, $Res Function(FontModel) _then) = _$FontModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> files, String desc, String official, Map<String, dynamic> license
});




}
/// @nodoc
class _$FontModelCopyWithImpl<$Res>
    implements $FontModelCopyWith<$Res> {
  _$FontModelCopyWithImpl(this._self, this._then);

  final FontModel _self;
  final $Res Function(FontModel) _then;

/// Create a copy of FontModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? files = null,Object? desc = null,Object? official = null,Object? license = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<String>,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,official: null == official ? _self.official : official // ignore: cast_nullable_to_non_nullable
as String,license: null == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [FontModel].
extension FontModelPatterns on FontModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FontModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FontModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FontModel value)  $default,){
final _that = this;
switch (_that) {
case _FontModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FontModel value)?  $default,){
final _that = this;
switch (_that) {
case _FontModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> files,  String desc,  String official,  Map<String, dynamic> license)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FontModel() when $default != null:
return $default(_that.id,_that.name,_that.files,_that.desc,_that.official,_that.license);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> files,  String desc,  String official,  Map<String, dynamic> license)  $default,) {final _that = this;
switch (_that) {
case _FontModel():
return $default(_that.id,_that.name,_that.files,_that.desc,_that.official,_that.license);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> files,  String desc,  String official,  Map<String, dynamic> license)?  $default,) {final _that = this;
switch (_that) {
case _FontModel() when $default != null:
return $default(_that.id,_that.name,_that.files,_that.desc,_that.official,_that.license);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FontModel implements FontModel {
  const _FontModel({this.id = '', this.name = '', final  List<String> files = const [], this.desc = '', this.official = '', final  Map<String, dynamic> license = const {}}): _files = files,_license = license;
  factory _FontModel.fromJson(Map<String, dynamic> json) => _$FontModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
 final  List<String> _files;
@override@JsonKey() List<String> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

@override@JsonKey() final  String desc;
@override@JsonKey() final  String official;
 final  Map<String, dynamic> _license;
@override@JsonKey() Map<String, dynamic> get license {
  if (_license is EqualUnmodifiableMapView) return _license;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_license);
}


/// Create a copy of FontModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FontModelCopyWith<_FontModel> get copyWith => __$FontModelCopyWithImpl<_FontModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FontModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FontModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.desc, desc) || other.desc == desc)&&(identical(other.official, official) || other.official == official)&&const DeepCollectionEquality().equals(other._license, _license));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_files),desc,official,const DeepCollectionEquality().hash(_license));

@override
String toString() {
  return 'FontModel(id: $id, name: $name, files: $files, desc: $desc, official: $official, license: $license)';
}


}

/// @nodoc
abstract mixin class _$FontModelCopyWith<$Res> implements $FontModelCopyWith<$Res> {
  factory _$FontModelCopyWith(_FontModel value, $Res Function(_FontModel) _then) = __$FontModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> files, String desc, String official, Map<String, dynamic> license
});




}
/// @nodoc
class __$FontModelCopyWithImpl<$Res>
    implements _$FontModelCopyWith<$Res> {
  __$FontModelCopyWithImpl(this._self, this._then);

  final _FontModel _self;
  final $Res Function(_FontModel) _then;

/// Create a copy of FontModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? files = null,Object? desc = null,Object? official = null,Object? license = null,}) {
  return _then(_FontModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<String>,desc: null == desc ? _self.desc : desc // ignore: cast_nullable_to_non_nullable
as String,official: null == official ? _self.official : official // ignore: cast_nullable_to_non_nullable
as String,license: null == license ? _self._license : license // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
