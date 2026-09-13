// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iptv_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IptvSettingsModel {

 String get selectedSourceName; String get selectedSourceId; bool get isAutoSyncEnabled; int get autoSyncHoursInterval; String get customIptvUserAgent; String get m3uDirectory;
/// Create a copy of IptvSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IptvSettingsModelCopyWith<IptvSettingsModel> get copyWith => _$IptvSettingsModelCopyWithImpl<IptvSettingsModel>(this as IptvSettingsModel, _$identity);

  /// Serializes this IptvSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IptvSettingsModel&&(identical(other.selectedSourceName, selectedSourceName) || other.selectedSourceName == selectedSourceName)&&(identical(other.selectedSourceId, selectedSourceId) || other.selectedSourceId == selectedSourceId)&&(identical(other.isAutoSyncEnabled, isAutoSyncEnabled) || other.isAutoSyncEnabled == isAutoSyncEnabled)&&(identical(other.autoSyncHoursInterval, autoSyncHoursInterval) || other.autoSyncHoursInterval == autoSyncHoursInterval)&&(identical(other.customIptvUserAgent, customIptvUserAgent) || other.customIptvUserAgent == customIptvUserAgent)&&(identical(other.m3uDirectory, m3uDirectory) || other.m3uDirectory == m3uDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,selectedSourceName,selectedSourceId,isAutoSyncEnabled,autoSyncHoursInterval,customIptvUserAgent,m3uDirectory);

@override
String toString() {
  return 'IptvSettingsModel(selectedSourceName: $selectedSourceName, selectedSourceId: $selectedSourceId, isAutoSyncEnabled: $isAutoSyncEnabled, autoSyncHoursInterval: $autoSyncHoursInterval, customIptvUserAgent: $customIptvUserAgent, m3uDirectory: $m3uDirectory)';
}


}

/// @nodoc
abstract mixin class $IptvSettingsModelCopyWith<$Res>  {
  factory $IptvSettingsModelCopyWith(IptvSettingsModel value, $Res Function(IptvSettingsModel) _then) = _$IptvSettingsModelCopyWithImpl;
@useResult
$Res call({
 String selectedSourceName, String selectedSourceId, bool isAutoSyncEnabled, int autoSyncHoursInterval, String customIptvUserAgent, String m3uDirectory
});




}
/// @nodoc
class _$IptvSettingsModelCopyWithImpl<$Res>
    implements $IptvSettingsModelCopyWith<$Res> {
  _$IptvSettingsModelCopyWithImpl(this._self, this._then);

  final IptvSettingsModel _self;
  final $Res Function(IptvSettingsModel) _then;

/// Create a copy of IptvSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedSourceName = null,Object? selectedSourceId = null,Object? isAutoSyncEnabled = null,Object? autoSyncHoursInterval = null,Object? customIptvUserAgent = null,Object? m3uDirectory = null,}) {
  return _then(_self.copyWith(
selectedSourceName: null == selectedSourceName ? _self.selectedSourceName : selectedSourceName // ignore: cast_nullable_to_non_nullable
as String,selectedSourceId: null == selectedSourceId ? _self.selectedSourceId : selectedSourceId // ignore: cast_nullable_to_non_nullable
as String,isAutoSyncEnabled: null == isAutoSyncEnabled ? _self.isAutoSyncEnabled : isAutoSyncEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoSyncHoursInterval: null == autoSyncHoursInterval ? _self.autoSyncHoursInterval : autoSyncHoursInterval // ignore: cast_nullable_to_non_nullable
as int,customIptvUserAgent: null == customIptvUserAgent ? _self.customIptvUserAgent : customIptvUserAgent // ignore: cast_nullable_to_non_nullable
as String,m3uDirectory: null == m3uDirectory ? _self.m3uDirectory : m3uDirectory // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IptvSettingsModel].
extension IptvSettingsModelPatterns on IptvSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IptvSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IptvSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IptvSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _IptvSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IptvSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _IptvSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String selectedSourceName,  String selectedSourceId,  bool isAutoSyncEnabled,  int autoSyncHoursInterval,  String customIptvUserAgent,  String m3uDirectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IptvSettingsModel() when $default != null:
return $default(_that.selectedSourceName,_that.selectedSourceId,_that.isAutoSyncEnabled,_that.autoSyncHoursInterval,_that.customIptvUserAgent,_that.m3uDirectory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String selectedSourceName,  String selectedSourceId,  bool isAutoSyncEnabled,  int autoSyncHoursInterval,  String customIptvUserAgent,  String m3uDirectory)  $default,) {final _that = this;
switch (_that) {
case _IptvSettingsModel():
return $default(_that.selectedSourceName,_that.selectedSourceId,_that.isAutoSyncEnabled,_that.autoSyncHoursInterval,_that.customIptvUserAgent,_that.m3uDirectory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String selectedSourceName,  String selectedSourceId,  bool isAutoSyncEnabled,  int autoSyncHoursInterval,  String customIptvUserAgent,  String m3uDirectory)?  $default,) {final _that = this;
switch (_that) {
case _IptvSettingsModel() when $default != null:
return $default(_that.selectedSourceName,_that.selectedSourceId,_that.isAutoSyncEnabled,_that.autoSyncHoursInterval,_that.customIptvUserAgent,_that.m3uDirectory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IptvSettingsModel implements IptvSettingsModel {
  const _IptvSettingsModel({this.selectedSourceName = '', this.selectedSourceId = '', this.isAutoSyncEnabled = false, this.autoSyncHoursInterval = 24, this.customIptvUserAgent = '', this.m3uDirectory = 'm3uDirectory'});
  factory _IptvSettingsModel.fromJson(Map<String, dynamic> json) => _$IptvSettingsModelFromJson(json);

@override@JsonKey() final  String selectedSourceName;
@override@JsonKey() final  String selectedSourceId;
@override@JsonKey() final  bool isAutoSyncEnabled;
@override@JsonKey() final  int autoSyncHoursInterval;
@override@JsonKey() final  String customIptvUserAgent;
@override@JsonKey() final  String m3uDirectory;

/// Create a copy of IptvSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IptvSettingsModelCopyWith<_IptvSettingsModel> get copyWith => __$IptvSettingsModelCopyWithImpl<_IptvSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IptvSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IptvSettingsModel&&(identical(other.selectedSourceName, selectedSourceName) || other.selectedSourceName == selectedSourceName)&&(identical(other.selectedSourceId, selectedSourceId) || other.selectedSourceId == selectedSourceId)&&(identical(other.isAutoSyncEnabled, isAutoSyncEnabled) || other.isAutoSyncEnabled == isAutoSyncEnabled)&&(identical(other.autoSyncHoursInterval, autoSyncHoursInterval) || other.autoSyncHoursInterval == autoSyncHoursInterval)&&(identical(other.customIptvUserAgent, customIptvUserAgent) || other.customIptvUserAgent == customIptvUserAgent)&&(identical(other.m3uDirectory, m3uDirectory) || other.m3uDirectory == m3uDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,selectedSourceName,selectedSourceId,isAutoSyncEnabled,autoSyncHoursInterval,customIptvUserAgent,m3uDirectory);

@override
String toString() {
  return 'IptvSettingsModel(selectedSourceName: $selectedSourceName, selectedSourceId: $selectedSourceId, isAutoSyncEnabled: $isAutoSyncEnabled, autoSyncHoursInterval: $autoSyncHoursInterval, customIptvUserAgent: $customIptvUserAgent, m3uDirectory: $m3uDirectory)';
}


}

/// @nodoc
abstract mixin class _$IptvSettingsModelCopyWith<$Res> implements $IptvSettingsModelCopyWith<$Res> {
  factory _$IptvSettingsModelCopyWith(_IptvSettingsModel value, $Res Function(_IptvSettingsModel) _then) = __$IptvSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String selectedSourceName, String selectedSourceId, bool isAutoSyncEnabled, int autoSyncHoursInterval, String customIptvUserAgent, String m3uDirectory
});




}
/// @nodoc
class __$IptvSettingsModelCopyWithImpl<$Res>
    implements _$IptvSettingsModelCopyWith<$Res> {
  __$IptvSettingsModelCopyWithImpl(this._self, this._then);

  final _IptvSettingsModel _self;
  final $Res Function(_IptvSettingsModel) _then;

/// Create a copy of IptvSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedSourceName = null,Object? selectedSourceId = null,Object? isAutoSyncEnabled = null,Object? autoSyncHoursInterval = null,Object? customIptvUserAgent = null,Object? m3uDirectory = null,}) {
  return _then(_IptvSettingsModel(
selectedSourceName: null == selectedSourceName ? _self.selectedSourceName : selectedSourceName // ignore: cast_nullable_to_non_nullable
as String,selectedSourceId: null == selectedSourceId ? _self.selectedSourceId : selectedSourceId // ignore: cast_nullable_to_non_nullable
as String,isAutoSyncEnabled: null == isAutoSyncEnabled ? _self.isAutoSyncEnabled : isAutoSyncEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoSyncHoursInterval: null == autoSyncHoursInterval ? _self.autoSyncHoursInterval : autoSyncHoursInterval // ignore: cast_nullable_to_non_nullable
as int,customIptvUserAgent: null == customIptvUserAgent ? _self.customIptvUserAgent : customIptvUserAgent // ignore: cast_nullable_to_non_nullable
as String,m3uDirectory: null == m3uDirectory ? _self.m3uDirectory : m3uDirectory // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
