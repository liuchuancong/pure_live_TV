import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/app_scaffold.dart';
import 'package:pure_live/modules/version/version_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class VersionPage extends GetView<VersionController> {
  const VersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap48,
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.arrow_back,
                text: "返回",
                autofocus: true,
                onTap: () {
                  Navigator.of(Get.context!).pop();
                },
              ),
              AppStyle.hGap32,
              Text(
                "版本更新",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
            ],
          ),
          AppStyle.vGap24,
          Expanded(
            child: Obx(
              () => !controller.hasNewVersion.value
                  ? Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text("暂无新版本", style: AppStyle.textStyleWhite)],
                      ),
                    )
                  : Column(
                      spacing: 20,
                      children: [
                        ...getMirrorUrls(controller.apkUrl.value).asMap().entries.map((entry) {
                          int index = entry.key;
                          String url = entry.value;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppStyle.vGap32,
                              HighlightButton(
                                focusNode: controller.appFocusNodes[index],
                                iconData: Icons.download_rounded,
                                text: '下载地址 ${index + 1}',
                                autofocus: true,
                                onTap: () {
                                  downloadAndInstallApk(url);
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
