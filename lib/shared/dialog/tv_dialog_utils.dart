import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/services/settings/settings.dart';

class TvDialogUtils {
  /// The dialog lock, or null before the settings service is up.
  ///
  /// Reads the container through `isInitialized`: the field is `late`, so touching
  /// `container` itself throws instead of returning null, and a dialog opened
  /// during startup (or in a widget test) must not crash.
  static ProviderContainer? get _container =>
      SettingsService.to.isInitialized ? SettingsService.to.container : null;

  static Future<T?> show<T>({required BuildContext context, required WidgetBuilder builder}) async {
    _container?.read(tvDialogLockProvider.notifier).lock();

    // The row/button that had the keyboard before the dialog opened. Restoring
    // it here (not from the page's route-lifecycle hooks) is what
    // wins: the dialog's focus tree disposes when its *exit transition* ends —
    // after any frame-bounded restore has run — and the d-pad layer answers
    // that focus death by parking on the top-most node it finds, which is the
    // app bar's back button.
    final FocusNode? invokingFocus = FocusManager.instance.primaryFocus;

    final result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'TvDialogBarrier',
      barrierColor: Colors.black.withAlpha(150),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve), child: child),
        );
      },
    );

    _container?.read(tvDialogLockProvider.notifier).unlock();

    // The dialog is fully gone here; hand the keyboard back to exactly where
    // the user was, asserting for a few frames so the d-pad fallback loses.
    _restoreInvokingFocus(invokingFocus);

    return result;
  }

  /// Re-asserts [node] until it settles, for up to [deadline]; gives up
  /// silently when the node was rebuilt away or focus moved elsewhere.
  ///
  /// The window must outlast the dialog's 300ms *exit* transition: the dialog's
  /// focus tree (and its focus guard) only disposes when that animation ends,
  /// and that disposal is the moment the d-pad fallback parks on the app bar's
  /// back button. A frame-counted retry ran out inside the transition and the
  /// fallback still won on pages like background -> aspect ratio.
  static void _restoreInvokingFocus(FocusNode? node, {Duration deadline = const Duration(milliseconds: 900)}) {
    if (node == null) return;
    final DateTime stopAt = DateTime.now().add(deadline);
    void attempt() {
      if (DateTime.now().isAfter(stopAt)) return;
      if (identical(FocusManager.instance.primaryFocus, node)) return; // settled
      final bool usable = node.parent != null && node.context?.mounted == true && node.canRequestFocus;
      if (!usable) return;
      node.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show<bool>(
      context: context,
      builder: (context) => TvConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    int? maxLength,
    ValueChanged<String>? onConfirm,
  }) {
    return show<String>(
      context: context,
      builder: (context) => TvInputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        maxLength: maxLength,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<T?> showMenu<T>({
    required BuildContext context,
    required String title,
    required List<TvMenuItem<T>> items,
    T? selectedValue,
    ValueChanged<T>? onSelected,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context: context,
      builder: (context) =>
          TvMenuDialog<T>(title: title, items: items, selectedValue: selectedValue, onSelected: onSelected),
    );
  }

  static Future<T?> showSelect<T>({
    required BuildContext context,
    required String title,
    required List<TvSelectItem<T>> items,
    T? selectedValue,
    ValueChanged<T>? onSelected,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context: context,
      builder: (context) =>
          TvSelectDialog<T>(title: title, items: items, selectedValue: selectedValue, onSelected: onSelected),
    );
  }

  /// Returns the confirmed selection, or null when the dialog was cancelled.
  static Future<Set<T>?> showMultiSelect<T>({
    required BuildContext context,
    required String title,
    required List<TvMultiSelectItem<T>> items,
    required Set<T> initialSelection,
    String? emptyHint,
  }) {
    return show<Set<T>>(
      context: context,
      builder: (context) => TvMultiSelectDialog<T>(
        title: title,
        items: items,
        initialSelection: initialSelection,
        emptyHint: emptyHint,
      ),
    );
  }
}
