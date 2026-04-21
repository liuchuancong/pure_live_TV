import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/wallpaper/wallpaper_preview_controller.dart';

class WallpaperPreviewPage extends GetView<WallpaperPreviewController> {
  const WallpaperPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => controller.handleKeyEvent(event),
      child: AppScaffold(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 底部操作提示
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
            Positioned(
              bottom: 40.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30.w)),
                child: Text(
                  "↑↓ 切换图片  ·  返回键退出预览",
                  style: TextStyle(color: Colors.white70, fontSize: 20.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
