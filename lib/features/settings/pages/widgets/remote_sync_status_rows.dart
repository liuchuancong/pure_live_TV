import 'package:pure_live/exports/package_export.dart';

/// Status colours shared by the service pill and the receive notice.
const Color remoteSyncOkColor = Color(0xFF4CAF50);
const Color remoteSyncFailColor = Color(0xFFEF5350);

/// The 6-digit code every settings request must carry. Shown large: it is read
/// off the screen and typed on the other device.
class RemoteSyncPairingCodeRow extends StatelessWidget {
  const RemoteSyncPairingCodeRow({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Row(
      children: [
        Icon(Icons.pin_rounded, size: 22.ts(context), color: theme.secondaryTextColor),
        SizedBox(width: 10.ts(context)),
        Text(
          i18n('remote_sync_pairing_code'),
          style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor),
        ),
        SizedBox(width: 12.ts(context)),
        Text(
          code,
          style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w700, color: theme.focusColor, letterSpacing: 4),
        ),
      ],
    );
  }
}

/// Service status pill: dot + address/error + running label.
class RemoteSyncServiceStatusPill extends StatelessWidget {
  const RemoteSyncServiceStatusPill({super.key, required this.started, required this.address, required this.error});

  final bool started;
  final String address;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final running = started;
    final Color badgeColor = running ? remoteSyncOkColor : remoteSyncFailColor;
    final String label = running ? i18n('ui_running') : i18n('ui_stopped');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 10.ts(context)),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.ts(context)),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.ts(context),
            height: 10.ts(context),
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.ts(context)),
          Flexible(
            child: Text(
              running ? address : (error ?? i18nOr('remote_sync_starting', 'Starting the LAN sync service...')),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: theme.primaryTextColor),
            ),
          ),
          SizedBox(width: 12.ts(context)),
          Text(
            label,
            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: badgeColor),
          ),
        ],
      ),
    );
  }
}

/// Result of the last inbound settings push, kept on screen after the toast.
class RemoteSyncReceiveNoticeRow extends StatelessWidget {
  const RemoteSyncReceiveNoticeRow({super.key, required this.notice, required this.ok});

  final String notice;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? remoteSyncOkColor : remoteSyncFailColor;
    return Row(
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 20.ts(context), color: color),
        SizedBox(width: 8.ts(context)),
        Expanded(
          child: Text(
            notice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}

/// Guide step row: icon + description.
class RemoteSyncStepBullet extends StatelessWidget {
  const RemoteSyncStepBullet({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30.ts(context),
          height: 30.ts(context),
          decoration: BoxDecoration(
            color: theme.focusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8.ts(context)),
          ),
          child: Icon(icon, size: 17.ts(context), color: theme.focusColor),
        ),
        SizedBox(width: 12.ts(context)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.sp),
            child: Text(
              text,
              style: AppTextStyles.t18.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.secondaryTextColor,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
