import 'package:flutter/material.dart';
import 'package:pure_live/dialog/index.dart';

class TvDialogUtils {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
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
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return show<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
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
    bool barrierDismissible = true,
  }) {
    return show<String>(
      context: context,
      barrierDismissible: barrierDismissible,
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
      barrierDismissible: barrierDismissible,
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
      barrierDismissible: barrierDismissible,
      builder: (context) =>
          TvSelectDialog<T>(title: title, items: items, selectedValue: selectedValue, onSelected: onSelected),
    );
  }
}
