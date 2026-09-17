import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The "connect your phone" card: a QR that opens the web form, plus the plain
/// `http://ip:port/` for manual entry.
///
/// The QR used to carry `purelive://ip:port/sync`, which only the mobile app could open —
/// a camera scan did nothing. It is the HTTP address now, so any phone browser lands on
/// the page where cookies, IPTV request headers, WebDAV, the proxy and search text are
/// typed, and every one of those lands in the TV's own settings.
class RemoteSyncQrCard extends ConsumerWidget {
  const RemoteSyncQrCard({super.key, this.width = 260});

  /// Card width in design pixels; the player panel passes a smaller value.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(remoteSyncControllerProvider);
    final tvTheme = context.tvTheme;

    if (!snapshot.started || snapshot.qrData.isEmpty) {
      // A failure has to be actionable: the spinner used to run forever whenever the
      // server could not start (no LAN address, port taken), with nothing to press.
      final String? error = snapshot.error;
      return Container(
        width: width.sp,
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.5), width: 1.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
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
            if (error != null) ...<Widget>[
              SizedBox(height: 12.sp),
              TvButton(
                title: i18nOr('remote_sync_retry', 'Retry'),
                size: TvButtonSize.mini,
                icon: Icon(Remix.refresh_line, size: 20.sp),
                onTap: () => ref.read(remoteSyncControllerProvider.notifier).restart(),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      width: width.sp,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The QR is the web address, so the text under it has to read the same way.
          TvQrCodeCard(qrData: snapshot.qrData, urlText: snapshot.webAddress),
          SizedBox(height: 10.sp),
          Text(
            i18nOr(
              'remote_sync_open_hint',
              'Scan with your phone camera, then fill in the page: it applies to this TV.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: tvTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
