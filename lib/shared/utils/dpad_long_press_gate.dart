/// Keeps a long press from also arriving as a tap.
///
/// `DpadFocusable` decides between select and long-select itself and normally
/// drops the select for a held key. The release can still be reported as a select
/// when the press is disturbed — the remote sends an extra down/up pair, the card
/// is rebuilt mid-press, a dialog takes the keyboard and hands it back — and the
/// card then opened the room on the tail of its own long press.
///
/// A card marks the long press here and drops the next select that arrives inside
/// [_window], so a hold always ends in its menu and never in a tap.
class DpadLongPressGate {
  /// How long after a long press a select still counts as its release.
  ///
  /// Long enough to cover the release of the same press (a viewer lets go as soon
  /// as the menu appears), short enough that a deliberate press after the menu was
  /// dismissed is treated as a new press.
  static const Duration _window = Duration(seconds: 1);

  DateTime? _firedAt;

  /// Records that the card's long-press action just ran.
  void markLongPress() => _firedAt = DateTime.now();

  /// Whether this select is the release of a long press and must be dropped.
  bool swallowSelect() {
    final DateTime? at = _firedAt;
    _firedAt = null;
    return at != null && DateTime.now().difference(at) < _window;
  }
}
