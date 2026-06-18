import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/account/account_controller.dart';
import 'package:pure_live/services/settings/bilibili_account_service.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: DpadRegion(
        memoryKey: 'account/main_list',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  DpadFocusable(
                    autofocus: true,
                    effects: [
                      DpadScaleEffect(scale: 1.05),
                      DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ],
                    onSelect: () async => Navigator.of(Get.context!).pop(),
                    builder: (context, state, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.focused
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "返回",
                              style: TextStyle(
                                color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 24),
                  Text("第三方账号管理", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle("平台授权绑定"),
                  context.buildModernCard([
                    Obx(() {
                      final bool isLogin = BiliBiliAccountService.instance.logined.value;
                      return _buildAccountTile(
                        theme: theme,
                        imageAsset: 'assets/images/bilibili_2.png',
                        title: "哔哩哔哩",
                        subtitle: isLogin ? "已登录; 绑定成功" : "请扫码登录授权",
                        trailingText: isLogin ? "已登录" : null,
                        onTap: isLogin ? null : () => controller.bilibiliTap(),
                      );
                    }),
                    Obx(() {
                      final bool hasCookie = controller.settings.cookieManager.douyinCookie.isNotEmpty;
                      return _buildAccountTile(
                        theme: theme,
                        imageAsset: 'assets/images/douyin.png',
                        title: "抖音直播",
                        subtitle: hasCookie ? "已登录; 可修改TTwid" : "请输入ttwid登录",
                        onTap: () => controller.douyinTap(),
                      );
                    }),
                    Obx(() {
                      final bool hasCookie = controller.settings.cookieManager.kuaishouCookie.isNotEmpty;
                      return _buildAccountTile(
                        theme: theme,
                        imageAsset: 'assets/images/kuaishou.png',
                        title: "快手直播",
                        subtitle: hasCookie ? "已登录; 可修改Cookie" : "请输入Cookie",
                        onTap: () => controller.kuaishouTap(),
                      );
                    }),
                    _buildAccountTile(
                      theme: theme,
                      imageAsset: 'assets/images/douyu.png',
                      title: "斗鱼直播",
                      subtitle: "尚不支持",
                      enabled: false,
                    ),
                    _buildAccountTile(
                      theme: theme,
                      imageAsset: 'assets/images/huya.png',
                      title: "虎牙直播",
                      subtitle: "尚不支持",
                      enabled: false,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required ThemeData theme,
    required String imageAsset,
    required String title,
    required String subtitle,
    String? trailingText,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return DpadFocusable(
      enabled: enabled,
      effects: [
        DpadScaleEffect(scale: 1.02),
        DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
      ],
      onSelect: () async => onTap?.call(),
      builder: (context, state, child) {
        return Container(
          color: state.focused ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Opacity(opacity: enabled ? 1.0 : 0.4, child: Image.asset(imageAsset, width: 32, height: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: !enabled
                            ? theme.colorScheme.onSurface.withOpacity(0.4)
                            : (state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: !enabled
                            ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                            : (state.focused
                                  ? theme.colorScheme.primary.withOpacity(0.7)
                                  : theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                trailingText != null
                    ? Text(
                        trailingText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: state.focused
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
