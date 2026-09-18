import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';

/// The pairing QR of the device sync page: this TV's sync endpoint, to be scanned
/// by the PureLive mobile app (not by a camera app).
///
/// The payload is `purelive://ip:39888/sync` ([TvSyncProtocol.createQrUri]). The
/// app scans it, parses `ip:port` and pushes/pulls settings over the sync
/// protocol. This is *not* the web-form entry — that is the 8888 web remote.
class RemoteSyncPairQrCard extends ConsumerWidget {
  const RemoteSyncPairQrCard({super.key, this.width = 280});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(remoteSyncControllerProvider);
    final tvTheme = context.tvTheme;

    if (!snapshot.started || snapshot.qrData.isEmpty) {
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
          TvQrCodeCard(qrData: snapshot.qrData, urlText: snapshot.qrData),
          SizedBox(height: 10.sp),
          Text(
            i18nOr('remote_sync_pair_hint', 'Open PureLive on your phone and scan this code to sync settings.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: tvTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
