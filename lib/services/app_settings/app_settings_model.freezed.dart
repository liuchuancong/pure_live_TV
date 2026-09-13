// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettingsModel {

 int get autoRefreshTime; bool get enableDenseFavorites; bool get enableBackgroundPlay; bool get enableAsmrSleepMode; int get asmrSleepMinutes; bool get enableRotateScreen; bool get enableScreenKeepOn; bool get enableAutoCheckUpdate; bool get useGitHubOriginForUpdates; bool get enableFullScreenDefault; bool get showSplashPage; String get refreshRateMode; bool get preferRealOnlineCounts; List<String> get realOnlinePlatforms; int get audienceMetricMigration; bool get enableMultiView; bool get enableNewWindowPlay; List<String> get savedMenuIds;
/// Create a copy of AppSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsModelCopyWith<AppSettingsModel> get copyWith => _$AppSettingsModelCopyWithImpl<AppSettingsModel>(this as AppSettingsModel, _$identity);

  /// Serializes this AppSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettingsModel&&(identical(other.autoRefreshTime, autoRefreshTime) || other.autoRefreshTime == autoRefreshTime)&&(identical(other.enableDenseFavorites, enableDenseFavorites) || other.enableDenseFavorites == enableDenseFavorites)&&(identical(other.enableBackgroundPlay, enableBackgroundPlay) || other.enableBackgroundPlay == enableBackgroundPlay)&&(identical(other.enableAsmrSleepMode, enableAsmrSleepMode) || other.enableAsmrSleepMode == enableAsmrSleepMode)&&(identical(other.asmrSleepMinutes, asmrSleepMinutes) || other.asmrSleepMinutes == asmrSleepMinutes)&&(identical(other.enableRotateScreen, enableRotateScreen) || other.enableRotateScreen == enableRotateScreen)&&(identical(other.enableScreenKeepOn, enableScreenKeepOn) || other.enableScreenKeepOn == enableScreenKeepOn)&&(identical(other.enableAutoCheckUpdate, enableAutoCheckUpdate) || other.enableAutoCheckUpdate == enableAutoCheckUpdate)&&(identical(other.useGitHubOriginForUpdates, useGitHubOriginForUpdates) || other.useGitHubOriginForUpdates == useGitHubOriginForUpdates)&&(identical(other.enableFullScreenDefault, enableFullScreenDefault) || other.enableFullScreenDefault == enableFullScreenDefault)&&(identical(other.showSplashPage, showSplashPage) || other.showSplashPage == showSplashPage)&&(identical(other.refreshRateMode, refreshRateMode) || other.refreshRateMode == refreshRateMode)&&(identical(other.preferRealOnlineCounts, preferRealOnlineCounts) || other.preferRealOnlineCounts == preferRealOnlineCounts)&&const DeepCollectionEquality().equals(other.realOnlinePlatforms, realOnlinePlatforms)&&(identical(other.audienceMetricMigration, audienceMetricMigration) || other.audienceMetricMigration == audienceMetricMigration)&&(identical(other.enableMultiView, enableMultiView) || other.enableMultiView == enableMultiView)&&(identical(other.enableNewWindowPlay, enableNewWindowPlay) || other.enableNewWindowPlay == enableNewWindowPlay)&&const DeepCollectionEquality().equals(other.savedMenuIds, savedMenuIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoRefreshTime,enableDenseFavorites,enableBackgroundPlay,enableAsmrSleepMode,asmrSleepMinutes,enableRotateScreen,enableScreenKeepOn,enableAutoCheckUpdate,useGitHubOriginForUpdates,enableFullScreenDefault,showSplashPage,refreshRateMode,preferRealOnlineCounts,const DeepCollectionEquality().hash(realOnlinePlatforms),audienceMetricMigration,enableMultiView,enableNewWindowPlay,const DeepCollectionEquality().hash(savedMenuIds));

@override
String toString() {
  return 'AppSettingsModel(autoRefreshTime: $autoRefreshTime, enableDenseFavorites: $enableDenseFavorites, enableBackgroundPlay: $enableBackgroundPlay, enableAsmrSleepMode: $enableAsmrSleepMode, asmrSleepMinutes: $asmrSleepMinutes, enableRotateScreen: $enableRotateScreen, enableScreenKeepOn: $enableScreenKeepOn, enableAutoCheckUpdate: $enableAutoCheckUpdate, useGitHubOriginForUpdates: $useGitHubOriginForUpdates, enableFullScreenDefault: $enableFullScreenDefault, showSplashPage: $showSplashPage, refreshRateMode: $refreshRateMode, preferRealOnlineCounts: $preferRealOnlineCounts, realOnlinePlatforms: $realOnlinePlatforms, audienceMetricMigration: $audienceMetricMigration, enableMultiView: $enableMultiView, enableNewWindowPlay: $enableNewWindowPlay, savedMenuIds: $savedMenuIds)';
}


}

/// @nodoc
abstract mixin class $AppSettingsModelCopyWith<$Res>  {
  factory $AppSettingsModelCopyWith(AppSettingsModel value, $Res Function(AppSettingsModel) _then) = _$AppSettingsModelCopyWithImpl;
@useResult
$Res call({
 int autoRefreshTime, bool enableDenseFavorites, bool enableBackgroundPlay, bool enableAsmrSleepMode, int asmrSleepMinutes, bool enableRotateScreen, bool enableScreenKeepOn, bool enableAutoCheckUpdate, bool useGitHubOriginForUpdates, bool enableFullScreenDefault, bool showSplashPage, String refreshRateMode, bool preferRealOnlineCounts, List<String> realOnlinePlatforms, int audienceMetricMigration, bool enableMultiView, bool enableNewWindowPlay, List<String> savedMenuIds
});




}
/// @nodoc
class _$AppSettingsModelCopyWithImpl<$Res>
    implements $AppSettingsModelCopyWith<$Res> {
  _$AppSettingsModelCopyWithImpl(this._self, this._then);

  final AppSettingsModel _self;
  final $Res Function(AppSettingsModel) _then;

/// Create a copy of AppSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? autoRefreshTime = null,Object? enableDenseFavorites = null,Object? enableBackgroundPlay = null,Object? enableAsmrSleepMode = null,Object? asmrSleepMinutes = null,Object? enableRotateScreen = null,Object? enableScreenKeepOn = null,Object? enableAutoCheckUpdate = null,Object? useGitHubOriginForUpdates = null,Object? enableFullScreenDefault = null,Object? showSplashPage = null,Object? refreshRateMode = null,Object? preferRealOnlineCounts = null,Object? realOnlinePlatforms = null,Object? audienceMetricMigration = null,Object? enableMultiView = null,Object? enableNewWindowPlay = null,Object? savedMenuIds = null,}) {
  return _then(_self.copyWith(
autoRefreshTime: null == autoRefreshTime ? _self.autoRefreshTime : autoRefreshTime // ignore: cast_nullable_to_non_nullable
as int,enableDenseFavorites: null == enableDenseFavorites ? _self.enableDenseFavorites : enableDenseFavorites // ignore: cast_nullable_to_non_nullable
as bool,enableBackgroundPlay: null == enableBackgroundPlay ? _self.enableBackgroundPlay : enableBackgroundPlay // ignore: cast_nullable_to_non_nullable
as bool,enableAsmrSleepMode: null == enableAsmrSleepMode ? _self.enableAsmrSleepMode : enableAsmrSleepMode // ignore: cast_nullable_to_non_nullable
as bool,asmrSleepMinutes: null == asmrSleepMinutes ? _self.asmrSleepMinutes : asmrSleepMinutes // ignore: cast_nullable_to_non_nullable
as int,enableRotateScreen: null == enableRotateScreen ? _self.enableRotateScreen : enableRotateScreen // ignore: cast_nullable_to_non_nullable
as bool,enableScreenKeepOn: null == enableScreenKeepOn ? _self.enableScreenKeepOn : enableScreenKeepOn // ignore: cast_nullable_to_non_nullable
as bool,enableAutoCheckUpdate: null == enableAutoCheckUpdate ? _self.enableAutoCheckUpdate : enableAutoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,useGitHubOriginForUpdates: null == useGitHubOriginForUpdates ? _self.useGitHubOriginForUpdates : useGitHubOriginForUpdates // ignore: cast_nullable_to_non_nullable
as bool,enableFullScreenDefault: null == enableFullScreenDefault ? _self.enableFullScreenDefault : enableFullScreenDefault // ignore: cast_nullable_to_non_nullable
as bool,showSplashPage: null == showSplashPage ? _self.showSplashPage : showSplashPage // ignore: cast_nullable_to_non_nullable
as bool,refreshRateMode: null == refreshRateMode ? _self.refreshRateMode : refreshRateMode // ignore: cast_nullable_to_non_nullable
as String,preferRealOnlineCounts: null == preferRealOnlineCounts ? _self.preferRealOnlineCounts : preferRealOnlineCounts // ignore: cast_nullable_to_non_nullable
as bool,realOnlinePlatforms: null == realOnlinePlatforms ? _self.realOnlinePlatforms : realOnlinePlatforms // ignore: cast_nullable_to_non_nullable
as List<String>,audienceMetricMigration: null == audienceMetricMigration ? _self.audienceMetricMigration : audienceMetricMigration // ignore: cast_nullable_to_non_nullable
as int,enableMultiView: null == enableMultiView ? _self.enableMultiView : enableMultiView // ignore: cast_nullable_to_non_nullable
as bool,enableNewWindowPlay: null == enableNewWindowPlay ? _self.enableNewWindowPlay : enableNewWindowPlay // ignore: cast_nullable_to_non_nullable
as bool,savedMenuIds: null == savedMenuIds ? _self.savedMenuIds : savedMenuIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettingsModel].
extension AppSettingsModelPatterns on AppSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _AppSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int autoRefreshTime,  bool enableDenseFavorites,  bool enableBackgroundPlay,  bool enableAsmrSleepMode,  int asmrSleepMinutes,  bool enableRotateScreen,  bool enableScreenKeepOn,  bool enableAutoCheckUpdate,  bool useGitHubOriginForUpdates,  bool enableFullScreenDefault,  bool showSplashPage,  String refreshRateMode,  bool preferRealOnlineCounts,  List<String> realOnlinePlatforms,  int audienceMetricMigration,  bool enableMultiView,  bool enableNewWindowPlay,  List<String> savedMenuIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettingsModel() when $default != null:
return $default(_that.autoRefreshTime,_that.enableDenseFavorites,_that.enableBackgroundPlay,_that.enableAsmrSleepMode,_that.asmrSleepMinutes,_that.enableRotateScreen,_that.enableScreenKeepOn,_that.enableAutoCheckUpdate,_that.useGitHubOriginForUpdates,_that.enableFullScreenDefault,_that.showSplashPage,_that.refreshRateMode,_that.preferRealOnlineCounts,_that.realOnlinePlatforms,_that.audienceMetricMigration,_that.enableMultiView,_that.enableNewWindowPlay,_that.savedMenuIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int autoRefreshTime,  bool enableDenseFavorites,  bool enableBackgroundPlay,  bool enableAsmrSleepMode,  int asmrSleepMinutes,  bool enableRotateScreen,  bool enableScreenKeepOn,  bool enableAutoCheckUpdate,  bool useGitHubOriginForUpdates,  bool enableFullScreenDefault,  bool showSplashPage,  String refreshRateMode,  bool preferRealOnlineCounts,  List<String> realOnlinePlatforms,  int audienceMetricMigration,  bool enableMultiView,  bool enableNewWindowPlay,  List<String> savedMenuIds)  $default,) {final _that = this;
switch (_that) {
case _AppSettingsModel():
return $default(_that.autoRefreshTime,_that.enableDenseFavorites,_that.enableBackgroundPlay,_that.enableAsmrSleepMode,_that.asmrSleepMinutes,_that.enableRotateScreen,_that.enableScreenKeepOn,_that.enableAutoCheckUpdate,_that.useGitHubOriginForUpdates,_that.enableFullScreenDefault,_that.showSplashPage,_that.refreshRateMode,_that.preferRealOnlineCounts,_that.realOnlinePlatforms,_that.audienceMetricMigration,_that.enableMultiView,_that.enableNewWindowPlay,_that.savedMenuIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int autoRefreshTime,  bool enableDenseFavorites,  bool enableBackgroundPlay,  bool enableAsmrSleepMode,  int asmrSleepMinutes,  bool enableRotateScreen,  bool enableScreenKeepOn,  bool enableAutoCheckUpdate,  bool useGitHubOriginForUpdates,  bool enableFullScreenDefault,  bool showSplashPage,  String refreshRateMode,  bool preferRealOnlineCounts,  List<String> realOnlinePlatforms,  int audienceMetricMigration,  bool enableMultiView,  bool enableNewWindowPlay,  List<String> savedMenuIds)?  $default,) {final _that = this;
switch (_that) {
case _AppSettingsModel() when $default != null:
return $default(_that.autoRefreshTime,_that.enableDenseFavorites,_that.enableBackgroundPlay,_that.enableAsmrSleepMode,_that.asmrSleepMinutes,_that.enableRotateScreen,_that.enableScreenKeepOn,_that.enableAutoCheckUpdate,_that.useGitHubOriginForUpdates,_that.enableFullScreenDefault,_that.showSplashPage,_that.refreshRateMode,_that.preferRealOnlineCounts,_that.realOnlinePlatforms,_that.audienceMetricMigration,_that.enableMultiView,_that.enableNewWindowPlay,_that.savedMenuIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettingsModel implements AppSettingsModel {
  const _AppSettingsModel({this.autoRefreshTime = 3, this.enableDenseFavorites = true, this.enableBackgroundPlay = false, this.enableAsmrSleepMode = false, this.asmrSleepMinutes = 60, this.enableRotateScreen = false, this.enableScreenKeepOn = true, this.enableAutoCheckUpdate = true, this.useGitHubOriginForUpdates = false, this.enableFullScreenDefault = false, this.showSplashPage = true, this.refreshRateMode = '', this.preferRealOnlineCounts = false, final  List<String> realOnlinePlatforms = const [], this.audienceMetricMigration = 0, this.enableMultiView = true, this.enableNewWindowPlay = true, final  List<String> savedMenuIds = const []}): _realOnlinePlatforms = realOnlinePlatforms,_savedMenuIds = savedMenuIds;
  factory _AppSettingsModel.fromJson(Map<String, dynamic> json) => _$AppSettingsModelFromJson(json);

@override@JsonKey() final  int autoRefreshTime;
@override@JsonKey() final  bool enableDenseFavorites;
@override@JsonKey() final  bool enableBackgroundPlay;
@override@JsonKey() final  bool enableAsmrSleepMode;
@override@JsonKey() final  int asmrSleepMinutes;
@override@JsonKey() final  bool enableRotateScreen;
@override@JsonKey() final  bool enableScreenKeepOn;
@override@JsonKey() final  bool enableAutoCheckUpdate;
@override@JsonKey() final  bool useGitHubOriginForUpdates;
@override@JsonKey() final  bool enableFullScreenDefault;
@override@JsonKey() final  bool showSplashPage;
@override@JsonKey() final  String refreshRateMode;
@override@JsonKey() final  bool preferRealOnlineCounts;
 final  List<String> _realOnlinePlatforms;
@override@JsonKey() List<String> get realOnlinePlatforms {
  if (_realOnlinePlatforms is EqualUnmodifiableListView) return _realOnlinePlatforms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_realOnlinePlatforms);
}

@override@JsonKey() final  int audienceMetricMigration;
@override@JsonKey() final  bool enableMultiView;
@override@JsonKey() final  bool enableNewWindowPlay;
 final  List<String> _savedMenuIds;
@override@JsonKey() List<String> get savedMenuIds {
  if (_savedMenuIds is EqualUnmodifiableListView) return _savedMenuIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedMenuIds);
}


/// Create a copy of AppSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsModelCopyWith<_AppSettingsModel> get copyWith => __$AppSettingsModelCopyWithImpl<_AppSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettingsModel&&(identical(other.autoRefreshTime, autoRefreshTime) || other.autoRefreshTime == autoRefreshTime)&&(identical(other.enableDenseFavorites, enableDenseFavorites) || other.enableDenseFavorites == enableDenseFavorites)&&(identical(other.enableBackgroundPlay, enableBackgroundPlay) || other.enableBackgroundPlay == enableBackgroundPlay)&&(identical(other.enableAsmrSleepMode, enableAsmrSleepMode) || other.enableAsmrSleepMode == enableAsmrSleepMode)&&(identical(other.asmrSleepMinutes, asmrSleepMinutes) || other.asmrSleepMinutes == asmrSleepMinutes)&&(identical(other.enableRotateScreen, enableRotateScreen) || other.enableRotateScreen == enableRotateScreen)&&(identical(other.enableScreenKeepOn, enableScreenKeepOn) || other.enableScreenKeepOn == enableScreenKeepOn)&&(identical(other.enableAutoCheckUpdate, enableAutoCheckUpdate) || other.enableAutoCheckUpdate == enableAutoCheckUpdate)&&(identical(other.useGitHubOriginForUpdates, useGitHubOriginForUpdates) || other.useGitHubOriginForUpdates == useGitHubOriginForUpdates)&&(identical(other.enableFullScreenDefault, enableFullScreenDefault) || other.enableFullScreenDefault == enableFullScreenDefault)&&(identical(other.showSplashPage, showSplashPage) || other.showSplashPage == showSplashPage)&&(identical(other.refreshRateMode, refreshRateMode) || other.refreshRateMode == refreshRateMode)&&(identical(other.preferRealOnlineCounts, preferRealOnlineCounts) || other.preferRealOnlineCounts == preferRealOnlineCounts)&&const DeepCollectionEquality().equals(other._realOnlinePlatforms, _realOnlinePlatforms)&&(identical(other.audienceMetricMigration, audienceMetricMigration) || other.audienceMetricMigration == audienceMetricMigration)&&(identical(other.enableMultiView, enableMultiView) || other.enableMultiView == enableMultiView)&&(identical(other.enableNewWindowPlay, enableNewWindowPlay) || other.enableNewWindowPlay == enableNewWindowPlay)&&const DeepCollectionEquality().equals(other._savedMenuIds, _savedMenuIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoRefreshTime,enableDenseFavorites,enableBackgroundPlay,enableAsmrSleepMode,asmrSleepMinutes,enableRotateScreen,enableScreenKeepOn,enableAutoCheckUpdate,useGitHubOriginForUpdates,enableFullScreenDefault,showSplashPage,refreshRateMode,preferRealOnlineCounts,const DeepCollectionEquality().hash(_realOnlinePlatforms),audienceMetricMigration,enableMultiView,enableNewWindowPlay,const DeepCollectionEquality().hash(_savedMenuIds));

@override
String toString() {
  return 'AppSettingsModel(autoRefreshTime: $autoRefreshTime, enableDenseFavorites: $enableDenseFavorites, enableBackgroundPlay: $enableBackgroundPlay, enableAsmrSleepMode: $enableAsmrSleepMode, asmrSleepMinutes: $asmrSleepMinutes, enableRotateScreen: $enableRotateScreen, enableScreenKeepOn: $enableScreenKeepOn, enableAutoCheckUpdate: $enableAutoCheckUpdate, useGitHubOriginForUpdates: $useGitHubOriginForUpdates, enableFullScreenDefault: $enableFullScreenDefault, showSplashPage: $showSplashPage, refreshRateMode: $refreshRateMode, preferRealOnlineCounts: $preferRealOnlineCounts, realOnlinePlatforms: $realOnlinePlatforms, audienceMetricMigration: $audienceMetricMigration, enableMultiView: $enableMultiView, enableNewWindowPlay: $enableNewWindowPlay, savedMenuIds: $savedMenuIds)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsModelCopyWith<$Res> implements $AppSettingsModelCopyWith<$Res> {
  factory _$AppSettingsModelCopyWith(_AppSettingsModel value, $Res Function(_AppSettingsModel) _then) = __$AppSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 int autoRefreshTime, bool enableDenseFavorites, bool enableBackgroundPlay, bool enableAsmrSleepMode, int asmrSleepMinutes, bool enableRotateScreen, bool enableScreenKeepOn, bool enableAutoCheckUpdate, bool useGitHubOriginForUpdates, bool enableFullScreenDefault, bool showSplashPage, String refreshRateMode, bool preferRealOnlineCounts, List<String> realOnlinePlatforms, int audienceMetricMigration, bool enableMultiView, bool enableNewWindowPlay, List<String> savedMenuIds
});




}
/// @nodoc
class __$AppSettingsModelCopyWithImpl<$Res>
    implements _$AppSettingsModelCopyWith<$Res> {
  __$AppSettingsModelCopyWithImpl(this._self, this._then);

  final _AppSettingsModel _self;
  final $Res Function(_AppSettingsModel) _then;

/// Create a copy of AppSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? autoRefreshTime = null,Object? enableDenseFavorites = null,Object? enableBackgroundPlay = null,Object? enableAsmrSleepMode = null,Object? asmrSleepMinutes = null,Object? enableRotateScreen = null,Object? enableScreenKeepOn = null,Object? enableAutoCheckUpdate = null,Object? useGitHubOriginForUpdates = null,Object? enableFullScreenDefault = null,Object? showSplashPage = null,Object? refreshRateMode = null,Object? preferRealOnlineCounts = null,Object? realOnlinePlatforms = null,Object? audienceMetricMigration = null,Object? enableMultiView = null,Object? enableNewWindowPlay = null,Object? savedMenuIds = null,}) {
  return _then(_AppSettingsModel(
autoRefreshTime: null == autoRefreshTime ? _self.autoRefreshTime : autoRefreshTime // ignore: cast_nullable_to_non_nullable
as int,enableDenseFavorites: null == enableDenseFavorites ? _self.enableDenseFavorites : enableDenseFavorites // ignore: cast_nullable_to_non_nullable
as bool,enableBackgroundPlay: null == enableBackgroundPlay ? _self.enableBackgroundPlay : enableBackgroundPlay // ignore: cast_nullable_to_non_nullable
as bool,enableAsmrSleepMode: null == enableAsmrSleepMode ? _self.enableAsmrSleepMode : enableAsmrSleepMode // ignore: cast_nullable_to_non_nullable
as bool,asmrSleepMinutes: null == asmrSleepMinutes ? _self.asmrSleepMinutes : asmrSleepMinutes // ignore: cast_nullable_to_non_nullable
as int,enableRotateScreen: null == enableRotateScreen ? _self.enableRotateScreen : enableRotateScreen // ignore: cast_nullable_to_non_nullable
as bool,enableScreenKeepOn: null == enableScreenKeepOn ? _self.enableScreenKeepOn : enableScreenKeepOn // ignore: cast_nullable_to_non_nullable
as bool,enableAutoCheckUpdate: null == enableAutoCheckUpdate ? _self.enableAutoCheckUpdate : enableAutoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,useGitHubOriginForUpdates: null == useGitHubOriginForUpdates ? _self.useGitHubOriginForUpdates : useGitHubOriginForUpdates // ignore: cast_nullable_to_non_nullable
as bool,enableFullScreenDefault: null == enableFullScreenDefault ? _self.enableFullScreenDefault : enableFullScreenDefault // ignore: cast_nullable_to_non_nullable
as bool,showSplashPage: null == showSplashPage ? _self.showSplashPage : showSplashPage // ignore: cast_nullable_to_non_nullable
as bool,refreshRateMode: null == refreshRateMode ? _self.refreshRateMode : refreshRateMode // ignore: cast_nullable_to_non_nullable
as String,preferRealOnlineCounts: null == preferRealOnlineCounts ? _self.preferRealOnlineCounts : preferRealOnlineCounts // ignore: cast_nullable_to_non_nullable
as bool,realOnlinePlatforms: null == realOnlinePlatforms ? _self._realOnlinePlatforms : realOnlinePlatforms // ignore: cast_nullable_to_non_nullable
as List<String>,audienceMetricMigration: null == audienceMetricMigration ? _self.audienceMetricMigration : audienceMetricMigration // ignore: cast_nullable_to_non_nullable
as int,enableMultiView: null == enableMultiView ? _self.enableMultiView : enableMultiView // ignore: cast_nullable_to_non_nullable
as bool,enableNewWindowPlay: null == enableNewWindowPlay ? _self.enableNewWindowPlay : enableNewWindowPlay // ignore: cast_nullable_to_non_nullable
as bool,savedMenuIds: null == savedMenuIds ? _self._savedMenuIds : savedMenuIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
