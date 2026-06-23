// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PageSettingsModel {

 bool get showPageSizeSelector; bool get showGotoButton; bool get showScrollToTopBtn; int get defaultPageSize; List<int> get pageSizeOptions;
/// Create a copy of PageSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageSettingsModelCopyWith<PageSettingsModel> get copyWith => _$PageSettingsModelCopyWithImpl<PageSettingsModel>(this as PageSettingsModel, _$identity);

  /// Serializes this PageSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageSettingsModel&&(identical(other.showPageSizeSelector, showPageSizeSelector) || other.showPageSizeSelector == showPageSizeSelector)&&(identical(other.showGotoButton, showGotoButton) || other.showGotoButton == showGotoButton)&&(identical(other.showScrollToTopBtn, showScrollToTopBtn) || other.showScrollToTopBtn == showScrollToTopBtn)&&(identical(other.defaultPageSize, defaultPageSize) || other.defaultPageSize == defaultPageSize)&&const DeepCollectionEquality().equals(other.pageSizeOptions, pageSizeOptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showPageSizeSelector,showGotoButton,showScrollToTopBtn,defaultPageSize,const DeepCollectionEquality().hash(pageSizeOptions));

@override
String toString() {
  return 'PageSettingsModel(showPageSizeSelector: $showPageSizeSelector, showGotoButton: $showGotoButton, showScrollToTopBtn: $showScrollToTopBtn, defaultPageSize: $defaultPageSize, pageSizeOptions: $pageSizeOptions)';
}


}

/// @nodoc
abstract mixin class $PageSettingsModelCopyWith<$Res>  {
  factory $PageSettingsModelCopyWith(PageSettingsModel value, $Res Function(PageSettingsModel) _then) = _$PageSettingsModelCopyWithImpl;
@useResult
$Res call({
 bool showPageSizeSelector, bool showGotoButton, bool showScrollToTopBtn, int defaultPageSize, List<int> pageSizeOptions
});




}
/// @nodoc
class _$PageSettingsModelCopyWithImpl<$Res>
    implements $PageSettingsModelCopyWith<$Res> {
  _$PageSettingsModelCopyWithImpl(this._self, this._then);

  final PageSettingsModel _self;
  final $Res Function(PageSettingsModel) _then;

/// Create a copy of PageSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showPageSizeSelector = null,Object? showGotoButton = null,Object? showScrollToTopBtn = null,Object? defaultPageSize = null,Object? pageSizeOptions = null,}) {
  return _then(_self.copyWith(
showPageSizeSelector: null == showPageSizeSelector ? _self.showPageSizeSelector : showPageSizeSelector // ignore: cast_nullable_to_non_nullable
as bool,showGotoButton: null == showGotoButton ? _self.showGotoButton : showGotoButton // ignore: cast_nullable_to_non_nullable
as bool,showScrollToTopBtn: null == showScrollToTopBtn ? _self.showScrollToTopBtn : showScrollToTopBtn // ignore: cast_nullable_to_non_nullable
as bool,defaultPageSize: null == defaultPageSize ? _self.defaultPageSize : defaultPageSize // ignore: cast_nullable_to_non_nullable
as int,pageSizeOptions: null == pageSizeOptions ? _self.pageSizeOptions : pageSizeOptions // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [PageSettingsModel].
extension PageSettingsModelPatterns on PageSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _PageSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PageSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showPageSizeSelector,  bool showGotoButton,  bool showScrollToTopBtn,  int defaultPageSize,  List<int> pageSizeOptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageSettingsModel() when $default != null:
return $default(_that.showPageSizeSelector,_that.showGotoButton,_that.showScrollToTopBtn,_that.defaultPageSize,_that.pageSizeOptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showPageSizeSelector,  bool showGotoButton,  bool showScrollToTopBtn,  int defaultPageSize,  List<int> pageSizeOptions)  $default,) {final _that = this;
switch (_that) {
case _PageSettingsModel():
return $default(_that.showPageSizeSelector,_that.showGotoButton,_that.showScrollToTopBtn,_that.defaultPageSize,_that.pageSizeOptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showPageSizeSelector,  bool showGotoButton,  bool showScrollToTopBtn,  int defaultPageSize,  List<int> pageSizeOptions)?  $default,) {final _that = this;
switch (_that) {
case _PageSettingsModel() when $default != null:
return $default(_that.showPageSizeSelector,_that.showGotoButton,_that.showScrollToTopBtn,_that.defaultPageSize,_that.pageSizeOptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageSettingsModel implements PageSettingsModel {
  const _PageSettingsModel({this.showPageSizeSelector = true, this.showGotoButton = true, this.showScrollToTopBtn = true, this.defaultPageSize = 12, final  List<int> pageSizeOptions = const [12, 24, 36, 48]}): _pageSizeOptions = pageSizeOptions;
  factory _PageSettingsModel.fromJson(Map<String, dynamic> json) => _$PageSettingsModelFromJson(json);

@override@JsonKey() final  bool showPageSizeSelector;
@override@JsonKey() final  bool showGotoButton;
@override@JsonKey() final  bool showScrollToTopBtn;
@override@JsonKey() final  int defaultPageSize;
 final  List<int> _pageSizeOptions;
@override@JsonKey() List<int> get pageSizeOptions {
  if (_pageSizeOptions is EqualUnmodifiableListView) return _pageSizeOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pageSizeOptions);
}


/// Create a copy of PageSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageSettingsModelCopyWith<_PageSettingsModel> get copyWith => __$PageSettingsModelCopyWithImpl<_PageSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageSettingsModel&&(identical(other.showPageSizeSelector, showPageSizeSelector) || other.showPageSizeSelector == showPageSizeSelector)&&(identical(other.showGotoButton, showGotoButton) || other.showGotoButton == showGotoButton)&&(identical(other.showScrollToTopBtn, showScrollToTopBtn) || other.showScrollToTopBtn == showScrollToTopBtn)&&(identical(other.defaultPageSize, defaultPageSize) || other.defaultPageSize == defaultPageSize)&&const DeepCollectionEquality().equals(other._pageSizeOptions, _pageSizeOptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showPageSizeSelector,showGotoButton,showScrollToTopBtn,defaultPageSize,const DeepCollectionEquality().hash(_pageSizeOptions));

@override
String toString() {
  return 'PageSettingsModel(showPageSizeSelector: $showPageSizeSelector, showGotoButton: $showGotoButton, showScrollToTopBtn: $showScrollToTopBtn, defaultPageSize: $defaultPageSize, pageSizeOptions: $pageSizeOptions)';
}


}

/// @nodoc
abstract mixin class _$PageSettingsModelCopyWith<$Res> implements $PageSettingsModelCopyWith<$Res> {
  factory _$PageSettingsModelCopyWith(_PageSettingsModel value, $Res Function(_PageSettingsModel) _then) = __$PageSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 bool showPageSizeSelector, bool showGotoButton, bool showScrollToTopBtn, int defaultPageSize, List<int> pageSizeOptions
});




}
/// @nodoc
class __$PageSettingsModelCopyWithImpl<$Res>
    implements _$PageSettingsModelCopyWith<$Res> {
  __$PageSettingsModelCopyWithImpl(this._self, this._then);

  final _PageSettingsModel _self;
  final $Res Function(_PageSettingsModel) _then;

/// Create a copy of PageSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showPageSizeSelector = null,Object? showGotoButton = null,Object? showScrollToTopBtn = null,Object? defaultPageSize = null,Object? pageSizeOptions = null,}) {
  return _then(_PageSettingsModel(
showPageSizeSelector: null == showPageSizeSelector ? _self.showPageSizeSelector : showPageSizeSelector // ignore: cast_nullable_to_non_nullable
as bool,showGotoButton: null == showGotoButton ? _self.showGotoButton : showGotoButton // ignore: cast_nullable_to_non_nullable
as bool,showScrollToTopBtn: null == showScrollToTopBtn ? _self.showScrollToTopBtn : showScrollToTopBtn // ignore: cast_nullable_to_non_nullable
as bool,defaultPageSize: null == defaultPageSize ? _self.defaultPageSize : defaultPageSize // ignore: cast_nullable_to_non_nullable
as int,pageSizeOptions: null == pageSizeOptions ? _self._pageSizeOptions : pageSizeOptions // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
