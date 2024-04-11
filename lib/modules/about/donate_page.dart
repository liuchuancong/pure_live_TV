import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap32,
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
                  Get.back();
                },
              ),
              AppStyle.hGap32,
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          AppStyle.vGap48,
          Expanded(
            child: Center(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "感谢您的支持！",
                        style: AppStyle.titleStyleWhite,
                      ),
                    ),
                    AppStyle.vGap16,
                    Text(
                      "如果您觉得本软件对您有帮助，欢迎微信扫码或支付宝捐赠。",
                      style: AppStyle.titleStyleWhite,
                    ),
                    Text(
                      "支付宝:17792321552",
                      style: AppStyle.titleStyleWhite.copyWith(
                        fontSize: 36.w,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppStyle.vGap16,
                    const WechatItem(),
                  ]),
            ),
          )
        ],
      ),
    );
  }
}

class WechatItem extends StatelessWidget {
  const WechatItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300.w,
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/images/wechat.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
