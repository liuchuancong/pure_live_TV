import 'site/huya_site.dart';
import 'package:get/get.dart';
import 'site/douyu_site.dart';
import 'site/douyin_site.dart';
import 'interface/live_site.dart';
import 'package:pure_live/core/sign/douyu.dart';
import 'package:pure_live/core/sign/douyin.dart';
import 'package:pure_live/core/site/cc_site.dart';
import 'package:pure_live/core/site/iptv_site.dart';
import 'package:pure_live/core/site/bilibili_site.dart';
import 'package:pure_live/core/site/kuaishou_site.dart';
import 'package:pure_live/common/services/settings_service.dart';

class Sites {
  static const String allSite = "all";
  static const String bilibiliSite = "bilibili";
  static const String douyuSite = "douyu";
  static const String huyaSite = "huya";
  static const String douyinSite = "douyin";
  static const String kuaishouSite = "kuaishou";
  static const String ccSite = "cc";
  static const String iptvSite = "iptv";
  static List<Site> supportSites = [
    Site(id: "bilibili", name: "哔哩", logo: "assets/images/bilibili_2.png", liveSite: BiliBiliSite()),
    Site(
      id: "douyu",
      name: "斗鱼",
      logo: "assets/images/douyu.png",
      liveSite: DouyuSite()..setDouyuSignFunction(DouyuSign.getSign),
    ),
    Site(id: "huya", name: "虎牙", logo: "assets/images/huya.png", liveSite: HuyaSite()),
    Site(
      id: "douyin",
      name: "抖音",
      logo: "assets/images/douyin.png",
      liveSite: DouyinSite()
        ..setAbogusUrlFunction(DouyinSign.getAbogusUrl)
        ..setSignatureFunction(DouyinSign.getSignature),
    ),
    Site(id: "kuaishou", name: "快手", logo: "assets/images/kuaishou.png", liveSite: KuaishowSite()),
    Site(id: "cc", name: "网易CC", logo: "assets/images/cc.png", liveSite: CCSite()),
    Site(id: "iptv", name: "网络", logo: "assets/images/logo.png", liveSite: IptvSite()),
  ];

  static Site of(String id) {
    return supportSites.firstWhere((e) => id == e.id);
  }

  List<Site> availableSites({bool containsAll = false}) {
    final SettingsService settingsService = Get.find<SettingsService>();
    if (containsAll) {
      var result = supportSites.where((element) => settingsService.hotAreasList.value.contains(element.id)).toList();
      result.insert(0, Site(id: "all", name: "全部", logo: "assets/images/all.png", liveSite: LiveSite()));
      return result;
    }
    return supportSites.where((element) => settingsService.hotAreasList.value.contains(element.id)).toList();
  }
}

class Site {
  final String id;
  final String name;
  final String logo;
  final LiveSite liveSite;
  Site({required this.id, required this.liveSite, required this.logo, required this.name});
}
