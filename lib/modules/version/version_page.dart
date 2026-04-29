import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/app_scaffold.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:pure_live/modules/version/version_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class VersionPage extends GetView<VersionController> {
  const VersionPage({super.key});
  Widget _buildUpdateNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: MarkdownBody(
            data: controller.updateNotes.value.replaceAll('\\n', '\n'),
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Colors.white, fontSize: 24.sp),
              pPadding: EdgeInsets.only(bottom: 8.h),
              h1: const TextStyle(color: Colors.white),
              h2: const TextStyle(color: Colors.white),
              listBullet: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadSection({required String title, required String urls, required bool isArmV7a}) {
    final List<String> mirrorUrls = getMirrorUrls(urls);
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
                      focusNode: isArmV7a
                          ? (i < controller.appFocusNodes.length ? controller.appFocusNodes[i] : AppFocusNode())
                          : (i < controller.appFocus2Nodes.length ? controller.appFocus2Nodes[i] : AppFocusNode()),
                      // ------------------------------------------
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
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    controller.scrollController.jumpTo(0);
                  }
                },
                onTap: () {
                  // Kept your original logic
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  controller: controller.scrollController,
                  children: [
                    _buildUpdateNotes(),
                    const SizedBox(height: 24),
                    _buildDownloadSection(
                      title: 'ARM64 (arm64-v8a) 版本',
                      urls: controller.apkUrl2.value,
                      isArmV7a: false,
                    ),
                    const SizedBox(height: 24),
                    _buildDownloadSection(
                      title: 'ARM32 (armeabi-v7a) 版本',
                      urls: controller.apkUrl.value,
                      isArmV7a: true,
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
