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
              Text(
                "帮助与支持",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          AppStyle.vGap48,
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: AppStyle.edgeInsetsA32,
                    child: Text(
                      "感谢您的使用！",
                      style: AppStyle.titleStyleWhite,
                    ),
                  ),
                  AppStyle.vGap48,
                  Padding(
                    padding: AppStyle.edgeInsetsA32,
                    child: Text(
                      "如果您觉得有更好的建议或者意见，欢迎您联系我们。",
                      style: AppStyle.titleStyleWhite,
                    ),
                  ),
                  Padding(
                    padding: AppStyle.edgeInsetsA32,
                    child: Text(
                      "QQ群：920447827",
                      style: AppStyle.titleStyleWhite.copyWith(
                        fontSize: 36.w,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]),
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
