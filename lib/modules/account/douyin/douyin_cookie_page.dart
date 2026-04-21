import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/modules/account/douyin/douyin_cookie_controller.dart';

class DouyinCookiePage extends GetView<DouyinCookiePageController> {
  const DouyinCookiePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              AppStyle.vGap32,
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    // 左侧：深色卡片包裹二维码
                    _buildQRCodeSection(),
                    // 渐变分割线
                    Container(
                      width: 2.w,
                      height: 300.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.white12, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // 右侧：输入区域
                    _buildInputSection(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48.w),
      child: Row(
        children: [
          HighlightButton(
            focusNode: AppFocusNode(),
            iconData: Icons.arrow_back,
            text: "返回",
            autofocus: true,
            onTap: () => Get.back(),
          ),
          AppStyle.hGap32,
          Text(
            "抖音TTwid设置",
            style: AppStyle.titleStyleWhite.copyWith(fontSize: 38.w, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const Spacer(),
          // 状态指示器
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: controller.fullServerUrl.value.isNotEmpty
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Text(
                controller.fullServerUrl.value.isNotEmpty ? "局域网服务已启动" : "服务未启动",
                style: TextStyle(
                  color: controller.fullServerUrl.value.isNotEmpty ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 20.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Expanded(
      flex: 4,
      child: Obx(
        () => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.fullServerUrl.value.isNotEmpty) ...[
              // 二维码外框装饰
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.w),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20.w, offset: const Offset(0, 10))],
                ),
                child: QrImageView(
                  data: controller.fullServerUrl.value,
                  version: QrVersions.auto,
                  size: 320.w,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              AppStyle.vGap32,
              Text(
                "扫码远程录入",
                style: AppStyle.textStyleWhite.copyWith(fontSize: 30.w, fontWeight: FontWeight.bold),
              ),
              AppStyle.vGap12,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8.w)),
                child: Text(
                  controller.fullServerUrl.value,
                  style: TextStyle(color: Colors.white38, fontSize: 28.w, fontFamily: "monospace"),
                ),
              ),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Expanded(
      flex: 6,
      child: Padding(
        padding: EdgeInsets.all(48.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "在此粘贴或输入TTwid",
              style: AppStyle.textStyleWhite.copyWith(fontSize: 28.w, color: Colors.white70),
            ),
            AppStyle.vGap24,
            // 输入框容器
            AndroidTVTextField(
              focusNode: AppFocusNode(),
              controller: controller.cookieInputController,
              hint: "等待手机扫码同步或点击输入...",
              textColor: Colors.white,
              maxLines: 3,
              height: 160.h,
              backgroundColor: Get.theme.primaryColor, // 对应你之前的颜色
              onSubmitted: (e) => controller.setTTwid(e),
            ),
            AppStyle.vGap40,
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.settings,
                  label: "设置TTwid",
                  color: Get.theme.primaryColor,
                  onTap: () => controller.setTTwid(controller.cookieInputController.text),
                ),
                AppStyle.hGap24,
                _buildActionButton(
                  icon: Icons.cleaning_services_rounded,
                  label: "清空",
                  color: Colors.white12,
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
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HighlightButton(focusNode: AppFocusNode(), iconData: icon, text: label, onTap: onTap);
  }
}
