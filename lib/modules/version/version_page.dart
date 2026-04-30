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

  // 修改：增加 focusNodes 参数以适配不同版本
  Widget _buildDownloadSection({required String title, required String urls, required List<AppFocusNode> focusNodes}) {
    final List<String> mirrorUrls = getMirrorUrls(urls);
    if (mirrorUrls.isEmpty) return const SizedBox.shrink();

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
            const int maxColumns = 4;
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
                      // 修改：直接使用传入的 focusNodes
                      focusNode: i < focusNodes.length ? focusNodes[i] : AppFocusNode(),
                      iconData: Icons.download_rounded,
                      text: '地址 ${i + 1}',
                      onTap: () => downloadAndInstallApk(mirrorUrls[i]),
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
                    if (controller.scrollController.hasClients) {
                      controller.scrollController.jumpTo(0);
                    }
                  }
                },
                onTap: () => Navigator.of(Get.context!).pop(),
              ),
              AppStyle.hGap32,
              Text(
                "版本更新",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  controller: controller.scrollController,
                  children: [
                    _buildUpdateNotes(),
                    // 1. 标准版 - ARM64
                    _buildDownloadSection(
                      title: '标准版 - ARM64 (v8a)',
                      urls: controller.apkUrlv8.value,
                      focusNodes: controller.appFocusNodesV8,
                    ),
                    const SizedBox(height: 24),

                    // 2. 标准版 - ARM32
                    _buildDownloadSection(
                      title: '标准版 - ARM32 (v7a)',
                      urls: controller.apkUrlv7.value,
                      focusNodes: controller.appFocusNodesV7,
                    ),
                    const SizedBox(height: 24),

                    // 3. 精简版 - ARM64 (without-exo)
                    _buildDownloadSection(
                      title: '精简版 (No-Exo) - ARM64',
                      urls: controller.apkUrlv8Exo.value,
                      focusNodes: controller.appFocusNodesV8Exo,
                    ),
                    const SizedBox(height: 24),

                    // 4. 精简版 - ARM32 (without-exo)
                    _buildDownloadSection(
                      title: '精简版 (No-Exo) - ARM32',
                      urls: controller.apkUrlv7Exo.value,
                      focusNodes: controller.appFocusNodesV7Exo,
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
