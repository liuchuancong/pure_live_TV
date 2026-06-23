import 'site/huya_site.dart';
import 'site/douyu_site.dart';
import 'site/douyin_site.dart';
import 'interface/live_site.dart';
import 'package:collection/collection.dart';
import 'package:pure_live/core/sites/site/cc_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/core/sites/site/bilibili_site.dart';
import 'package:pure_live/core/sites/site/kuaishou_site.dart';

class Sites {
  static const String allSite = "all";
  static const String bilibiliSite = "bilibili";
  static const String douyuSite = "douyu";
  static const String huyaSite = "huya";
  static const String douyinSite = "douyin";
  static const String kuaishouSite = "kuaishou";
  static const String ccSite = "cc";
  static const String iptvSite = "iptv";
  static List<Site> get supportSites => [
    Site(id: "bilibili", name: "哔哩哔哩", logo: "assets/images/bilibili_2.png", liveSite: BiliBiliSite()),
    Site(id: "douyu", name: "斗鱼", logo: "assets/images/douyu.png", liveSite: DouyuSite()),
    Site(id: "huya", name: "虎牙", logo: "assets/images/huya.png", liveSite: HuyaSite()),
    Site(id: "douyin", name: "抖音", logo: "assets/images/douyin.png", liveSite: DouyinSite()),
    Site(id: "kuaishou", name: "快手", logo: "assets/images/kuaishou.png", liveSite: KuaishowSite()),
    Site(id: "cc", name: "网易CC", logo: "assets/images/cc.png", liveSite: CCSite()),
  ];

  static Site of(String id) {
    return supportSites.firstWhere((e) => id == e.id);
  }

  List<Site> availableSites({bool containsAll = false}) {
    final List<String> savedIds = SettingsService.to.favState.hotAreasList;

    List<Site> result = [];
    for (String id in savedIds) {
      final match = supportSites.firstWhereOrNull((element) => element.id == id);
      if (match != null) {
        result.add(match);
      }
    }
    if (containsAll) {
      result.insert(0, Site(id: "all", name: "全部", logo: "assets/images/all.png", liveSite: LiveSite()));
    }
    return result;
  }
}

class Site {
  final String id;
  final String name;
  final String logo;
  final LiveSite liveSite;
  Site({required this.id, required this.liveSite, required this.logo, required this.name});
}
