import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';
import 'package:pure_live/modules/account/kuaishou/kuaishou_cookie_controller.dart';

class KuaishouCookiePage extends GetView<KuaishouCookieController> {
  const KuaishouCookiePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: DpadRegion(
        memoryKey: 'account/kuaishou_cookie_page',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: Row(
                children: [
                  _buildQRCodeSection(theme),
                  Container(
                    width: 2,
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, theme.colorScheme.onSurface.withOpacity(0.1), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  _buildInputSection(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          DpadFocusable(
            autofocus: true,
            effects: [
              DpadScaleEffect(scale: 1.05),
              DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
            ],
            onSelect: () async => Get.back(),
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
          Text("快手cookie设置", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: controller.fullServerUrl.value.isNotEmpty
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.fullServerUrl.value.isNotEmpty ? "局域网服务已启动" : "服务未启动",
                style: TextStyle(
                  color: controller.fullServerUrl.value.isNotEmpty ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(ThemeData theme) {
    return Expanded(
      flex: 4,
      child: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.fullServerUrl.value.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: QrImageView(
                  data: controller.fullServerUrl.value,
                  version: QrVersions.auto,
                  size: 240,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text("扫码远程录入", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.fullServerUrl.value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 14,
                    fontFamily: "monospace",
                  ),
                ),
              ),
            ] else
              CircularProgressIndicator(color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Expanded(
      flex: 6,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "在此粘贴或输入快手cookie",
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AndroidTVTextField(
              focusNode: FocusNode(),
              controller: controller.cookieInputController,
              hint: "等待手机扫码同步或点击输入...",
              textColor: theme.colorScheme.onSurface,
              maxLines: 3,
              height: 120,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              onSubmitted: (e) => controller.setCookies(e),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildActionButton(
                  theme: theme,
                  icon: Icons.settings,
                  label: "设置cookie",
                  isPrimary: true,
                  onTap: () => controller.setCookies(controller.cookieInputController.text),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  theme: theme,
                  icon: Icons.cleaning_services_rounded,
                  label: "清空",
                  isPrimary: false,
                  onTap: () => controller.cookieInputController.clear(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return DpadFocusable(
      effects: [
        DpadScaleEffect(scale: 1.05),
        DpadGlowEffect(color: (isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface).withOpacity(0.3)),
      ],
      onSelect: () async => onTap(),
      builder: (context, state, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: state.focused
                ? (isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.15))
                : (isPrimary
                      ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                      : theme.colorScheme.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: state.focused
                  ? (isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: state.focused
                    ? (isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary)
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: state.focused
                      ? (isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
