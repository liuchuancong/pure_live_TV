import 'dart:io';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/exit_settings/exit_settings_controller.dart';

/// Asks before the app exits, with the donation note inside.
///
/// Back on the home page pops nothing (the page sits at the route root), so the
/// pop is the exit gesture; when 退出不再询问 was ticked earlier the exit is
/// immediate. Confirming persists the tick and leaves via `exit(0)`.
Future<void> showExitConfirmDialog(BuildContext context, WidgetRef ref) async {
  // The stored preference wins: the user asked not to be asked again.
  if (ref.read(exitSettingsControllerProvider).dontAskExit) {
    exit(0);
  }

  await TvDialogUtils.show<bool>(
    context: context,
    builder: (_) => const _ExitConfirmDialog(),
  );
}

class _ExitConfirmDialog extends ConsumerStatefulWidget {
  const _ExitConfirmDialog();

  @override
  ConsumerState<_ExitConfirmDialog> createState() => _ExitConfirmDialogState();
}

class _ExitConfirmDialogState extends ConsumerState<_ExitConfirmDialog> {
  bool _dontAskAgain = false;

  void _exit() {
    if (_dontAskAgain) {
      ref.read(exitSettingsControllerProvider.notifier).setDontAskExit(true);
    }
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: i18n('confirm_exit'),
      confirmText: i18n('exit_yes'),
      cancelText: i18n('exit_no'),
      onConfirm: _exit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            i18nOr('exit_confirm_message', '感谢使用纯粹直播 TV，期待下次再见。'),
            style: TextStyle(
              fontSize: 22.sp,
              height: 1.5,
              color: tvTheme.primaryTextColor,
            ),
          ),
          SizedBox(height: 20.sp),
          // The donation note rides in the exit dialog: the one moment every
          // user looks at a full-screen app message.
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: tvTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16.sp),
              border: Border.all(
                color: tvTheme.focusColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120.sp,
                  height: 120.sp,
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Image.asset(
                    'assets/images/wechat.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 20.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 20.sp,
                            color: tvTheme.focusColor,
                          ),
                          SizedBox(width: 6.sp),
                          Text(
                            i18n('support_donate'),
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: tvTheme.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.sp),
                      Text(
                        i18nOr(
                          'exit_donate_message',
                          '项目全程开源免费，无任何付费门槛。若是本应用给您带来便利，欢迎微信扫码请开发者喝瓶牛奶，支持后续更新维护。',
                        ),
                        style: TextStyle(
                          fontSize: 16.sp,
                          height: 1.5,
                          color: tvTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.sp),
          TvButton(
            title: i18n('exit_without_ask'),
            size: TvButtonSize.mini,
            isSecondary: !_dontAskAgain,
            selected: _dontAskAgain,
            icon: Icon(
              _dontAskAgain
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 22.sp,
            ),
            onTap: () => setState(() => _dontAskAgain = !_dontAskAgain),
          ),
        ],
      ),
    );
  }
}
