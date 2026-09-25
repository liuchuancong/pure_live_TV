import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Phone page for downloading and importing a backup.
///
/// A TV has no file system to hand, so the QR opens the web remote's sync page,
/// where the same backup file can be downloaded or uploaded back into the TV —
/// the only way in for a file that never landed in this device's backup folder.
///
/// Nothing here is focusable: the QR is scanned with a phone and the rest is a
/// line of text, so the page has no rows of its own.
class BackupBrowserSectionPage extends StatelessWidget {
  const BackupBrowserSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RemoteSyncQrCard(width: 320, route: WebRemoteRouter.sync)),
          SizedBox(height: 20.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: Center(
              child: Text(
                i18n('backup_browser_hint'),
                style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
