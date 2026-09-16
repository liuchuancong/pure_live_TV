import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The "connect your phone" card: the native sync QR (`purelive://ip:port/sync`)
/// plus the plain `ip:port` for manual entry.
///
/// One connection covers every channel — search text, cookies, tags, proxy,
/// IPTV links, danmaku filters and device sync — so the very same card is
/// embedded in each settings page that accepts phone input.
class RemoteSyncQrCard extends ConsumerWidget {
  const RemoteSyncQrCard({super.key, this.width = 260});

  /// Card width in design pixels; the player panel passes a smaller value.
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(remoteSyncControllerProvider);
    final tvTheme = context.tvTheme;

    if (!snapshot.started || snapshot.qrData.isEmpty) {
      return Container(
        width: width.sp,
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.5), width: 1.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10.sp),
            Expanded(
              child: Text(
                snapshot.error ?? i18nOr('remote_sync_starting', 'Starting the LAN sync service...'),
                style: TextStyle(fontSize: 14.sp, color: tvTheme.secondaryTextColor),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width.sp,
      child: TvQrCodeCard(qrData: snapshot.qrData, urlText: snapshot.address),
    );
  }
}
