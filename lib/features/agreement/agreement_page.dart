import 'dart:io';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/services/settings/settings.dart';

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
              Text(
                i18n('agreement_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.t40.copyWith(fontWeight: FontWeight.w700),
              ),
              AppStyle.vGap40(context),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(i18n('agreement_welcome'), style: AppTextStyles.t28.copyWith(fontWeight: FontWeight.w700)),
                      AppStyle.vGap24(context),

                      Padding(
                        padding: EdgeInsets.only(left: 28.0.sp, right: 8.0.sp),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(i18n('agreement_item_1'), style: AppTextStyles.t32),
                            AppStyle.vGap16(context),
                            Text(i18n('agreement_item_2'), style: AppTextStyles.t32),
                            AppStyle.vGap16(context),
                            Text(i18n('agreement_item_3'), style: AppTextStyles.t32),
                            AppStyle.vGap16(context),
                            Text(i18n('agreement_item_4'), style: AppTextStyles.t32),
                          ],
                        ),
                      ),
                      AppStyle.vGap32(context),

                      Text(i18n('agreement_footer'), style: AppTextStyles.t28.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              AppStyle.vGap48(context),

              // The action row stays visible so a remote can always reach both
              // buttons without scrolling the terms.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TvButton(
                    autofocus: true,
                    title: i18n('agreement_accept'),
                    size: TvButtonSize.medium,
                    onTap: () {
                      SettingsService.to.startup.setIsFirstInApp(false);
                      const HomeRoute().go(context);
                    },
                  ),
                  AppStyle.hGap32(context),
                  TvButton(title: i18n('exit_app'), size: TvButtonSize.medium, isSecondary: true, onTap: () => exit(0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
