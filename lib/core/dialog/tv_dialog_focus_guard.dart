import 'package:flutter/material.dart';

/// Keeps the keyboard inside the dialog it wraps.
///
/// The d-pad layer treats "the focused node died" as a reason to restore focus
/// itself: it picks the node nearest the last known position on the whole screen.
/// A list that rebuilds while a dialog is open (the history grid is reactive, and
/// its cards are recreated page by page) therefore hands the remote back to a card
/// *behind* the dialog — the dialog stays on screen with its field unreachable and
/// the highlight moving on the page underneath.
///
/// Rather than asking every list to behave, the dialog holds its own focus: the
/// moment the primary focus ends up outside this subtree while the dialog is the
/// route on screen, the first focusable inside it takes the keyboard back.
///
/// A dialog stacked *above* this one is untouched: it makes this route stop being
/// current, and a covered dialog must not fight it for focus.
class TvDialogFocusGuard extends StatefulWidget {
  const TvDialogFocusGuard({super.key, required this.child, this.initialFocusNode});

  final Widget child;

  /// The node the dialog should open the keyboard on — for a select dialog the
  /// row holding the value in force, not merely the first one.
  final FocusNode? initialFocusNode;

  @override
  State<TvDialogFocusGuard> createState() => _TvDialogFocusGuardState();
}

class _TvDialogFocusGuardState extends State<TvDialogFocusGuard> {
  final FocusNode _root = FocusNode(debugLabel: 'tv-dialog/focus-guard', skipTraversal: true);

  /// The last node *inside* the dialog that held the keyboard, so a restore puts
  /// the user back on the row/field they were using rather than on the first one.
  FocusNode? _lastInside;

  /// One restore in flight at a time; a burst of focus changes must not queue up.
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleFocusChange);
    // Claim the keyboard once the dialog has laid out.
    //
    // Listening for focus *changes* is not enough: when a dialog opens while
    // the page behind it keeps its focus, no change fires and the keyboard stays
    // on the app-bar back button underneath — every option row is then
    // unreachable and only a mouse click works. One post-frame claim makes the
    // dialog own the remote from the first key press.
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimWithRetry(0));
  }

  /// Claims the keyboard, retrying across a few frames.
  ///
  /// A dialog body is often a lazy list: on the first layout the option rows
  /// may not exist yet, and the only focusable node then is the dialog's close
  /// button — claiming it *did* put the keyboard inside the dialog, but on the
  /// wrong row, and the guard then defended that wrong row against every later
  /// correction. Retrying until something inside holds the keyboard lets the
  /// rows appear first and the preferred node win.
  void _claimWithRetry(int attempts) {
    if (!mounted || attempts >= 10) return;
    if (_holdsKeyboard) return;
    _claim();
    if (_holdsKeyboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimWithRetry(attempts + 1));
  }

  /// Hands the keyboard to an option inside the dialog, if it is not there yet.
  void _claim() {
    if (!mounted || _holdsKeyboard) return;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    final Iterable<FocusNode> candidates = _candidates;
    if (candidates.isEmpty) return;
    final FocusNode? preferred = _lastInside ?? widget.initialFocusNode;
    if (preferred != null && candidates.contains(preferred)) {
      preferred.requestFocus();
      return;
    }
    candidates.first.requestFocus();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    _root.dispose();
    super.dispose();
  }

  FocusNode? get _primaryFocus => FocusManager.instance.primaryFocus;

  /// Whether the keyboard is somewhere inside this dialog.
  bool get _holdsKeyboard {
    for (FocusNode? node = _primaryFocus; node != null; node = node.parent) {
      if (identical(node, _root)) return true;
    }
    return false;
  }

  /// Focusable nodes of this dialog, in tree order.
  Iterable<FocusNode> get _candidates =>
      _root.descendants.where((node) => node.canRequestFocus && node.context?.mounted == true);

  void _handleFocusChange() {
    if (!mounted) return;
    if (_holdsKeyboard) {
      _lastInside = _primaryFocus;
      return;
    }
    if (_restoring) return;

    // Only the dialog on screen defends the keyboard: while another route covers
    // this one it is that route's job.
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    _restoring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoring = false;
      if (!mounted || _holdsKeyboard) return;
      final Iterable<FocusNode> candidates = _candidates;
      if (candidates.isEmpty) return;
      final FocusNode? preferred = _lastInside ?? widget.initialFocusNode;
      if (preferred != null && candidates.contains(preferred)) {
        preferred.requestFocus();
        return;
      }
      candidates.first.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _root,
      // The dialog itself is not a stop the user can land on; it is only the
      // subtree whose focus we defend.
      canRequestFocus: false,
      skipTraversal: true,
      child: widget.child,
    );
  }
}
