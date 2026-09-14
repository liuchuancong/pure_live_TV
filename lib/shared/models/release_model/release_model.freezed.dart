// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'release_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReleaseModel {

 String get version; String get title; String get date; String get github; AuthorModel get author; String get changeLog; List<ReleaseFileModel> get files;
/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseModelCopyWith<ReleaseModel> get copyWith => _$ReleaseModelCopyWithImpl<ReleaseModel>(this as ReleaseModel, _$identity);

  /// Serializes this ReleaseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseModel&&(identical(other.version, version) || other.version == version)&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.github, github) || other.github == github)&&(identical(other.author, author) || other.author == author)&&(identical(other.changeLog, changeLog) || other.changeLog == changeLog)&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,title,date,github,author,changeLog,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'ReleaseModel(version: $version, title: $title, date: $date, github: $github, author: $author, changeLog: $changeLog, files: $files)';
}


}

/// @nodoc
abstract mixin class $ReleaseModelCopyWith<$Res>  {
  factory $ReleaseModelCopyWith(ReleaseModel value, $Res Function(ReleaseModel) _then) = _$ReleaseModelCopyWithImpl;
@useResult
$Res call({
 String version, String title, String date, String github, AuthorModel author, String changeLog, List<ReleaseFileModel> files
});


$AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class _$ReleaseModelCopyWithImpl<$Res>
    implements $ReleaseModelCopyWith<$Res> {
  _$ReleaseModelCopyWithImpl(this._self, this._then);

  final ReleaseModel _self;
  final $Res Function(ReleaseModel) _then;

/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? title = null,Object? date = null,Object? github = null,Object? author = null,Object? changeLog = null,Object? files = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,github: null == github ? _self.github : github // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,changeLog: null == changeLog ? _self.changeLog : changeLog // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<ReleaseFileModel>,
  ));
}
/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReleaseModel].
extension ReleaseModelPatterns on ReleaseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseModel value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String title,  String date,  String github,  AuthorModel author,  String changeLog,  List<ReleaseFileModel> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseModel() when $default != null:
return $default(_that.version,_that.title,_that.date,_that.github,_that.author,_that.changeLog,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String title,  String date,  String github,  AuthorModel author,  String changeLog,  List<ReleaseFileModel> files)  $default,) {final _that = this;
switch (_that) {
case _ReleaseModel():
return $default(_that.version,_that.title,_that.date,_that.github,_that.author,_that.changeLog,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String title,  String date,  String github,  AuthorModel author,  String changeLog,  List<ReleaseFileModel> files)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseModel() when $default != null:
return $default(_that.version,_that.title,_that.date,_that.github,_that.author,_that.changeLog,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseModel implements ReleaseModel {
  const _ReleaseModel({this.version = '', this.title = '', this.date = '', this.github = '', required this.author, this.changeLog = '', final  List<ReleaseFileModel> files = const []}): _files = files;
  factory _ReleaseModel.fromJson(Map<String, dynamic> json) => _$ReleaseModelFromJson(json);

@override@JsonKey() final  String version;
@override@JsonKey() final  String title;
@override@JsonKey() final  String date;
@override@JsonKey() final  String github;
@override final  AuthorModel author;
@override@JsonKey() final  String changeLog;
 final  List<ReleaseFileModel> _files;
@override@JsonKey() List<ReleaseFileModel> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseModelCopyWith<_ReleaseModel> get copyWith => __$ReleaseModelCopyWithImpl<_ReleaseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseModel&&(identical(other.version, version) || other.version == version)&&(identical(other.title, title) || other.title == title)&&(identical(other.date, date) || other.date == date)&&(identical(other.github, github) || other.github == github)&&(identical(other.author, author) || other.author == author)&&(identical(other.changeLog, changeLog) || other.changeLog == changeLog)&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,title,date,github,author,changeLog,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'ReleaseModel(version: $version, title: $title, date: $date, github: $github, author: $author, changeLog: $changeLog, files: $files)';
}


}

/// @nodoc
abstract mixin class _$ReleaseModelCopyWith<$Res> implements $ReleaseModelCopyWith<$Res> {
  factory _$ReleaseModelCopyWith(_ReleaseModel value, $Res Function(_ReleaseModel) _then) = __$ReleaseModelCopyWithImpl;
@override @useResult
$Res call({
 String version, String title, String date, String github, AuthorModel author, String changeLog, List<ReleaseFileModel> files
});


@override $AuthorModelCopyWith<$Res> get author;

}
/// @nodoc
class __$ReleaseModelCopyWithImpl<$Res>
    implements _$ReleaseModelCopyWith<$Res> {
  __$ReleaseModelCopyWithImpl(this._self, this._then);

  final _ReleaseModel _self;
  final $Res Function(_ReleaseModel) _then;

/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? title = null,Object? date = null,Object? github = null,Object? author = null,Object? changeLog = null,Object? files = null,}) {
  return _then(_ReleaseModel(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,github: null == github ? _self.github : github // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as AuthorModel,changeLog: null == changeLog ? _self.changeLog : changeLog // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<ReleaseFileModel>,
  ));
}

/// Create a copy of ReleaseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<$Res> get author {
  
  return $AuthorModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$AuthorModel {

 String get name; String get avatar; String get profile;
/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthorModelCopyWith<AuthorModel> get copyWith => _$AuthorModelCopyWithImpl<AuthorModel>(this as AuthorModel, _$identity);

  /// Serializes this AuthorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthorModel&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.profile, profile) || other.profile == profile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatar,profile);

@override
String toString() {
  return 'AuthorModel(name: $name, avatar: $avatar, profile: $profile)';
}


}

/// @nodoc
abstract mixin class $AuthorModelCopyWith<$Res>  {
  factory $AuthorModelCopyWith(AuthorModel value, $Res Function(AuthorModel) _then) = _$AuthorModelCopyWithImpl;
@useResult
$Res call({
 String name, String avatar, String profile
});




}
/// @nodoc
class _$AuthorModelCopyWithImpl<$Res>
    implements $AuthorModelCopyWith<$Res> {
  _$AuthorModelCopyWithImpl(this._self, this._then);

  final AuthorModel _self;
  final $Res Function(AuthorModel) _then;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? avatar = null,Object? profile = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthorModel].
extension AuthorModelPatterns on AuthorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthorModel value)  $default,){
final _that = this;
switch (_that) {
case _AuthorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthorModel value)?  $default,){
final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String avatar,  String profile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
return $default(_that.name,_that.avatar,_that.profile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String avatar,  String profile)  $default,) {final _that = this;
switch (_that) {
case _AuthorModel():
return $default(_that.name,_that.avatar,_that.profile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String avatar,  String profile)?  $default,) {final _that = this;
switch (_that) {
case _AuthorModel() when $default != null:
return $default(_that.name,_that.avatar,_that.profile);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthorModel implements AuthorModel {
  const _AuthorModel({this.name = '', this.avatar = '', this.profile = ''});
  factory _AuthorModel.fromJson(Map<String, dynamic> json) => _$AuthorModelFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String avatar;
@override@JsonKey() final  String profile;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthorModelCopyWith<_AuthorModel> get copyWith => __$AuthorModelCopyWithImpl<_AuthorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthorModel&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.profile, profile) || other.profile == profile));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatar,profile);

@override
String toString() {
  return 'AuthorModel(name: $name, avatar: $avatar, profile: $profile)';
}


}

/// @nodoc
abstract mixin class _$AuthorModelCopyWith<$Res> implements $AuthorModelCopyWith<$Res> {
  factory _$AuthorModelCopyWith(_AuthorModel value, $Res Function(_AuthorModel) _then) = __$AuthorModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String avatar, String profile
});




}
/// @nodoc
class __$AuthorModelCopyWithImpl<$Res>
    implements _$AuthorModelCopyWith<$Res> {
  __$AuthorModelCopyWithImpl(this._self, this._then);

  final _AuthorModel _self;
  final $Res Function(_AuthorModel) _then;

/// Create a copy of AuthorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? avatar = null,Object? profile = null,}) {
  return _then(_AuthorModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReleaseFileModel {

 String get name; String get size; int get downloads; String get url;
/// Create a copy of ReleaseFileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseFileModelCopyWith<ReleaseFileModel> get copyWith => _$ReleaseFileModelCopyWithImpl<ReleaseFileModel>(this as ReleaseFileModel, _$identity);

  /// Serializes this ReleaseFileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseFileModel&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.downloads, downloads) || other.downloads == downloads)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,size,downloads,url);

@override
String toString() {
  return 'ReleaseFileModel(name: $name, size: $size, downloads: $downloads, url: $url)';
}


}

/// @nodoc
abstract mixin class $ReleaseFileModelCopyWith<$Res>  {
  factory $ReleaseFileModelCopyWith(ReleaseFileModel value, $Res Function(ReleaseFileModel) _then) = _$ReleaseFileModelCopyWithImpl;
@useResult
$Res call({
 String name, String size, int downloads, String url
});




}
/// @nodoc
class _$ReleaseFileModelCopyWithImpl<$Res>
    implements $ReleaseFileModelCopyWith<$Res> {
  _$ReleaseFileModelCopyWithImpl(this._self, this._then);

  final ReleaseFileModel _self;
  final $Res Function(ReleaseFileModel) _then;

/// Create a copy of ReleaseFileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? size = null,Object? downloads = null,Object? url = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,downloads: null == downloads ? _self.downloads : downloads // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseFileModel].
extension ReleaseFileModelPatterns on ReleaseFileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseFileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseFileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseFileModel value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseFileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseFileModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseFileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String size,  int downloads,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseFileModel() when $default != null:
return $default(_that.name,_that.size,_that.downloads,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String size,  int downloads,  String url)  $default,) {final _that = this;
switch (_that) {
case _ReleaseFileModel():
return $default(_that.name,_that.size,_that.downloads,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String size,  int downloads,  String url)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseFileModel() when $default != null:
return $default(_that.name,_that.size,_that.downloads,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseFileModel implements ReleaseFileModel {
  const _ReleaseFileModel({this.name = '', this.size = '', this.downloads = 0, this.url = ''});
  factory _ReleaseFileModel.fromJson(Map<String, dynamic> json) => _$ReleaseFileModelFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String size;
@override@JsonKey() final  int downloads;
@override@JsonKey() final  String url;

/// Create a copy of ReleaseFileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseFileModelCopyWith<_ReleaseFileModel> get copyWith => __$ReleaseFileModelCopyWithImpl<_ReleaseFileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseFileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseFileModel&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.downloads, downloads) || other.downloads == downloads)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,size,downloads,url);

@override
String toString() {
  return 'ReleaseFileModel(name: $name, size: $size, downloads: $downloads, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ReleaseFileModelCopyWith<$Res> implements $ReleaseFileModelCopyWith<$Res> {
  factory _$ReleaseFileModelCopyWith(_ReleaseFileModel value, $Res Function(_ReleaseFileModel) _then) = __$ReleaseFileModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String size, int downloads, String url
});




}
/// @nodoc
class __$ReleaseFileModelCopyWithImpl<$Res>
    implements _$ReleaseFileModelCopyWith<$Res> {
  __$ReleaseFileModelCopyWithImpl(this._self, this._then);

  final _ReleaseFileModel _self;
  final $Res Function(_ReleaseFileModel) _then;

/// Create a copy of ReleaseFileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? size = null,Object? downloads = null,Object? url = null,}) {
  return _then(_ReleaseFileModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,downloads: null == downloads ? _self.downloads : downloads // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
