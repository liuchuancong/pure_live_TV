/// Reactive view over controller state for non-widget code such as the player
/// core. Every read of `.v` / `.value` re-reads the latest state, and
/// assigning works whenever a writer was provided.
class SettingsValue<T> {
  const SettingsValue(this._read, [this._write]);

  final T Function() _read;
  final void Function(T value)? _write;

  T get v => _read();
  T get value => _read();

  set v(T value) => _write?.call(value);
  set value(T value) => _write?.call(value);
}
