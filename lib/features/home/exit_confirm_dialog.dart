import 'dart:io';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

Future<void> showExitConfirmDialog(BuildContext context, WidgetRef _) async {
  await TvDialogUtils.show<bool>(context: context, builder: (_) => const _ExitConfirmDialog());
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: i18n('confirm_exit'),
      confirmText: i18n('exit_yes'),
      cancelText: i18n('exit_no'),
      onConfirm: () => exit(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            i18nOr('exit_confirm_message', '感谢使用纯粹直播 TV，期待下次再见。'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.sp, height: 1.5, color: tvTheme.primaryTextColor),
          ),
          SizedBox(height: 24.sp),
          Center(
            child: Container(
              width: 260.sp,
              height: 260.sp,
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.sp)),
              child: Image.asset('assets/images/wechat.png', fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: 20.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, size: 24.sp, color: tvTheme.focusColor),
              SizedBox(width: 8.sp),
              Text(
                i18n('support_donate'),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: tvTheme.primaryTextColor),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Text(
            i18nOr('exit_donate_message', '项目全程开源免费，无任何付费门槛。若是本应用给您带来便利，欢迎微信扫码请开发者喝瓶牛奶，支持后续更新维护。'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, height: 1.5, color: tvTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
