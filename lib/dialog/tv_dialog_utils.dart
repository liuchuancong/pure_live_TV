import 'package:flutter/material.dart';
import 'package:pure_live/dialog/index.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/dialog/tv_dialog_lock_provider.dart';

class TvDialogUtils {
  static Future<T?> show<T>({required BuildContext context, required WidgetBuilder builder}) async {
    SettingsService.to.container?.read(tvDialogLockProvider.notifier).lock();

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

    SettingsService.to.container?.read(tvDialogLockProvider.notifier).unlock();

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
}
