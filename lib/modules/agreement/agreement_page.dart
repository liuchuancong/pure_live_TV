import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/widgets/tv_page.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/theme/styles/app_styles.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TvPage(
      child: Center(
        child: SizedBox(
          width: 1200.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("使用须知", textAlign: TextAlign.center, style: AppTextStyles.t40W700),
              AppStyle.vGap40,
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("欢迎使用纯粹直播 TV，请在使用前仔细阅读以下内容：", style: AppTextStyles.t28W700),
                      AppStyle.vGap24,

                      Padding(
                        padding: EdgeInsets.only(left: 28.0.sp, right: 8.0.sp),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text("1. 本软件为开源软件，仅供学习交流使用，禁止用于任何商业用途。", style: AppTextStyles.t32),
                            AppStyle.vGap16,
                            Text("2. 本软件不提供任何直播内容，所有直播内容均来自网络。", style: AppTextStyles.t32),
                            AppStyle.vGap16,
                            Text("3. 本软件完全基于您个人意愿使用，您应该对自己的使用行为和所有结果承担全部责任。", style: AppTextStyles.t32),
                            AppStyle.vGap16,
                            Text("4. 如果本软件存在侵犯您的合法权益的情况，请及时与作者联系，作者将会及时删除有关内容。", style: AppTextStyles.t32),
                          ],
                        ),
                      ),
                      AppStyle.vGap32,

                      Text("如您继续使用本软件即代表您已完全理解并同意上述内容。", style: AppTextStyles.t28W700),
                    ],
                  ),
                ),
              ),
              AppStyle.vGap48,

              // 3. 底部按钮操作区：保持常驻显示，方便遥控器快速选定焦点
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TvButton(
                    autofocus: true,
                    title: "已阅读并同意",
                    size: TvButtonSize.medium,
                    onTap: () {
                      SettingsService.to.startup.setIsFirstInApp(false);
                      context.go('/');
                    },
                  ),
                  AppStyle.hGap32,
                  TvButton(title: "退出应用", size: TvButtonSize.medium, isSecondary: true, onTap: () => exit(0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
