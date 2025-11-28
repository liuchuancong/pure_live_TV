import 'dart:convert';
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
    final SettingsService settingsService = Get.find<SettingsService>();
    return Scaffold(
      body: Obx(
        () => Stack(
          children: [
            Container(
              decoration: settingsService.currentBoxImage.isEmpty
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff141e30), Color(0xff243b55), Color(0xff141e30)],
                      ),
                    )
                  : BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(settingsService.currentBoxImage.value)),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}
