import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';

/// The "open the web form" card: a QR carrying the web remote's
/// `http://ip:port/` address, served by the alfred web server. A phone camera
/// scan opens the page directly.
class RemoteSyncQrCard extends ConsumerWidget {
  const RemoteSyncQrCard({super.key, this.width = 260});

  /// Card width in design pixels; the player panel passes a smaller value.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.watch(tvRemoteReceiverProvider);
    final tvTheme = context.tvTheme;

    final String? error = server.value?.error;
    final String url = server.value?.serverUrl ?? '';
    final bool ready = server.value?.isRunning == true && url.isNotEmpty;

    if (!ready) {
      return Container(
        width: width.sp,
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.5), width: 1.sp),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: error == null
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(Icons.error_outline_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              child: Text(
                error ?? i18nOr('remote_sync_starting', 'Starting the LAN sync service...'),
                style: TextStyle(fontSize: 14.sp, color: tvTheme.secondaryTextColor),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width.sp,
      child: TvQrCodeCard(qrData: url, urlText: url),
    );
  }
}
