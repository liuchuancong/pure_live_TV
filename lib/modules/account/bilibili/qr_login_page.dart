import 'package:dpad/dpad.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/account/bilibili/qr_login_controller.dart';

class BiliBiliQRLoginPage extends GetView<BiliBiliQRLoginController> {
  const BiliBiliQRLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: DpadRegion(
        memoryKey: 'account/bilibili_qr_login',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text("登录哔哩哔哩", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Obx(() {
                      if (controller.qrStatus.value == QRStatus.loading) {
                        return SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(strokeWidth: 6, color: theme.colorScheme.primary),
                        );
                      }
                      if (controller.qrStatus.value == QRStatus.failed) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("二维码加载失败", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            DpadFocusable(
                              effects: [
                                DpadScaleEffect(scale: 1.05),
                                DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ],
                              onSelect: () async => controller.loadQRCode(),
                              builder: (context, state, child) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: state.focused
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: state.focused ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "重试",
                                      style: TextStyle(
                                        color: state.focused
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        );
                      }
                      if (controller.qrStatus.value == QRStatus.expired) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("二维码已失效", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            DpadFocusable(
                              effects: [
                                DpadScaleEffect(scale: 1.05),
                                DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ],
                              onSelect: () async => controller.loadQRCode(),
                              builder: (context, state, child) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: state.focused
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: state.focused ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "刷新",
                                      style: TextStyle(
                                        color: state.focused
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: QrImageView(
                              data: controller.qrcodeUrl.value,
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                              size: 260,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Visibility(
                            visible: controller.qrStatus.value == QRStatus.scanned,
                            child: Text(
                              "已扫描，请在手机上确认登录",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "请使用哔哩哔哩手机客户端扫描二维码登录\n必须登录后才能观看哔哩哔哩直播",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
