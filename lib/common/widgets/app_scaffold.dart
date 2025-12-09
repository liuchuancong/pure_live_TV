import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  const AppScaffold({required this.child, super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<SettingsService>();
    return Scaffold(
      body: Obx(() {
        final bg = service.cachedBackgroundImage;
        return Stack(
          children: [
            // 底层：始终有渐变
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff141e30), Color(0xff243b55), Color(0xff141e30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // 上层：如果有图就叠加上去
            if (bg != null)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: bg, fit: BoxFit.cover),
                ),
              ),
            Positioned.fill(child: widget.child),
          ],
        );
      }),
    );
  }
}
