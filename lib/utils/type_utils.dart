T? asT<T>(dynamic value) {
  if (value is T) return value;
  if (value == null) return null;

  // 基础类型处理
  if (T == String) return value.toString() as T;
  if (T == int) return (int.tryParse(value.toString()) ?? 0) as T;
  if (T == double) return (double.tryParse(value.toString()) ?? 0.0) as T;
  if (T == bool) {
    if (value is String) return (value == 'true') as T;
    return (value != 0) as T;
  }

  return null;
}
