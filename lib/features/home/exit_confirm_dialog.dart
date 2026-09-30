import 'dart:io';
import 'package:pure_live/exports/package_export.dart';

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
            style: AppTextStyles.t22.copyWith(height: 1.5, color: tvTheme.primaryTextColor),
          ),
          SizedBox(height: 24.ts(context)),
          Center(
            child: Container(
              width: 260.ts(context),
              height: 260.ts(context),
              padding: EdgeInsets.all(12.ts(context)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.ts(context))),
              child: Image.asset('assets/images/wechat.png', fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: 20.ts(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, size: 24.ts(context), color: tvTheme.focusColor),
              SizedBox(width: 8.ts(context)),
              Text(
                i18n('support_donate'),
                style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
              ),
            ],
          ),
          SizedBox(height: 12.ts(context)),
          Text(
            i18nOr('exit_donate_message', '项目全程开源免费，无任何付费门槛。若是本应用给您带来便利，欢迎微信扫码请开发者喝瓶牛奶，支持后续更新维护。'),
            textAlign: TextAlign.center,
            style: AppTextStyles.t20.copyWith(height: 1.5, color: tvTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
