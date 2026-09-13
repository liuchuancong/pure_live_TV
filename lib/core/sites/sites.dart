import 'huya/huya_site.dart';
import 'douyu/douyu_site.dart';
import 'douyin/douyin_site.dart';
import 'interface/live_site.dart';
import 'package:collection/collection.dart';
import 'package:pure_live/core/sites/cc/cc_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/core/sites/bilibili/bilibili_site.dart';
import 'package:pure_live/core/sites/kuaishou/kuaishou_site.dart';
import 'package:pure_live/core/sites/yy/yy_site.dart';
import 'package:pure_live/core/sites/soop/soop_site.dart';
import 'package:pure_live/core/sites/twitch/twitch_site.dart';

class Sites {
  static const String allSite = "all";
  static const String bilibiliSite = "bilibili";
  static const String douyuSite = "douyu";
  static const String huyaSite = "huya";
  static const String douyinSite = "douyin";
  static const String kuaishouSite = "kuaishou";
  static const String ccSite = "cc";
  static const String iptvSite = "iptv";
  static const String yySite = "yy";
  static const String soopSite = "soop";
  static const String twitchSite = "twitch";
  static List<Site> get supportSites => [
    Site(id: "bilibili", name: "哔哩哔哩", logo: "assets/images/bilibili_2.png", liveSite: BiliBiliSite()),
    Site(id: "douyu", name: "斗鱼", logo: "assets/images/douyu.png", liveSite: DouyuSite()),
    Site(id: "huya", name: "虎牙", logo: "assets/images/huya.png", liveSite: HuyaSite()),
    Site(id: "douyin", name: "抖音", logo: "assets/images/douyin.png", liveSite: DouyinSite()),
    Site(id: "kuaishou", name: "快手", logo: "assets/images/kuaishou.png", liveSite: KuaishowSite()),
    Site(id: "cc", name: "网易CC", logo: "assets/images/cc.png", liveSite: CCSite()),
    Site(id: yySite, name: "YY", logo: "assets/images/yy.png", liveSite: YYSite()),
    Site(id: soopSite, name: "Soop", logo: "assets/images/soop.png", liveSite: SoopSite()),
    Site(id: twitchSite, name: "Twitch", logo: "assets/images/twitch.png", liveSite: TwitchSite()),
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
