// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveMessageColor {

 int get r; int get g; int get b;
/// Create a copy of LiveMessageColor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveMessageColorCopyWith<LiveMessageColor> get copyWith => _$LiveMessageColorCopyWithImpl<LiveMessageColor>(this as LiveMessageColor, _$identity);

  /// Serializes this LiveMessageColor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveMessageColor&&(identical(other.r, r) || other.r == r)&&(identical(other.g, g) || other.g == g)&&(identical(other.b, b) || other.b == b));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,r,g,b);



}

/// @nodoc
abstract mixin class $LiveMessageColorCopyWith<$Res>  {
  factory $LiveMessageColorCopyWith(LiveMessageColor value, $Res Function(LiveMessageColor) _then) = _$LiveMessageColorCopyWithImpl;
@useResult
$Res call({
 int r, int g, int b
});




}
/// @nodoc
class _$LiveMessageColorCopyWithImpl<$Res>
    implements $LiveMessageColorCopyWith<$Res> {
  _$LiveMessageColorCopyWithImpl(this._self, this._then);

  final LiveMessageColor _self;
  final $Res Function(LiveMessageColor) _then;

/// Create a copy of LiveMessageColor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? r = null,Object? g = null,Object? b = null,}) {
  return _then(_self.copyWith(
r: null == r ? _self.r : r // ignore: cast_nullable_to_non_nullable
as int,g: null == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as int,b: null == b ? _self.b : b // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveMessageColor].
extension LiveMessageColorPatterns on LiveMessageColor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveMessageColor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveMessageColor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveMessageColor value)  $default,){
final _that = this;
switch (_that) {
case _LiveMessageColor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveMessageColor value)?  $default,){
final _that = this;
switch (_that) {
case _LiveMessageColor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int r,  int g,  int b)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveMessageColor() when $default != null:
return $default(_that.r,_that.g,_that.b);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int r,  int g,  int b)  $default,) {final _that = this;
switch (_that) {
case _LiveMessageColor():
return $default(_that.r,_that.g,_that.b);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int r,  int g,  int b)?  $default,) {final _that = this;
switch (_that) {
case _LiveMessageColor() when $default != null:
return $default(_that.r,_that.g,_that.b);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveMessageColor extends LiveMessageColor {
  const _LiveMessageColor({required this.r, required this.g, required this.b}): super._();
  factory _LiveMessageColor.fromJson(Map<String, dynamic> json) => _$LiveMessageColorFromJson(json);

@override final  int r;
@override final  int g;
@override final  int b;

/// Create a copy of LiveMessageColor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveMessageColorCopyWith<_LiveMessageColor> get copyWith => __$LiveMessageColorCopyWithImpl<_LiveMessageColor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveMessageColorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveMessageColor&&(identical(other.r, r) || other.r == r)&&(identical(other.g, g) || other.g == g)&&(identical(other.b, b) || other.b == b));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,r,g,b);



}

/// @nodoc
abstract mixin class _$LiveMessageColorCopyWith<$Res> implements $LiveMessageColorCopyWith<$Res> {
  factory _$LiveMessageColorCopyWith(_LiveMessageColor value, $Res Function(_LiveMessageColor) _then) = __$LiveMessageColorCopyWithImpl;
@override @useResult
$Res call({
 int r, int g, int b
});




}
/// @nodoc
class __$LiveMessageColorCopyWithImpl<$Res>
    implements _$LiveMessageColorCopyWith<$Res> {
  __$LiveMessageColorCopyWithImpl(this._self, this._then);

  final _LiveMessageColor _self;
  final $Res Function(_LiveMessageColor) _then;

/// Create a copy of LiveMessageColor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? r = null,Object? g = null,Object? b = null,}) {
  return _then(_LiveMessageColor(
r: null == r ? _self.r : r // ignore: cast_nullable_to_non_nullable
as int,g: null == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as int,b: null == b ? _self.b : b // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LiveMessage {

 LiveMessageType get type; String get userName; String get message; LiveMessageColor get color; dynamic get data;
/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveMessageCopyWith<LiveMessage> get copyWith => _$LiveMessageCopyWithImpl<LiveMessage>(this as LiveMessage, _$identity);

  /// Serializes this LiveMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveMessage&&(identical(other.type, type) || other.type == type)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.message, message) || other.message == message)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,userName,message,color,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'LiveMessage(type: $type, userName: $userName, message: $message, color: $color, data: $data)';
}


}

/// @nodoc
abstract mixin class $LiveMessageCopyWith<$Res>  {
  factory $LiveMessageCopyWith(LiveMessage value, $Res Function(LiveMessage) _then) = _$LiveMessageCopyWithImpl;
@useResult
$Res call({
 LiveMessageType type, String userName, String message, LiveMessageColor color, dynamic data
});


$LiveMessageColorCopyWith<$Res> get color;

}
/// @nodoc
class _$LiveMessageCopyWithImpl<$Res>
    implements $LiveMessageCopyWith<$Res> {
  _$LiveMessageCopyWithImpl(this._self, this._then);

  final LiveMessage _self;
  final $Res Function(LiveMessage) _then;

/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? userName = null,Object? message = null,Object? color = null,Object? data = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LiveMessageType,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as LiveMessageColor,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}
/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveMessageColorCopyWith<$Res> get color {
  
  return $LiveMessageColorCopyWith<$Res>(_self.color, (value) {
    return _then(_self.copyWith(color: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveMessage].
extension LiveMessagePatterns on LiveMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveMessage value)  $default,){
final _that = this;
switch (_that) {
case _LiveMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveMessage value)?  $default,){
final _that = this;
switch (_that) {
case _LiveMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LiveMessageType type,  String userName,  String message,  LiveMessageColor color,  dynamic data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveMessage() when $default != null:
return $default(_that.type,_that.userName,_that.message,_that.color,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LiveMessageType type,  String userName,  String message,  LiveMessageColor color,  dynamic data)  $default,) {final _that = this;
switch (_that) {
case _LiveMessage():
return $default(_that.type,_that.userName,_that.message,_that.color,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LiveMessageType type,  String userName,  String message,  LiveMessageColor color,  dynamic data)?  $default,) {final _that = this;
switch (_that) {
case _LiveMessage() when $default != null:
return $default(_that.type,_that.userName,_that.message,_that.color,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveMessage implements LiveMessage {
  const _LiveMessage({required this.type, required this.userName, required this.message, required this.color, this.data});
  factory _LiveMessage.fromJson(Map<String, dynamic> json) => _$LiveMessageFromJson(json);

@override final  LiveMessageType type;
@override final  String userName;
@override final  String message;
@override final  LiveMessageColor color;
@override final  dynamic data;

/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveMessageCopyWith<_LiveMessage> get copyWith => __$LiveMessageCopyWithImpl<_LiveMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveMessage&&(identical(other.type, type) || other.type == type)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.message, message) || other.message == message)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,userName,message,color,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'LiveMessage(type: $type, userName: $userName, message: $message, color: $color, data: $data)';
}


}

/// @nodoc
abstract mixin class _$LiveMessageCopyWith<$Res> implements $LiveMessageCopyWith<$Res> {
  factory _$LiveMessageCopyWith(_LiveMessage value, $Res Function(_LiveMessage) _then) = __$LiveMessageCopyWithImpl;
@override @useResult
$Res call({
 LiveMessageType type, String userName, String message, LiveMessageColor color, dynamic data
});


@override $LiveMessageColorCopyWith<$Res> get color;

}
/// @nodoc
class __$LiveMessageCopyWithImpl<$Res>
    implements _$LiveMessageCopyWith<$Res> {
  __$LiveMessageCopyWithImpl(this._self, this._then);

  final _LiveMessage _self;
  final $Res Function(_LiveMessage) _then;

/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? userName = null,Object? message = null,Object? color = null,Object? data = freezed,}) {
  return _then(_LiveMessage(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LiveMessageType,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as LiveMessageColor,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

/// Create a copy of LiveMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveMessageColorCopyWith<$Res> get color {
  
  return $LiveMessageColorCopyWith<$Res>(_self.color, (value) {
    return _then(_self.copyWith(color: value));
  });
}
}


/// @nodoc
mixin _$LiveSuperChatMessage {

 String get userName; String get face; String get message; int get price; DateTime get startTime; DateTime get endTime; String get backgroundColor; String get backgroundBottomColor;
/// Create a copy of LiveSuperChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveSuperChatMessageCopyWith<LiveSuperChatMessage> get copyWith => _$LiveSuperChatMessageCopyWithImpl<LiveSuperChatMessage>(this as LiveSuperChatMessage, _$identity);

  /// Serializes this LiveSuperChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveSuperChatMessage&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.face, face) || other.face == face)&&(identical(other.message, message) || other.message == message)&&(identical(other.price, price) || other.price == price)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.backgroundBottomColor, backgroundBottomColor) || other.backgroundBottomColor == backgroundBottomColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userName,face,message,price,startTime,endTime,backgroundColor,backgroundBottomColor);

@override
String toString() {
  return 'LiveSuperChatMessage(userName: $userName, face: $face, message: $message, price: $price, startTime: $startTime, endTime: $endTime, backgroundColor: $backgroundColor, backgroundBottomColor: $backgroundBottomColor)';
}


}

/// @nodoc
abstract mixin class $LiveSuperChatMessageCopyWith<$Res>  {
  factory $LiveSuperChatMessageCopyWith(LiveSuperChatMessage value, $Res Function(LiveSuperChatMessage) _then) = _$LiveSuperChatMessageCopyWithImpl;
@useResult
$Res call({
 String userName, String face, String message, int price, DateTime startTime, DateTime endTime, String backgroundColor, String backgroundBottomColor
});




}
/// @nodoc
class _$LiveSuperChatMessageCopyWithImpl<$Res>
    implements $LiveSuperChatMessageCopyWith<$Res> {
  _$LiveSuperChatMessageCopyWithImpl(this._self, this._then);

  final LiveSuperChatMessage _self;
  final $Res Function(LiveSuperChatMessage) _then;

/// Create a copy of LiveSuperChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userName = null,Object? face = null,Object? message = null,Object? price = null,Object? startTime = null,Object? endTime = null,Object? backgroundColor = null,Object? backgroundBottomColor = null,}) {
  return _then(_self.copyWith(
userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,backgroundBottomColor: null == backgroundBottomColor ? _self.backgroundBottomColor : backgroundBottomColor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveSuperChatMessage].
extension LiveSuperChatMessagePatterns on LiveSuperChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveSuperChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveSuperChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveSuperChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _LiveSuperChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveSuperChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _LiveSuperChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userName,  String face,  String message,  int price,  DateTime startTime,  DateTime endTime,  String backgroundColor,  String backgroundBottomColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveSuperChatMessage() when $default != null:
return $default(_that.userName,_that.face,_that.message,_that.price,_that.startTime,_that.endTime,_that.backgroundColor,_that.backgroundBottomColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userName,  String face,  String message,  int price,  DateTime startTime,  DateTime endTime,  String backgroundColor,  String backgroundBottomColor)  $default,) {final _that = this;
switch (_that) {
case _LiveSuperChatMessage():
return $default(_that.userName,_that.face,_that.message,_that.price,_that.startTime,_that.endTime,_that.backgroundColor,_that.backgroundBottomColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userName,  String face,  String message,  int price,  DateTime startTime,  DateTime endTime,  String backgroundColor,  String backgroundBottomColor)?  $default,) {final _that = this;
switch (_that) {
case _LiveSuperChatMessage() when $default != null:
return $default(_that.userName,_that.face,_that.message,_that.price,_that.startTime,_that.endTime,_that.backgroundColor,_that.backgroundBottomColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveSuperChatMessage implements LiveSuperChatMessage {
  const _LiveSuperChatMessage({required this.userName, required this.face, required this.message, required this.price, required this.startTime, required this.endTime, required this.backgroundColor, required this.backgroundBottomColor});
  factory _LiveSuperChatMessage.fromJson(Map<String, dynamic> json) => _$LiveSuperChatMessageFromJson(json);

@override final  String userName;
@override final  String face;
@override final  String message;
@override final  int price;
@override final  DateTime startTime;
@override final  DateTime endTime;
@override final  String backgroundColor;
@override final  String backgroundBottomColor;

/// Create a copy of LiveSuperChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveSuperChatMessageCopyWith<_LiveSuperChatMessage> get copyWith => __$LiveSuperChatMessageCopyWithImpl<_LiveSuperChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveSuperChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveSuperChatMessage&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.face, face) || other.face == face)&&(identical(other.message, message) || other.message == message)&&(identical(other.price, price) || other.price == price)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.backgroundBottomColor, backgroundBottomColor) || other.backgroundBottomColor == backgroundBottomColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userName,face,message,price,startTime,endTime,backgroundColor,backgroundBottomColor);

@override
String toString() {
  return 'LiveSuperChatMessage(userName: $userName, face: $face, message: $message, price: $price, startTime: $startTime, endTime: $endTime, backgroundColor: $backgroundColor, backgroundBottomColor: $backgroundBottomColor)';
}


}

/// @nodoc
abstract mixin class _$LiveSuperChatMessageCopyWith<$Res> implements $LiveSuperChatMessageCopyWith<$Res> {
  factory _$LiveSuperChatMessageCopyWith(_LiveSuperChatMessage value, $Res Function(_LiveSuperChatMessage) _then) = __$LiveSuperChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String userName, String face, String message, int price, DateTime startTime, DateTime endTime, String backgroundColor, String backgroundBottomColor
});




}
/// @nodoc
class __$LiveSuperChatMessageCopyWithImpl<$Res>
    implements _$LiveSuperChatMessageCopyWith<$Res> {
  __$LiveSuperChatMessageCopyWithImpl(this._self, this._then);

  final _LiveSuperChatMessage _self;
  final $Res Function(_LiveSuperChatMessage) _then;

/// Create a copy of LiveSuperChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userName = null,Object? face = null,Object? message = null,Object? price = null,Object? startTime = null,Object? endTime = null,Object? backgroundColor = null,Object? backgroundBottomColor = null,}) {
  return _then(_LiveSuperChatMessage(
userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,backgroundColor: null == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as String,backgroundBottomColor: null == backgroundBottomColor ? _self.backgroundBottomColor : backgroundBottomColor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
