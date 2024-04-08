/// - [isNullOrEmpty], [isNullEmptyOrFalse], [isNullEmptyZeroOrFalse] are from [this StackOverflow answer](https://stackoverflow.com/a/59826129/10830091)
extension GeneralUtilsObjectExtension on Object {
  /// Returns true if object is:
  /// - null `Object`
  // ignore: unnecessary_null_comparison
  bool get isNull => this == null;

  /// Returns true if object is NOT:
  /// - null `Object`
  // ignore: unnecessary_null_comparison
  bool get isNotNull => this != null;

  /// Returns true if object is:
  /// - null `Object`
  /// - empty `String`
  /// - empty `Iterable` (list, map, set, ...)
  bool get isNullOrEmpty =>
      isNull || _isStringObjectEmpty || _isIterableObjectEmpty;

  /// Returns true if object is:
  /// - null `Object`
  /// - empty `String`
  /// - empty `Iterable` (list, map, set, ...)
  /// - false `bool`
  bool get isNullEmptyOrFalse =>
      isNull ||
      _isStringObjectEmpty ||
      _isIterableObjectEmpty ||
      _isBoolObjectFalse;

  /// Returns true if object is:
  /// - null `Object`
  /// - empty `String`
  /// - empty `Iterable` (list, map, set, ...)
  /// - false `bool`
  /// - zero `num`
  bool get isNullEmptyFalseOrZero =>
      isNull ||
      _isStringObjectEmpty ||
      _isIterableObjectEmpty ||
      _isBoolObjectFalse ||
      _isNumObjectZero;

  // ------- PRIVATE EXTENSION HELPERS -------
  /// **Private helper**
  ///
  /// If `String` object, return String's method `isEmpty`
  ///
  /// Otherwise return `false` to not affect logical-OR expression. As `false` denotes undefined or N/A since object is not `String`
  bool get _isStringObjectEmpty =>
      (this is String) ? (this as String).isEmpty : false;

  /// **Private helper**
  ///
  /// If `Iterable` object, return Iterable's method `isEmpty`
  ///
  /// Otherwise return `false` to not affect logical-OR expression. As `false` denotes undefined or N/A since object is not `Iterable`
  bool get _isIterableObjectEmpty =>
      (this is Iterable) ? (this as Iterable).isEmpty : false;

  /// **Private helper**
  ///
  /// If `bool` object, return `isFalse` expression
  ///
  /// Otherwise return `false` to not affect logical-OR expression. As `false` denotes undefined or N/A since object is not `bool`
  bool get _isBoolObjectFalse =>
      (this is bool) ? (this as bool) == false : false;

  /// **Private helper**
  ///
  /// If `num` object, return `isZero` expression
  ///
  /// Otherwise return `false` to not affect logical-OR expression. As `false` denotes undefined or N/A since object is not `num`
  bool get _isNumObjectZero => (this is num) ? (this as num) == 0 : false;
}
