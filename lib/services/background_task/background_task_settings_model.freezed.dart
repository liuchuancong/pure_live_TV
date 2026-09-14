// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_task_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackgroundTaskSettings implements DiagnosticableTreeMixin {

 bool get enabled;@JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson) List<BackgroundTaskConfig> get tasks;
/// Create a copy of BackgroundTaskSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundTaskSettingsCopyWith<BackgroundTaskSettings> get copyWith => _$BackgroundTaskSettingsCopyWithImpl<BackgroundTaskSettings>(this as BackgroundTaskSettings, _$identity);

  /// Serializes this BackgroundTaskSettings to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BackgroundTaskSettings'))
    ..add(DiagnosticsProperty('enabled', enabled))..add(DiagnosticsProperty('tasks', tasks));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundTaskSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.tasks, tasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(tasks));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BackgroundTaskSettings(enabled: $enabled, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class $BackgroundTaskSettingsCopyWith<$Res>  {
  factory $BackgroundTaskSettingsCopyWith(BackgroundTaskSettings value, $Res Function(BackgroundTaskSettings) _then) = _$BackgroundTaskSettingsCopyWithImpl;
@useResult
$Res call({
 bool enabled,@JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson) List<BackgroundTaskConfig> tasks
});




}
/// @nodoc
class _$BackgroundTaskSettingsCopyWithImpl<$Res>
    implements $BackgroundTaskSettingsCopyWith<$Res> {
  _$BackgroundTaskSettingsCopyWithImpl(this._self, this._then);

  final BackgroundTaskSettings _self;
  final $Res Function(BackgroundTaskSettings) _then;

/// Create a copy of BackgroundTaskSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? tasks = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<BackgroundTaskConfig>,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundTaskSettings].
extension BackgroundTaskSettingsPatterns on BackgroundTaskSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundTaskSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundTaskSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundTaskSettings value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundTaskSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundTaskSettings value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundTaskSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled, @JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson)  List<BackgroundTaskConfig> tasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundTaskSettings() when $default != null:
return $default(_that.enabled,_that.tasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled, @JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson)  List<BackgroundTaskConfig> tasks)  $default,) {final _that = this;
switch (_that) {
case _BackgroundTaskSettings():
return $default(_that.enabled,_that.tasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled, @JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson)  List<BackgroundTaskConfig> tasks)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundTaskSettings() when $default != null:
return $default(_that.enabled,_that.tasks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackgroundTaskSettings with DiagnosticableTreeMixin implements BackgroundTaskSettings {
  const _BackgroundTaskSettings({this.enabled = true, @JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson) final  List<BackgroundTaskConfig> tasks = const <BackgroundTaskConfig>[]}): _tasks = tasks;
  factory _BackgroundTaskSettings.fromJson(Map<String, dynamic> json) => _$BackgroundTaskSettingsFromJson(json);

@override@JsonKey() final  bool enabled;
 final  List<BackgroundTaskConfig> _tasks;
@override@JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson) List<BackgroundTaskConfig> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of BackgroundTaskSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundTaskSettingsCopyWith<_BackgroundTaskSettings> get copyWith => __$BackgroundTaskSettingsCopyWithImpl<_BackgroundTaskSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackgroundTaskSettingsToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BackgroundTaskSettings'))
    ..add(DiagnosticsProperty('enabled', enabled))..add(DiagnosticsProperty('tasks', tasks));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundTaskSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(_tasks));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BackgroundTaskSettings(enabled: $enabled, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$BackgroundTaskSettingsCopyWith<$Res> implements $BackgroundTaskSettingsCopyWith<$Res> {
  factory _$BackgroundTaskSettingsCopyWith(_BackgroundTaskSettings value, $Res Function(_BackgroundTaskSettings) _then) = __$BackgroundTaskSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool enabled,@JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson) List<BackgroundTaskConfig> tasks
});




}
/// @nodoc
class __$BackgroundTaskSettingsCopyWithImpl<$Res>
    implements _$BackgroundTaskSettingsCopyWith<$Res> {
  __$BackgroundTaskSettingsCopyWithImpl(this._self, this._then);

  final _BackgroundTaskSettings _self;
  final $Res Function(_BackgroundTaskSettings) _then;

/// Create a copy of BackgroundTaskSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? tasks = null,}) {
  return _then(_BackgroundTaskSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<BackgroundTaskConfig>,
  ));
}


}

// dart format on
