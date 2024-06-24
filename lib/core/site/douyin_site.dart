import 'dart:convert';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/common/convert_helper.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/core/danmaku/douyin_danmaku.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/common/services/settings_service.dart';

class DouyinSite implements LiveSite {
  @override
  String id = "douyin";

  @override
  String name = "抖音直播";

  @override
  LiveDanmaku getDanmaku() => DouyinDanmaku();
  final SettingsService settings = Get.find<SettingsService>();

  static const String kDefaultUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0";

  static const String kDefaultReferer = "https://live.douyin.com";

  static const String kDefaultAuthority = "live.douyin.com";

  Map<String, dynamic> headers = {
    "Authority": kDefaultAuthority,
    "Referer": kDefaultReferer,
    "User-Agent": kDefaultUserAgent,
  };

  Future<Map<String, dynamic>> getRequestHeaders() async {
    try {
      if (headers.containsKey("cookie")) {
        return headers;
      }
      var head = await HttpClient.instance.head("https://live.douyin.com", header: headers);
      head.headers["set-cookie"]?.forEach((element) {
        var cookie = element.split(";")[0];
        if (cookie.contains("ttwid")) {
          headers["cookie"] = cookie;
        }
      });
      return headers;
    } catch (e) {
      CoreLog.error(e);
      return headers;
    }
  }

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<LiveCategory> categories = [];
    var result = await HttpClient.instance.getText(
      "https://live.douyin.com/",
      queryParameters: {},
      header: await getRequestHeaders(),
    );
    var renderData = RegExp(r'\{\\"pathname\\":\\"\/\\",\\"categoryData.*?\]\\n').firstMatch(result)?.group(0) ?? "";
    var renderDataJson =
        json.decode(renderData.trim().replaceAll('\\"', '"').replaceAll(r"\\", r"\").replaceAll(']\\n', ""));
    for (var item in renderDataJson["categoryData"]) {
      List<LiveArea> subs = [];
      var id = '${item["partition"]["id_str"]},${item["partition"]["type"]}';
      for (var subItem in item["sub_partition"]) {
        var subCategory = LiveArea(
          areaId: '${subItem["partition"]["id_str"]},${subItem["partition"]["type"]}',
          typeName: item["partition"]["title"] ?? '',
          areaType: id,
          areaName: subItem["partition"]["title"] ?? '',
          areaPic: "",
          platform: Sites.douyinSite,
        );
        subs.add(subCategory);
      }

      var category = LiveCategory(
        children: subs,
        id: id,
        name: asT<String?>(item["partition"]["title"]) ?? "",
      );
      subs.insert(
          0,
          LiveArea(
            areaId: category.id,
            typeName: category.name,
            areaType: category.id,
            areaPic: "",
            areaName: category.name,
            platform: Sites.douyinSite,
          ));
      categories.add(category);
    }
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var ids = category.areaId?.split(',');
    var partitionId = ids?[0];
    var partitionType = ids?[1];
    var result = await HttpClient.instance.getJson(
      "https://live.douyin.com/webcast/web/partition/detail/room/",
      queryParameters: {
        "aid": 6383,
        "app_name": "douyin_web",
        "live_id": 1,
        "device_platform": "web",
        "count": 15,
        "offset": (page - 1) * 15,
        "partition": partitionId,
        "partition_type": partitionType,
        "req_from": 2
      },
      header: await getRequestHeaders(),
    );
    var hasMore = (result["data"]["data"] as List).length >= 15;
    var items = <LiveRoom>[];
    for (var item in result["data"]["data"]) {
      var roomItem = LiveRoom(
        roomId: item["web_rid"],
        title: item["room"]["title"].toString(),
        cover: item["room"]["cover"]["url_list"][0].toString(),
        nick: item["room"]["owner"]["nickname"].toString(),
        liveStatus: LiveStatus.live,
        avatar: item["room"]["owner"]["avatar_thumb"]["url_list"][0].toString(),
        status: true,
        platform: Sites.douyinSite,
        area: item['tag_name'].toString(),
        watching: item["room"]?["room_view_stats"]?["display_value"].toString() ?? '',
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var result = await HttpClient.instance.getJson(
      "https://live.douyin.com/webcast/web/partition/detail/room/",
      queryParameters: {
        "aid": 6383,
        "app_name": "douyin_web",
        "live_id": 1,
        "device_platform": "web",
        "count": 15,
        "offset": (page - 1) * 15,
        "partition": 720,
        "partition_type": 1,
      },
      header: await getRequestHeaders(),
    );

    var hasMore = (result["data"]["data"] as List).length >= 15;
    var items = <LiveRoom>[];

    for (var item in result["data"]["data"]) {
      var roomItem = LiveRoom(
        roomId: item["web_rid"],
        title: item["room"]["title"].toString(),
        cover: item["room"]["cover"]["url_list"][0].toString(),
        nick: item["room"]["owner"]["nickname"].toString(),
        platform: Sites.douyinSite,
        area: item["tag_name"] ?? '热门推荐',
        avatar: item["room"]["owner"]["avatar_thumb"]["url_list"][0].toString(),
        watching: item["room"]?["room_view_stats"]?["display_value"].toString() ?? '',
        liveStatus: LiveStatus.live,
      );
      items.add(roomItem);
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail(
      {required String nick, required String platform, required String roomId, required String title}) async {
    try {
      var detail = await getRoomWebDetail(roomId);
      var requestHeader = await getRequestHeaders();
      var webRid = roomId;
      var realRoomId = detail["roomStore"]["roomInfo"]["room"]["id_str"].toString();
      var userUniqueId = detail["userStore"]["odin"]["user_unique_id"].toString();
      var result = await HttpClient.instance.getJson(
        "https://live.douyin.com/webcast/room/web/enter/",
        queryParameters: {
          "aid": 6383,
          "app_name": "douyin_web",
          "live_id": 1,
          "device_platform": "web",
          "enter_from": "web_live",
          "web_rid": webRid,
          "room_id_str": "",
          "enter_source": "",
          "Room-Enter-User-Login-Ab": 1,
          "is_need_double_stream": false,
          "cookie_enabled": true,
          "screen_width": 1980,
          "screen_height": 1080,
          "browser_language": "zh-CN",
          "browser_platform": "Win32",
          "browser_name": "Edge",
          "browser_version": "125.0.0.0"
        },
        header: requestHeader,
      );
      var roomInfo = result["data"]["data"][0];
      var userInfo = result["data"]["user"];
      var partition = result["data"]['partition_road_map'];
      var roomStatus = (asT<int?>(roomInfo["status"]) ?? 0) == 2;
      return LiveRoom(
        roomId: roomId,
        title: roomInfo["title"].toString(),
        cover: roomStatus ? roomInfo["cover"]["url_list"][0].toString() : "",
        nick: userInfo["nickname"].toString(),
        avatar: userInfo["avatar_thumb"]["url_list"][0].toString(),
        watching: roomInfo?["room_view_stats"]?["display_value"].toString() ?? '',
        liveStatus: roomStatus ? LiveStatus.live : LiveStatus.offline,
        link: "https://live.douyin.com/$webRid",
        area: partition?['partition']?['title'].toString() ?? '',
        status: roomStatus,
        platform: Sites.douyinSite,
        introduction: roomInfo["title"].toString(),
        notice: "",
        danmakuData: DouyinDanmakuArgs(
          webRid: webRid,
          roomId: realRoomId,
          userId: userUniqueId,
          cookie: headers["cookie"],
        ),
        data: roomInfo["stream_url"],
      );
    } catch (e) {
      LiveRoom liveRoom = settings.getLiveRoomByRoomId(roomId, platform);
      liveRoom.liveStatus = LiveStatus.offline;
      liveRoom.status = false;
      return liveRoom;
    }
  }

  Future<Map> getRoomWebDetail(String webRid) async {
    var headResp = await HttpClient.instance.head("https://live.douyin.com/$webRid", header: headers);
    var dyCookie = "";
    headResp.headers["set-cookie"]?.forEach((element) {
      var cookie = element.split(";")[0];
      if (cookie.contains("ttwid")) {
        dyCookie += "$cookie;";
      }
      if (cookie.contains("__ac_nonce")) {
        dyCookie += "$cookie;";
      }
    });
    var result = await HttpClient.instance.getText(
      "https://live.douyin.com/$webRid",
      queryParameters: {},
      header: {
        "Authority": kDefaultAuthority,
        "Referer": kDefaultReferer,
        "Cookie": dyCookie,
        "User-Agent": kDefaultUserAgent,
      },
    );

    var renderData = RegExp(r'\{\\"state\\":\{\\"isLiveModal.*?\]\\n').firstMatch(result)?.group(0) ?? "";
    var str = renderData.trim().replaceAll('\\"', '"').replaceAll(r"\\", r"\").replaceAll(']\\n', "");
    var renderDataJson = json.decode(str);

    return renderDataJson["state"];
    // return renderDataJson["app"]["initialState"]["roomStore"]["roomInfo"]
    //         ["room"]["id_str"]
    //     .toString();
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    List<LivePlayQuality> qualities = [];

    var qulityList = detail.data["live_core_sdk_data"]["pull_data"]["options"]["qualities"];
    var streamData = detail.data["live_core_sdk_data"]["pull_data"]["stream_data"].toString();

    if (!streamData.startsWith('{')) {
      var flvList = (detail.data["flv_pull_url"] as Map).values.cast<String>().toList();
      var hlsList = (detail.data["hls_pull_url_map"] as Map).values.cast<String>().toList();
      for (var quality in qulityList) {
        int level = quality["level"];
        List<String> urls = [];
        var flvIndex = flvList.length - level;
        if (flvIndex >= 0 && flvIndex < flvList.length) {
          urls.add(flvList[flvIndex]);
        }
        var hlsIndex = hlsList.length - level;
        if (hlsIndex >= 0 && hlsIndex < hlsList.length) {
          urls.add(hlsList[hlsIndex]);
        }
        var qualityItem = LivePlayQuality(
          quality: quality["name"],
          sort: level,
          data: urls,
        );
        if (urls.isNotEmpty) {
          qualities.add(qualityItem);
        }
      }
    } else {
      var qualityData = json.decode(streamData)["data"] as Map;
      for (var quality in qulityList) {
        List<String> urls = [];
        var flvUrl = qualityData[quality["sdk_key"]]?["main"]?["flv"]?.toString();

        if (flvUrl != null && flvUrl.isNotEmpty) {
          urls.add(flvUrl);
        }
        var hlsUrl = qualityData[quality["sdk_key"]]?["main"]?["hls"]?.toString();
        if (hlsUrl != null && hlsUrl.isNotEmpty) {
          urls.add(hlsUrl);
        }
        var qualityItem = LivePlayQuality(
          quality: quality["name"],
          sort: quality["level"],
          data: urls,
        );
        if (urls.isNotEmpty) {
          qualities.add(qualityItem);
        }
      }
    }
    // var qualityData = json.decode(
    //     detail.data["live_core_sdk_data"]["pull_data"]["stream_data"])["data"];

    qualities.sort((a, b) => b.sort.compareTo(a.sort));
    return qualities;
  }

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.data;
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    String serverUrl = "https://www.douyin.com/aweme/v1/web/live/search/";
    var uri = Uri.parse(serverUrl).replace(scheme: "https", port: 443, queryParameters: {
      "device_platform": "webapp",
      "aid": "6383",
      "channel": "channel_pc_web",
      "search_channel": "aweme_live",
      "keyword": keyword,
      "search_source": "switch_tab",
      "query_correct_type": "1",
      "is_filter_search": "0",
      "from_group_id": "",
      "offset": ((page - 1) * 10).toString(),
      "count": "10",
      "pc_client_type": "1",
      "version_code": "170400",
      "version_name": "17.4.0",
      "cookie_enabled": "true",
      "screen_width": "1980",
      "screen_height": "1080",
      "browser_language": "zh-CN",
      "browser_platform": "Win32",
      "browser_name": "Edge",
      "browser_version": "125.0.0.0",
      "browser_online": "true",
      "engine_name": "Blink",
      "engine_version": "125.0.0.0",
      "os_name": "Windows",
      "os_version": "10",
      "cpu_core_num": "12",
      "device_memory": "8",
      "platform": "PC",
      "downlink": "10",
      "effective_type": "4g",
      "round_trip_time": "100",
      "webid": "7382872326016435738",
    });
    var requlestUrl = uri.toString();
    var headResp = await HttpClient.instance.head('https://live.douyin.com', header: headers);
    var dyCookie = "";
    headResp.headers["set-cookie"]?.forEach((element) {
      var cookie = element.split(";")[0];
      if (cookie.contains("ttwid")) {
        dyCookie += "$cookie;";
      }
      if (cookie.contains("__ac_nonce")) {
        dyCookie += "$cookie;";
      }
    });
    var result = await HttpClient.instance.getJson(
      requlestUrl,
      queryParameters: {},
      header: {
        "Authority": 'www.douyin.com',
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'cookie': dyCookie,
        'priority': 'u=1, i',
        'referer': 'https://www.douyin.com/search/${Uri.encodeComponent(keyword)}?type=live',
        'sec-ch-ua': '"Microsoft Edge";v="125", "Chromium";v="125", "Not.A/Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent': kDefaultUserAgent,
      },
    );
    if (result == "" || result == 'blocked') {
      throw Exception("抖音直播搜索被限制，请稍后再试");
    }
    var items = <LiveRoom>[];
    var queryList = result["data"] ?? [];
    for (var item in queryList) {
      var itemData = json.decode(item["lives"]["rawdata"].toString());
      var roomStatus = (asT<int?>(itemData["status"]) ?? 0) == 2;
      var roomItem = LiveRoom(
        roomId: itemData["owner"]["web_rid"].toString(),
        title: itemData["title"].toString(),
        cover: itemData["cover"]["url_list"][0].toString(),
        nick: itemData["owner"]["nickname"].toString(),
        platform: Sites.douyinSite,
        avatar: itemData["owner"]["avatar_thumb"]["url_list"][0].toString(),
        liveStatus: roomStatus ? LiveStatus.live : LiveStatus.offline,
        area: '',
        status: roomStatus,
        watching: itemData["stats"]["total_user_str"].toString(),
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: queryList.length > 0, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    throw Exception("抖音暂不支持搜索主播，请直接搜索直播间");
  }

  @override
  Future<bool> getLiveStatus(
      {required String nick, required String platform, required String roomId, required String title}) async {
    var result = await getRoomDetail(roomId: roomId, platform: platform, title: title, nick: nick);
    return result.status!;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    return Future.value(<LiveSuperChatMessage>[]);
  }

  //生成指定长度的16进制随机字符串
  String generateRandomString(int length) {
    var random = math.Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(16));
    StringBuffer stringBuffer = StringBuffer();
    for (var item in values) {
      stringBuffer.write(item.toRadixString(16));
    }
    return stringBuffer.toString();
  }

  Future<String> getAbogusUrl(String url) async {
    try {
      // 发起一个签名请求
      // 服务端代码：https://github.com/5ime/Tiktok_Signature
      var signResult = await HttpClient.instance.postJson(
        "https://dy.nsapps.cn/abogus",
        queryParameters: {},
        header: {"Content-Type": "application/json"},
        data: {"url": url, "userAgent": kDefaultUserAgent},
      );

      return signResult["data"]["url"];
    } catch (e) {
      CoreLog.error(e);
      return url;
    }
  }
}
