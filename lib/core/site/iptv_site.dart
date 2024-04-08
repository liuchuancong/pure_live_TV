import 'package:get/get.dart';
import '../iptv/m3u_parser_nullsafe.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/core/iptv/iptv_utils.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/danmaku/empty_danmaku.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/common/services/settings_service.dart';

class IptvSite implements LiveSite {
  @override
  String id = 'iptv';

  @override
  String name = "网络";

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<IptvCategory> categories = await IptvUtils.readCategory();
    List<LiveCategory> categoryTypes = [];
    for (IptvCategory item in categories) {
      var subCategory = await getSubCategores(item);
      LiveCategory liveCategory = LiveCategory(id: item.id!, name: item.name!, children: subCategory);
      if (liveCategory.name != 'hot') {
        categoryTypes.add(liveCategory);
      }
    }
    return categoryTypes;
  }

  Future<List<LiveArea>> getSubCategores(IptvCategory liveCategory) async {
    List<LiveArea> subs = [];
    List<M3uItem> lists = await IptvUtils.readCategoryItems(liveCategory.path);
    for (var item in lists) {
      subs.add(LiveArea(
        areaPic: '',
        areaId: item.link,
        typeName: liveCategory.name,
        areaType: liveCategory.id,
        platform: 'iptv',
        areaName: item.title,
      ));
    }

    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) {
    var items = <LiveRoom>[];
    var roomItem = LiveRoom(
      roomId: category.areaId,
      title: category.typeName,
      cover: '',
      nick: category.areaName,
      watching: '',
      avatar:
          'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
      area: '',
      liveStatus: LiveStatus.live,
      status: true,
      platform: 'iptv',
    );
    items.add(roomItem);
    return Future.value(LiveCategoryResult(hasMore: false, items: items));
  }

  @override
  LiveDanmaku getDanmaku() => EmptyDanmaku();

  @override
  Future<bool> getLiveStatus({required String roomId}) {
    return Future.value(true);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];

    var qualityItem = LivePlayQuality(
      quality: '默认',
      sort: 1,
      data: <String>[detail.data],
    );
    qualities.add(qualityItem);
    return Future.value(qualities);
  }

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.data as List<String>;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    List<M3uItem> lists = await IptvUtils.readRecommandsItems();

    // tvg-id: CCTV1, tvg-name: CCTV1, tvg-logo: https://live.fanmingming.com/tv/CCTV1.png, group-title: 央视
    var items = <LiveRoom>[];
    for (var item in lists) {
      var room = LiveRoom(
        cover: item.attributes['tvg-logo'] ?? '',
        watching: '',
        roomId: item.link,
        area: item.attributes['group-title'] ?? '',
        title: item.title,
        nick: '网络',
        avatar:
            'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
        introduction: '',
        notice: '',
        status: true,
        liveStatus: LiveStatus.live,
        platform: 'iptv',
        link: item.link,
        data: item.link,
      );
      items.add(room);
    }
    return LiveCategoryResult(hasMore: false, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail({required String roomId}) async {
    final SettingsService service = Get.find<SettingsService>();
    var siteIndex = service.favoriteRooms.indexWhere((item) => item.roomId == roomId);
    return LiveRoom(
      cover: '',
      watching: '',
      roomId: roomId,
      area: '',
      title: siteIndex == -1 ? "网络" : service.favoriteRooms[siteIndex].title,
      nick: siteIndex == -1 ? "m3u订阅" : service.favoriteRooms[siteIndex].nick,
      avatar:
          'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
      introduction: '',
      notice: '',
      status: true,
      liveStatus: LiveStatus.live,
      platform: 'iptv',
      link: roomId,
      data: roomId,
    );
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    //尚不支持
    return Future.value([]);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    return LiveSearchAnchorResult(hasMore: false, items: []);
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    return LiveSearchRoomResult(hasMore: false, items: []);
  }
}
