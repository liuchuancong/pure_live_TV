import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/app_scaffold.dart';
import 'package:pure_live/modules/sync/sync_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class SyncPage extends GetView<SyncController> {
  const SyncPage({super.key});

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
                  Get.back();
                },
              ),
              AppStyle.hGap32,
              Text(
                "数据同步",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          AppStyle.vGap24,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () => Visibility(
                    visible: controller.settingServer.webPortEnable.value,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: QrImageView(
                        data:
                            'http://${controller.ipAddress.value}:${controller.settingServer.webPort.value}/pure_live/',
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        padding: AppStyle.edgeInsetsA24,
                        size: 420.0.w,
                      ),
                    ),
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => Visibility(
                    visible: controller.settingServer.webPortEnable.value,
                    child: Text(
                      '服务已启动：http://${controller.ipAddress.value}:${controller.settingServer.webPort.value}/pure_live/',
                      style: AppStyle.textStyleWhite,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: !controller.settingServer.webPortEnable.value,
                    child: Text(
                      'HTTP服务未启动：${controller.settingServer.httpErrorMsg.value}，请尝试重启应用',
                      style: AppStyle.textStyleWhite,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                AppStyle.vGap12,
                Obx(
                  () => Visibility(
                    visible: controller.settingServer.webPortEnable.value,
                    child: Text(
                      "请使用手机扫描上方二维码\n建立连接后可在浏览器端选择需要同步至TV端的数据",
                      style: AppStyle.textStyleWhite,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
