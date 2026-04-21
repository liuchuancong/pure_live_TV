import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_preview_page.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_preview_binding.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_page_controller.dart';

class WallpaperPage extends GetView<WallpaperPageController> {
  const WallpaperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppScaffold(
        child: Stack(
          children: [
            // 1. 顶部面板
            _buildAnimatePanel(
              isTop: true,
              child: Row(
                children: [
                  HighlightButton(
                    focusNode: controller.backNode,
                    iconData: Icons.arrow_back,
                    text: "返回",
                    onTap: () => Get.back(),
                  ),
                  AppStyle.hGap32,
                  _buildShadowText("壁纸设置", fontSize: 32.w),
                ],
              ),
            ),
            Obx(
              () => controller.isLoading.value
                  ? Center(
                      child: SizedBox(
                        width: 48.w,
                        height: 48.w,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4.w),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            // 2. 底部操作面板 (Column 结构)
            _buildAnimatePanel(
              isTop: false,
              child: Container(
                padding: AppStyle.edgeInsetsA24,
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24.w)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 壁纸源选择器
                    Obx(
                      () => SettingsItemWidget(
                        focusNode: controller.sourceNode,
                        title: "壁纸源选择",
                        items: controller.getBoxImageItemsMap(),
                        value: AppConsts.currentBoxImageSources[controller.currentBoxImageIndex.value].keys.first,
                        onChanged: (key) {
                          int index = AppConsts.currentBoxImageSources.indexWhere((e) => e.containsKey(key));
                          controller.currentBoxImageIndex.value = index;
                        },
                      ),
                    ),

                    AppStyle.vGap24, // 间距
                    // 2. 填充模式选择 (新增项)
                    Obx(
                      () => SettingsItemWidget(
                        focusNode: controller.fitNode, // 需要在 controller 定义此 node
                        title: "填充模式",
                        items: controller.getFitItems(), // 返回 7 种模式的 Map
                        value: controller.settingsService.backgroundImageFitIndex.value,
                        onChanged: (index) {
                          controller.settingsService.setBoxFitIndex(index as int);
                        },
                      ),
                    ),

                    AppStyle.vGap24, // 间距
                    // 3. 功能按钮行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HighlightButton(
                          focusNode: controller.refreshNode,
                          iconData: Icons.change_circle_rounded,
                          text: "切换图片",
                          onTap: () => controller.getImage(),
                        ),
                        AppStyle.hGap48,
                        HighlightButton(
                          focusNode: controller.previewNode,
                          iconData: Icons.fullscreen_rounded,
                          text: "全屏欣赏",
                          onTap: () {
                            Get.to(() => const WallpaperPreviewPage(), bindings: [WallpaperPreviewBinding()]);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatePanel({required bool isTop, required Widget child}) {
    return Obx(() {
      bool visible = !controller.isFullScreen.value;
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        // 根据布局高度微调隐藏位置
        top: isTop ? (visible ? 40.w : -160.w) : null,
        bottom: !isTop ? (visible ? 48.w : -350.w) : null,
        left: 48.w,
        right: 48.w,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !visible,
            child: Visibility(visible: visible, maintainState: true, child: child),
          ),
        ),
      );
    });
  }

  Widget _buildShadowText(String text, {double? fontSize}) {
    return Text(
      text,
      style: AppStyle.titleStyleWhite.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [const Shadow(blurRadius: 12, color: Colors.black)],
      ),
    );
  }
}
