import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';
import 'package:pure_live/modules/account/account_controller.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("三方认证"),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "哔哩哔哩账号需要登录才能看高清晰度的直播，其他平台暂无此限制。",
              textAlign: TextAlign.center,
            ),
          ),
          Obx(
            () => ListTile(
              leading: Image.asset(
                'assets/images/bilibili_2.png',
                width: 36,
                height: 36,
              ),
              title: const Text("哔哩哔哩"),
              subtitle: Text(BiliBiliAccountService.instance.name.value),
              trailing: BiliBiliAccountService.instance.logined.value
                  ? const Icon(Icons.logout)
                  : const Icon(Icons.chevron_right),
              onTap: controller.bilibiliTap,
            ),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/douyu.png',
              width: 36,
              height: 36,
            ),
            title: const Text("斗鱼直播"),
            subtitle: const Text("尚不支持"),
            enabled: false,
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/huya.png',
              width: 36,
              height: 36,
            ),
            title: const Text("虎牙直播"),
            subtitle: const Text("尚不支持"),
            enabled: false,
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/douyin.png',
              width: 36,
              height: 36,
            ),
            title: const Text("抖音直播"),
            subtitle: const Text("尚不支持"),
            enabled: false,
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
