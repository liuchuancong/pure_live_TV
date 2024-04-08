import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pure_live/common/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final controller = GroupButtonController();
  final pageController = GroupButtonController();
  String currentDateTime = '';
  @override
  void initState() {
    super.initState();
    getCurrentChineseDateTime();
  }

  void getCurrentChineseDateTime() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      DateTime now = DateTime.now();
      DateFormat formatter = DateFormat('yyyy年MM月dd日 HH:mm:ss', 'zh_CN');
      setState(() {
        currentDateTime = formatter.format(now);
      });
    });
  }

  handleMainPageButtonTap(int index) {
    controller.unselectAll();
    pageController.unselectAll();
    controller.selectIndex(index);
    switch (index) {
      case 0:
        Get.toNamed(RoutePath.kFavorite);
        break;
      case 1:
        Get.toNamed(RoutePath.kPopular);
        break;
      case 2:
        Get.toNamed(RoutePath.kAreas);
        break;
      case 3:
        Get.toNamed(RoutePath.kSearch);
        break;
      default:
    }
  }

  handleRoutePageButtonTap(int index) {
    controller.unselectAll();
    pageController.unselectAll();
    pageController.selectIndex(index);
    switch (index) {
      case 0:
        Get.toNamed(RoutePath.kHistory);
        break;
      case 1:
        Get.toNamed(RoutePath.kSettingsAccount);
        break;
      case 2:
        Get.toNamed(RoutePath.kSettings);
        break;
      case 3:
        Get.toNamed(RoutePath.kSearch);
        break;
      case 4:
        Get.toNamed(RoutePath.kSettingsHotAreas);
        break;
      case 5:
        Get.toNamed(RoutePath.kDonate);
        break;
      case 6:
        Get.toNamed(RoutePath.kAbout);
        break;

      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('纯粹直播'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: Text(
              currentDateTime,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GroupButton(
                controller: controller,
                isRadio: false,
                options: GroupButtonOptions(
                  selectedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  unselectedTextStyle: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  spacing: 12,
                  runSpacing: 10,
                  groupingType: GroupingType.wrap,
                  direction: Axis.horizontal,
                  borderRadius: BorderRadius.circular(20),
                  mainGroupAlignment: MainGroupAlignment.start,
                  crossGroupAlignment: CrossGroupAlignment.start,
                  groupRunAlignment: GroupRunAlignment.start,
                  textAlign: TextAlign.center,
                  textPadding: EdgeInsets.zero,
                  alignment: Alignment.center,
                ),
                buttons: const ["关注", "热门", "分区", "搜索"],
                maxSelected: 1,
                onSelected: (val, i, selected) => handleMainPageButtonTap(i)),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: GroupButton(
                controller: pageController,
                isRadio: false,
                options: GroupButtonOptions(
                  selectedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                  unselectedTextStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  spacing: 12,
                  runSpacing: 10,
                  groupingType: GroupingType.wrap,
                  direction: Axis.horizontal,
                  borderRadius: BorderRadius.circular(4),
                  mainGroupAlignment: MainGroupAlignment.start,
                  crossGroupAlignment: CrossGroupAlignment.start,
                  groupRunAlignment: GroupRunAlignment.start,
                  textAlign: TextAlign.center,
                  textPadding: EdgeInsets.zero,
                  alignment: Alignment.center,
                ),
                buttons: const ["历史", "账户", "设置", "推送", "平台", "捐赠", "关于"],
                maxSelected: 1,
                onSelected: (val, i, selected) => handleRoutePageButtonTap(i)),
          ),
        ],
      ),
    );
  }
}
