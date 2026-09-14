/// 播放器核心等非 widget 代码读取控制器状态的反应式视图：
/// `.v` / `.value` 每次读取都会重新取最新状态；提供写入器时可直接赋值。
class SettingsValue<T> {
  const SettingsValue(this._read, [this._write]);

  final T Function() _read;
  final void Function(T value)? _write;

  T get v => _read();
  T get value => _read();

  set v(T value) => _write?.call(value);
  set value(T value) => _write?.call(value);
}
