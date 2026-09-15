import 'package:flutter/material.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/shared/dialog/tv_dialog.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Confirmation dialog shown when an import would overwrite an existing source.
///
/// Returns false when no navigator is available: keeping the stored source is
/// the safe default.
///
/// Uses [TvDialog] rather than a Material `AlertDialog`: this is a remote-only
/// TV screen, and the app's TV dialog gives the confirm button a focusable
/// target with an autofocus landing point and a focus ring.
Future<bool> confirmReplaceIptvSource({required String title, required String message}) async {
  final context = appNavigatorContext;
  if (context == null) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => TvDialog(
      title: title,
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
      child: Text(
        message,
        style: TextStyle(color: dialogContext.tvTheme.secondaryTextColor, fontSize: 24.sp),
      ),
    ),
  );
  return confirmed == true;
}
