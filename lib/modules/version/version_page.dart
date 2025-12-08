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
  Widget _buildDownloadSection({required String title, required String urls}) {
    final List<String> mirrorUrls = getMirrorUrls(urls);
    bool isLine1 = controller.apkUrl.value == urls;
    if (mirrorUrls.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            '暂无 $title',
            style: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(Get.context!).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            // 桌面端 4 列，移动端 2 列（更易点击）
            final int maxColumns = 4;
            const double spacing = 8.0;
            final double buttonWidth = (maxWidth - spacing * (maxColumns - 1)) / maxColumns;

            return Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: [
                for (int i = 0; i < mirrorUrls.length; i++)
                  SizedBox(
                    width: buttonWidth,
                    child: HighlightButton(
                      focusNode: isLine1 ? controller.appFocusNodes[i] : controller.appFocus2Nodes[i],
                      iconData: Icons.download_rounded,
                      text: '地址 ${i + 1}',
                      autofocus: true,
                      onTap: () {
                        downloadAndInstallApk(mirrorUrls[i]);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDownloadSection(title: 'ARM64 (arm64-v8a) 版本', urls: controller.apkUrl2.value),
                        const SizedBox(height: 24),
                        _buildDownloadSection(title: 'ARM32 (armeabi-v7a) 版本', urls: controller.apkUrl.value),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
