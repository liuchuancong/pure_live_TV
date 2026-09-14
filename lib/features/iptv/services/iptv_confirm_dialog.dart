import 'package:flutter/material.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Confirmation dialog shown when an import would overwrite an existing source.
///
/// Returns false when no navigator is available: keeping the stored source is
Future<bool> confirmReplaceIptvSource({required String title, required String message}) async {
  final context = appNavigatorContext;
  if (context == null) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(i18n('cancel'))),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(i18n('confirm'))),
      ],
    ),
  );
  return confirmed == true;
}
