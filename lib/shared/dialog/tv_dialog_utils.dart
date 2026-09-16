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

    return result;
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
