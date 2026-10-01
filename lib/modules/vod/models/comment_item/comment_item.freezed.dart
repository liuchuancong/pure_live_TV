// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentItem {

 int get rpid; int get oid; int get type; int get mid; String get uname; String get face; int get level; String get content; List<String> get pictures; int get ctime; int get like; int get rcount; bool get liked; bool get isTop; bool get isUp; List<CommentItem> get replies;
/// Create a copy of CommentItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentItemCopyWith<CommentItem> get copyWith => _$CommentItemCopyWithImpl<CommentItem>(this as CommentItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CommentItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentItem&&(identical(other.rpid, _this.rpid) || other.rpid == _this.rpid)&&(identical(other.oid, _this.oid) || other.oid == _this.oid)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.mid, _this.mid) || other.mid == _this.mid)&&(identical(other.uname, _this.uname) || other.uname == _this.uname)&&(identical(other.face, _this.face) || other.face == _this.face)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.content, _this.content) || other.content == _this.content)&&const DeepCollectionEquality().equals(other.pictures, _this.pictures)&&(identical(other.ctime, _this.ctime) || other.ctime == _this.ctime)&&(identical(other.like, _this.like) || other.like == _this.like)&&(identical(other.rcount, _this.rcount) || other.rcount == _this.rcount)&&(identical(other.liked, _this.liked) || other.liked == _this.liked)&&(identical(other.isTop, _this.isTop) || other.isTop == _this.isTop)&&(identical(other.isUp, _this.isUp) || other.isUp == _this.isUp)&&const DeepCollectionEquality().equals(other.replies, _this.replies));
}


@override
int get hashCode {
  final _this = this as CommentItem;
  return Object.hash(runtimeType,_this.rpid,_this.oid,_this.type,_this.mid,_this.uname,_this.face,_this.level,_this.content,const DeepCollectionEquality().hash(_this.pictures),_this.ctime,_this.like,_this.rcount,_this.liked,_this.isTop,_this.isUp,const DeepCollectionEquality().hash(_this.replies));
}

@override
String toString() {
  final _this = this as CommentItem;
  return 'CommentItem(rpid: ${_this.rpid}, oid: ${_this.oid}, type: ${_this.type}, mid: ${_this.mid}, uname: ${_this.uname}, face: ${_this.face}, level: ${_this.level}, content: ${_this.content}, pictures: ${_this.pictures}, ctime: ${_this.ctime}, like: ${_this.like}, rcount: ${_this.rcount}, liked: ${_this.liked}, isTop: ${_this.isTop}, isUp: ${_this.isUp}, replies: ${_this.replies})';
}


}

/// @nodoc
abstract mixin class $CommentItemCopyWith<$Res>  {
  factory $CommentItemCopyWith(CommentItem value, $Res Function(CommentItem) _then) = _$CommentItemCopyWithImpl;
@useResult
$Res call({
 int rpid, int oid, int type, int mid, String uname, String face, int level, String content, List<String> pictures, int ctime, int like, int rcount, bool liked, bool isTop, bool isUp, List<CommentItem> replies
});




}
/// @nodoc
class _$CommentItemCopyWithImpl<$Res>
    implements $CommentItemCopyWith<$Res> {
  _$CommentItemCopyWithImpl(this._self, this._then);

  final CommentItem _self;
  final $Res Function(CommentItem) _then;

/// Create a copy of CommentItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rpid = null,Object? oid = null,Object? type = null,Object? mid = null,Object? uname = null,Object? face = null,Object? level = null,Object? content = null,Object? pictures = null,Object? ctime = null,Object? like = null,Object? rcount = null,Object? liked = null,Object? isTop = null,Object? isUp = null,Object? replies = null,}) {
  return _then(CommentItem(
rpid: null == rpid ? _self.rpid : rpid // ignore: cast_nullable_to_non_nullable
as int,oid: null == oid ? _self.oid : oid // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,pictures: null == pictures ? _self.pictures : pictures // ignore: cast_nullable_to_non_nullable
as List<String>,ctime: null == ctime ? _self.ctime : ctime // ignore: cast_nullable_to_non_nullable
as int,like: null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as int,rcount: null == rcount ? _self.rcount : rcount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,isUp: null == isUp ? _self.isUp : isUp // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentItem].
extension CommentItemPatterns on CommentItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentItem value)  $default,){
final _that = this;
switch (_that) {
case _CommentItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentItem value)?  $default,){
final _that = this;
switch (_that) {
case _CommentItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rpid,  int oid,  int type,  int mid,  String uname,  String face,  int level,  String content,  List<String> pictures,  int ctime,  int like,  int rcount,  bool liked,  bool isTop,  bool isUp,  List<CommentItem> replies)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentItem() when $default != null:
return $default(_that.rpid,_that.oid,_that.type,_that.mid,_that.uname,_that.face,_that.level,_that.content,_that.pictures,_that.ctime,_that.like,_that.rcount,_that.liked,_that.isTop,_that.isUp,_that.replies);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rpid,  int oid,  int type,  int mid,  String uname,  String face,  int level,  String content,  List<String> pictures,  int ctime,  int like,  int rcount,  bool liked,  bool isTop,  bool isUp,  List<CommentItem> replies)  $default,) {final _that = this;
switch (_that) {
case _CommentItem():
return $default(_that.rpid,_that.oid,_that.type,_that.mid,_that.uname,_that.face,_that.level,_that.content,_that.pictures,_that.ctime,_that.like,_that.rcount,_that.liked,_that.isTop,_that.isUp,_that.replies);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rpid,  int oid,  int type,  int mid,  String uname,  String face,  int level,  String content,  List<String> pictures,  int ctime,  int like,  int rcount,  bool liked,  bool isTop,  bool isUp,  List<CommentItem> replies)?  $default,) {final _that = this;
switch (_that) {
case _CommentItem() when $default != null:
return $default(_that.rpid,_that.oid,_that.type,_that.mid,_that.uname,_that.face,_that.level,_that.content,_that.pictures,_that.ctime,_that.like,_that.rcount,_that.liked,_that.isTop,_that.isUp,_that.replies);case _:
  return null;

}
}

}

/// @nodoc


class _CommentItem implements CommentItem {
  const _CommentItem({this.rpid = 0, this.oid = 0, this.type = 1, this.mid = 0, this.uname = '', this.face = '', this.level = 0, this.content = '',  List<String> pictures = const [], this.ctime = 0, this.like = 0, this.rcount = 0, this.liked = false, this.isTop = false, this.isUp = false,  List<CommentItem> replies = const []}): _pictures = pictures,_replies = replies;
  

@override@JsonKey() final  int rpid;
@override@JsonKey() final  int oid;
@override@JsonKey() final  int type;
@override@JsonKey() final  int mid;
@override@JsonKey() final  String uname;
@override@JsonKey() final  String face;
@override@JsonKey() final  int level;
@override@JsonKey() final  String content;
 final  List<String> _pictures;
@override@JsonKey() List<String> get pictures {
  if (_pictures is EqualUnmodifiableListView) return _pictures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pictures);
}

@override@JsonKey() final  int ctime;
@override@JsonKey() final  int like;
@override@JsonKey() final  int rcount;
@override@JsonKey() final  bool liked;
@override@JsonKey() final  bool isTop;
@override@JsonKey() final  bool isUp;
 final  List<CommentItem> _replies;
@override@JsonKey() List<CommentItem> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}


/// Create a copy of CommentItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentItemCopyWith<_CommentItem> get copyWith => __$CommentItemCopyWithImpl<_CommentItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentItem&&(identical(other.rpid, rpid) || other.rpid == rpid)&&(identical(other.oid, oid) || other.oid == oid)&&(identical(other.type, type) || other.type == type)&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.face, face) || other.face == face)&&(identical(other.level, level) || other.level == level)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.pictures, _pictures)&&(identical(other.ctime, ctime) || other.ctime == ctime)&&(identical(other.like, like) || other.like == like)&&(identical(other.rcount, rcount) || other.rcount == rcount)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isTop, isTop) || other.isTop == isTop)&&(identical(other.isUp, isUp) || other.isUp == isUp)&&const DeepCollectionEquality().equals(other.replies, _replies));
}


@override
int get hashCode {
    return Object.hash(runtimeType,rpid,oid,type,mid,uname,face,level,content,const DeepCollectionEquality().hash(_pictures),ctime,like,rcount,liked,isTop,isUp,const DeepCollectionEquality().hash(_replies));
}

@override
String toString() {
    return 'CommentItem(rpid: $rpid, oid: $oid, type: $type, mid: $mid, uname: $uname, face: $face, level: $level, content: $content, pictures: $pictures, ctime: $ctime, like: $like, rcount: $rcount, liked: $liked, isTop: $isTop, isUp: $isUp, replies: $replies)';
}


}

/// @nodoc
abstract mixin class _$CommentItemCopyWith<$Res> implements $CommentItemCopyWith<$Res> {
  factory _$CommentItemCopyWith(_CommentItem value, $Res Function(_CommentItem) _then) = __$CommentItemCopyWithImpl;
@override @useResult
$Res call({
 int rpid, int oid, int type, int mid, String uname, String face, int level, String content, List<String> pictures, int ctime, int like, int rcount, bool liked, bool isTop, bool isUp, List<CommentItem> replies
});




}
/// @nodoc
class __$CommentItemCopyWithImpl<$Res>
    implements _$CommentItemCopyWith<$Res> {
  __$CommentItemCopyWithImpl(this._self, this._then);

  final _CommentItem _self;
  final $Res Function(_CommentItem) _then;

/// Create a copy of CommentItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rpid = null,Object? oid = null,Object? type = null,Object? mid = null,Object? uname = null,Object? face = null,Object? level = null,Object? content = null,Object? pictures = null,Object? ctime = null,Object? like = null,Object? rcount = null,Object? liked = null,Object? isTop = null,Object? isUp = null,Object? replies = null,}) {
  return _then(_CommentItem(
rpid: null == rpid ? _self.rpid : rpid // ignore: cast_nullable_to_non_nullable
as int,oid: null == oid ? _self.oid : oid // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,pictures: null == pictures ? _self._pictures : pictures // ignore: cast_nullable_to_non_nullable
as List<String>,ctime: null == ctime ? _self.ctime : ctime // ignore: cast_nullable_to_non_nullable
as int,like: null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as int,rcount: null == rcount ? _self.rcount : rcount // ignore: cast_nullable_to_non_nullable
as int,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,isUp: null == isUp ? _self.isUp : isUp // ignore: cast_nullable_to_non_nullable
as bool,replies: null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<CommentItem>,
  ));
}


}

// dart format on
