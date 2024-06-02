import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:pure_live/common/widgets/app_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/modules/account/account_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap32,
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
                "哔哩哔哩账号需要登录才能看高清晰度的直播，其他平台暂无此限制。",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          AppStyle.vGap48,
          Obx(() => HighlightListTile(
                leading: Image.asset(
                  'assets/images/bilibili_2.png',
                  width: 36,
                  height: 36,
                ),
                title: "哔哩哔哩",
                trailing: BiliBiliAccountService.instance.logined.value
                    ? Obx(() => Text(
                          '已登录',
                          style: TextStyle(color: controller.nodes[0].isFoucsed.value ? Colors.black : Colors.white),
                        ))
                    : const Icon(Icons.chevron_right),
                focusNode: controller.nodes[0],
                onTap: () {
                  BiliBiliAccountService.instance.logined.value ? null : controller.bilibiliTap();
                },
              )),
          HighlightListTile(
            leading: Image.asset(
              'assets/images/douyu.png',
              width: 36,
              height: 36,
            ),
            title: "斗鱼直播",
            trailing: const Icon(Icons.chevron_right),
            focusNode: controller.nodes[1],
            subtitle: "尚不支持",
            onTap: () {},
          ),
          HighlightListTile(
            leading: Image.asset(
              'assets/images/huya.png',
              width: 36,
              height: 36,
            ),
            title: "虎牙直播",
            trailing: const Icon(Icons.chevron_right),
            focusNode: controller.nodes[2],
            subtitle: "尚不支持",
            onTap: () {},
          ),
          HighlightListTile(
            leading: Image.asset(
              'assets/images/douyin.png',
              width: 36,
              height: 36,
            ),
            title: "抖音直播",
            trailing: const Icon(Icons.chevron_right),
            focusNode: controller.nodes[3],
            subtitle: "尚不支持",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
