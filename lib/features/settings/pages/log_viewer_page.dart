import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// "View logs in a browser" — the page behind the backup & restore row.
///
/// A TV has no browser: the web remote serves the log viewer at
/// [WebRemoteRouter.log] (with `/api/log/download` behind it), so this page
/// hands the address over as a QR code plus the plain URL — scan it with a
/// phone or type it into a PC on the same LAN.
///
/// The card also boots the web server itself: this page may be the first
/// remote surface the user opens after launch, and nothing else guarantees a
/// start ([RemoteSyncQrCard] owns the start/retry/error rendering).
class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('view_logs_in_browser')),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.sp),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20.sp),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RemoteSyncQrCard(width: 320, route: WebRemoteRouter.log),
              SizedBox(width: 28.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepBullet(
                      icon: Icons.qr_code_scanner_rounded,
                      text: i18nOr(
                        'log_viewer_step_scan',
                        'Scan the QR code with a phone, or open the address above in a browser on the same LAN',
                      ),
                    ),
                    SizedBox(height: 10.sp),
                    _StepBullet(
                      icon: Icons.visibility_outlined,
                      text: i18nOr('log_viewer_step_view', 'The page shows the runtime log and offers a download'),
                    ),
                    SizedBox(height: 10.sp),
                    _StepBullet(
                      icon: Icons.description_outlined,
                      text: i18nOr('log_viewer_step_enable', 'Nothing to view until local logging is enabled in log management'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One icon + text line of the instruction column; text wraps freely.
class _StepBullet extends StatelessWidget {
  const _StepBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: theme.focusColor),
        SizedBox(width: 10.sp),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.t14W500.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}
