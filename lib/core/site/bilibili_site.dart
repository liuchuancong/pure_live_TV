import 'dart:convert';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_anchor_item.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/common/convert_helper.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/danmaku/bilibili_danmaku.dart';
import 'package:pure_live/common/services/settings_service.dart';

class BiliBiliSite implements LiveSite {
  @override
  String id = "bilibili";

  @override
  String name = "哔哩哔哩直播";
  String cookie = "";
  int userId = 0;
  @override
  LiveDanmaku getDanmaku() => BiliBiliDanmaku();
  final SettingsService settings = Get.find<SettingsService>();

  static const String kDefaultUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0";
  static const String kDefaultReferer = "https://live.bilibili.com/";

  Map<String, String> getHeader() {
    return cookie.isEmpty
        ? {
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
          }
        : {
            "cookie": cookie,
            "user-agent": kDefaultUserAgent,
            "referer": kDefaultReferer,
          };
  }

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<LiveCategory> categories = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Area/getList",
      queryParameters: {
        "need_entrance": 1,
        "parent_id": 0,
      },
      header: getHeader(),
    );
    for (var item in result["data"]) {
      List<LiveArea> subs = [];
      for (var subItem in item["list"]) {
        var subCategory = LiveArea(
          areaId: subItem["id"].toString(),
          areaName: asT<String?>(subItem["name"]) ?? "",
          areaType: asT<String?>(subItem["parent_id"]) ?? "",
          typeName: asT<String?>(subItem["parent_name"]) ?? "",
          areaPic: "${asT<String?>(subItem["pic"]) ?? ""}@100w.png",
          platform: Sites.bilibiliSite,
        );
        subs.add(subCategory);
      }
      var category = LiveCategory(
        children: subs,
        id: item["id"].toString(),
        name: asT<String?>(item["name"]) ?? "",
      );
      categories.add(category);
    }
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-interface/v1/second/getList",
      queryParameters: {
        "platform": "web",
        "parent_area_id": category.areaType,
        "area_id": category.areaId,
        "sort_type": "",
        "page": page
      },
      header: getHeader(),
    );

    var hasMore = result["data"]["has_more"] == 1;
    var items = <LiveRoom>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoom(
          roomId: item["roomid"].toString(),
          title: item["title"].toString(),
          cover: "${item["cover"]}@400w.jpg",
          nick: item["uname"].toString(),
          avatar: item["face"].toString(),
          watching: item["online"].toString(),
          liveStatus: LiveStatus.live,
          area: item["area_name"].toString(),
          status: true,
          platform: Sites.bilibiliSite);
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    List<LivePlayQuality> qualities = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,1,2",
        "codec": "0,1",
        "platform": "web",
      },
      header: getHeader(),
    );
    var qualitiesMap = <int, String>{};
    for (var item in result["data"]["playurl_info"]["playurl"]["g_qn_desc"]) {
      qualitiesMap[int.tryParse(item["qn"].toString()) ?? 0] = item["desc"].toString();
    }

    for (var item in result["data"]["playurl_info"]["playurl"]["stream"][0]["format"][0]["codec"][0]["accept_qn"]) {
      var qualityItem = LivePlayQuality(
        quality: qualitiesMap[item] ?? "未知清晰度",
        data: item,
      );
      qualities.add(qualityItem);
    }
    return qualities;
  }

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    List<String> urls = [];
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo",
      queryParameters: {
        "room_id": detail.roomId,
        "protocol": "0,1",
        "format": "0,2",
        "codec": "0",
        "platform": "web",
        "qn": quality.data,
      },
      header: getHeader(),
    );

    var streamList = result["data"]["playurl_info"]["playurl"]["stream"];

    for (var streamItem in streamList) {
      var formatList = streamItem["format"];
      for (var formatItem in formatList) {
        var formatName = formatItem["format_name"];
        var codecList = formatItem["codec"];
        if (formatName != 'flv') {
          for (var codecItem in codecList) {
            var urlList = codecItem["url_info"];
            var baseUrl = codecItem["base_url"].toString();
            for (var urlItem in urlList) {
              urls.add(
                "${urlItem["host"]}$baseUrl${urlItem["extra"]}",
              );
            }
          }
        }
      }
    }
    // 对链接进行排序，包含mcdn的在后
    urls.sort((a, b) {
      if (a.contains("mcdn")) {
        return 1;
      } else {
        return -1;
      }
    });
    return urls;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-interface/v1/second/getListByArea",
      queryParameters: {"platform": "web", "sort": "online", "page_size": 30, "page": page},
      header: getHeader(),
    );

    var hasMore = (result["data"]["list"] as List).isNotEmpty;
    var items = <LiveRoom>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoom(
        roomId: item["roomid"].toString(),
        title: item["title"].toString(),
        cover: "${item["cover"]}@400w.jpg",
        area: item["area_name"].toString(),
        nick: item["uname"].toString(),
        avatar: item["face"].toString(),
        watching: item["online"].toString(),
        liveStatus: LiveStatus.live,
        platform: Sites.bilibiliSite,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  Future<Map<String, dynamic>> getRoomInfo({required String roomId}) async {
    var url = "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom?room_id=$roomId";
    var queryParams = await getWbiSign(url);
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/xlive/web-room/v1/index/getInfoByRoom",
      queryParameters: queryParams,
      header: getHeader(),
    );
    return result["data"];
  }

  static String kImgKey = '';
  static String kSubKey = '';
  static const List<int> mixinKeyEncTab = [
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52
  ];
  Future<(String, String)> getWbiKeys() async {
    if (kImgKey.isNotEmpty && kSubKey.isNotEmpty) {
      return (kImgKey, kSubKey);
    }
    // 获取最新的 img_key 和 sub_key
    var resp = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/nav',
      header: getHeader(),
    );

    var imgUrl = resp["data"]["wbi_img"]["img_url"].toString();
    var subUrl = resp["data"]["wbi_img"]["sub_url"].toString();
    var imgKey = imgUrl.substring(imgUrl.lastIndexOf('/') + 1).split('.').first;
    var subKey = subUrl.substring(subUrl.lastIndexOf('/') + 1).split('.').first;

    kImgKey = imgKey;
    kSubKey = subKey;

    return (imgKey, subKey);
  }

  String getMixinKey(String origin) {
    // 对 imgKey 和 subKey 进行字符顺序打乱编码
    return mixinKeyEncTab.fold("", (s, i) => s + origin[i]).substring(0, 32);
  }

  Future<Map<String, String>> getWbiSign(String url) async {
    var (imgKey, subKey) = await getWbiKeys();

    // 为请求参数进行 wbi 签名
    var mixinKey = getMixinKey(imgKey + subKey);
    var currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var queryParams = Map<String, String>.from(Uri.parse(url).queryParameters);

    queryParams["wts"] = currentTime.toString(); // 添加 wts 字段

    //按照 key 重排参数
    Map<String, String> map = {};
    var sortedKeys = queryParams.keys.toList()..sort();
    for (var key in sortedKeys) {
      var value = queryParams[key]!;
      // 过滤 value 中的 "!'()*" 字符
      map[key] = value.toString().split('').where((c) => "!'()*".contains(c) == false).join('');
    }

    var query = map.keys.map((key) => "$key=${Uri.encodeQueryComponent(map[key]!)}").join("&");
    var wbiSign = md5.convert(utf8.encode("$query$mixinKey")).toString();
    queryParams["w_rid"] = wbiSign;
    return queryParams;
  }

  @override
  Future<LiveRoom> getRoomDetail(
      {required String nick, required String platform, required String roomId, required String title}) async {
    try {
      var roomInfo = await getRoomInfo(roomId: roomId);
      var realRoomId = roomInfo["room_info"]["room_id"].toString();

      var roomDanmakuResult = await HttpClient.instance.getJson(
        "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo",
        queryParameters: {
          "id": roomId,
        },
        header: getHeader(),
      );
      var buvid = await getBuvid();
      List<String> serverHosts =
          (roomDanmakuResult["data"]["host_list"] as List).map<String>((e) => e["host"].toString()).toList();
      return LiveRoom(
        roomId: roomId,
        title: roomInfo["room_info"]["title"].toString(),
        cover: roomInfo["room_info"]["cover"].toString(),
        nick: roomInfo["anchor_info"]["base_info"]["uname"].toString(),
        avatar: "${roomInfo["anchor_info"]["base_info"]["face"]}@100w.jpg",
        watching: roomInfo["room_info"]["online"].toString(),
        area: roomInfo['room_info']?['area_name'] ?? '',
        status: (asT<int?>(roomInfo["room_info"]["live_status"]) ?? 0) == 1,
        liveStatus: (asT<int?>(roomInfo["room_info"]["live_status"]) ?? 0) == 1 ? LiveStatus.live : LiveStatus.offline,
        link: "https://live.bilibili.com/$roomId",
        introduction: roomInfo["room_info"]["description"].toString(),
        notice: "",
        platform: Sites.bilibiliSite,
        danmakuData: BiliBiliDanmakuArgs(
          roomId: int.tryParse(realRoomId) ?? 0,
          uid: userId,
          token: roomDanmakuResult["data"]["token"].toString(),
          serverHost: serverHosts.isNotEmpty ? serverHosts.first : "broadcastlv.chat.bilibili.com",
          buvid: buvid,
          cookie: cookie,
        ),
      );
    } catch (e) {
      LiveRoom liveRoom = settings.getLiveRoomByRoomId(roomId, platform);
      liveRoom.liveStatus = LiveStatus.offline;
      liveRoom.status = false;
      return liveRoom;
    }
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page
      },
      header: getHeader(),
    );

    var items = <LiveRoom>[];
    var queryList = result["data"]["result"]["live_room"] ?? [];
    for (var item in queryList ?? []) {
      var title = item["title"].toString();
      //移除title中的<em></em>标签
      title = title.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var roomItem = LiveRoom(
        roomId: item["roomid"].toString(),
        title: title,
        cover: "https:${item["cover"]}@400w.jpg",
        nick: item["uname"].toString(),
        watching: item["online"].toString(),
        liveStatus: (asT<int?>(item["live_status"]) ?? 0) == 1 ? LiveStatus.live : LiveStatus.offline,
        area: item["cate_name"].toString(),
        status: (asT<int?>(item["live_status"]) ?? 0) == 1,
        avatar: "https:${item["uface"]}@400w.jpg",
        platform: Sites.bilibiliSite,
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: queryList.length > 0, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.bilibili.com/x/web-interface/search/type?context=&search_type=live_user&cover_type=user_cover",
      queryParameters: {
        "order": "",
        "keyword": keyword,
        "category_id": "",
        "__refresh__": "",
        "_extra": "",
        "highlight": 0,
        "single_column": 0,
        "page": page
      },
      header: getHeader(),
    );

    var items = <LiveAnchorItem>[];
    for (var item in result["data"]["result"] ?? []) {
      var uname = item["uname"].toString();
      //移除title中的<em></em>标签
      uname = uname.replaceAll(RegExp(r"<.*?em.*?>"), "");
      var anchorItem = LiveAnchorItem(
        roomId: item["roomid"].toString(),
        avatar: "https:${item["uface"]}@400w.jpg",
        userName: uname,
        liveStatus: item["is_live"],
      );
      items.add(anchorItem);
    }
    return LiveSearchAnchorResult(hasMore: items.length >= 40, items: items);
  }

  @override
  Future<bool> getLiveStatus(
      {required String nick, required String platform, required String roomId, required String title}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/room/v1/Room/get_info",
      queryParameters: {
        "room_id": roomId,
      },
      header: getHeader(),
    );
    return (asT<int?>(result["data"]["live_status"]) ?? 0) == 1;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) async {
    var result = await HttpClient.instance.getJson(
      "https://api.live.bilibili.com/av/v1/SuperChat/getMessageList",
      queryParameters: {
        "room_id": roomId,
      },
      header: getHeader(),
    );
    List<LiveSuperChatMessage> ls = [];
    for (var item in result["data"]?["list"] ?? []) {
      var message = LiveSuperChatMessage(
        backgroundBottomColor: item["background_bottom_color"].toString(),
        backgroundColor: item["background_color"].toString(),
        endTime: DateTime.fromMillisecondsSinceEpoch(
          item["end_time"] * 1000,
        ),
        face: "${item["user_info"]["face"]}@200w.jpg",
        message: item["message"].toString(),
        price: item["price"],
        startTime: DateTime.fromMillisecondsSinceEpoch(
          item["start_time"] * 1000,
        ),
        userName: item["user_info"]["uname"].toString(),
      );
      ls.add(message);
    }
    return ls;
  }

  Future<String> getBuvid() async {
    try {
      if (cookie.contains("buvid3")) {
        return RegExp(r"buvid3=(.*?);").firstMatch(cookie)?.group(1) ?? "";
      }

      var result = await HttpClient.instance.getJson(
        "https://api.bilibili.com/x/frontend/finger/spi",
        queryParameters: {},
        header: getHeader(),
      );
      return result["data"]["b_3"].toString();
    } catch (e) {
      return "";
    }
  }
}
