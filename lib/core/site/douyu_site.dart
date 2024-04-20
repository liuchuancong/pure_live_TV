import 'dart:math';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:pure_live/core/sites.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_anchor_item.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/danmaku/douyu_danmaku.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/common/services/settings_service.dart';

class DouyuSite implements LiveSite {
  @override
  String id = "douyu";

  @override
  String name = "斗鱼直播";

  @override
  LiveDanmaku getDanmaku() => DouyuDanmaku();
  final SettingsService settings = Get.find<SettingsService>();
  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<LiveCategory> categories = [
      LiveCategory(id: "PCgame", name: "网游竞技", children: []),
      LiveCategory(id: "djry", name: "单机热游", children: []),
      LiveCategory(id: "syxx", name: "手游休闲", children: []),
      LiveCategory(id: "yl", name: "娱乐天地", children: []),
      LiveCategory(id: "yz", name: "颜值", children: []),
      LiveCategory(id: "kjwh", name: "科技文化", children: []),
      LiveCategory(id: "yp", name: "语言互动", children: []),
    ];

    for (var item in categories) {
      var items = await getSubCategories(item);
      item.children.addAll(items);
    }
    return categories;
  }

  Future<List<LiveArea>> getSubCategories(LiveCategory liveCategory) async {
    var result = await HttpClient.instance.getJson("https://www.douyu.com/japi/weblist/api/getC2List",
        queryParameters: {"shortName": liveCategory.id, "offset": 0, "limit": 200});

    List<LiveArea> subs = [];
    for (var item in result["data"]["list"]) {
      subs.add(LiveArea(
        areaPic: item["squareIconUrlW"].toString(),
        areaId: item["cid2"].toString(),
        typeName: liveCategory.name,
        areaType: liveCategory.id,
        platform: Sites.douyuSite,
        areaName: item["cname2"].toString(),
      ));
    }

    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/gapi/rkc/directory/mixList/2_${category.areaId}/$page",
      queryParameters: {},
    );

    var items = <LiveRoom>[];
    for (var item in result['data']['rl']) {
      if (item["type"] != 1) {
        continue;
      }
      var roomItem = LiveRoom(
        cover: item['rs16'].toString(),
        watching: item['ol'].toString(),
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        nick: item['nn'].toString(),
        area: item['c2name'].toString(),
        liveStatus: LiveStatus.live,
        avatar: item['av'].toString().isNotEmpty ? 'https://apic.douyucdn.cn/upload/${item['av']}_middle.jpg' : '',
        status: true,
        platform: Sites.douyuSite,
      );
      items.add(roomItem);
    }
    var hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    var data = detail.data.toString();
    data += "&cdn=&rate=-1&ver=Douyu_223061205&iar=1&ive=1&hevc=0&fa=0";
    List<LivePlayQuality> qualities = [];
    var result = await HttpClient.instance.postJson(
      "https://www.douyu.com/lapi/live/getH5Play/${detail.roomId}",
      data: data,
      formUrlEncoded: true,
    );

    var cdns = <String>[];
    for (var item in result["data"]["cdnsWithName"]) {
      cdns.add(item["cdn"].toString());
    }
    for (var item in result["data"]["multirates"]) {
      qualities.add(LivePlayQuality(
        quality: item["name"].toString(),
        data: DouyuPlayData(item["rate"], cdns),
      ));
    }
    return qualities;
  }

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    var args = detail.data.toString();
    var data = quality.data as DouyuPlayData;

    List<String> urls = [];
    for (var item in data.cdns) {
      var url = await getPlayUrl(detail.roomId!, args, data.rate, item);
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String> getPlayUrl(String roomId, String args, int rate, String cdn) async {
    args += "&cdn=$cdn&rate=$rate";
    var result = await HttpClient.instance.postJson(
      "https://www.douyu.com/lapi/live/getH5Play/$roomId",
      data: args,
      header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43"
      },
      formUrlEncoded: true,
    );

    return "${result["data"]["rtmp_url"]}/${HtmlUnescape().convert(result["data"]["rtmp_live"].toString())}";
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/weblist/apinc/allpage/6/$page",
      queryParameters: {},
    );

    var items = <LiveRoom>[];
    for (var item in result['data']['rl']) {
      if (item["type"] != 1) {
        continue;
      }
      var roomItem = LiveRoom(
        cover: item['rs16'].toString(),
        watching: item['ol'].toString(),
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        nick: item['nn'].toString(),
        area: item['c2name'].toString(),
        avatar: item['av'].toString().isNotEmpty ? 'https://apic.douyucdn.cn/upload/${item['av']}_middle.jpg' : '',
        platform: Sites.douyuSite,
        status: true,
        liveStatus: LiveStatus.live,
      );
      items.add(roomItem);
    }
    var hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail(
      {required String nick, required String platform, required String roomId, required String title}) async {
    try {
      var result =
          await HttpClient.instance.getJson("https://www.douyu.com/betard/$roomId", queryParameters: {}, header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      });
      Map roomInfo;
      if (result is String) {
        roomInfo = json.decode(result)["room"];
      } else {
        roomInfo = result["room"];
      }

      var jsEncResult = await HttpClient.instance
          .getText("https://www.douyu.com/swf_api/homeH5Enc?rids=$roomId", queryParameters: {}, header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43"
      });
      var crptext = json.decode(jsEncResult)["data"]["room$roomId"].toString();

      return LiveRoom(
        cover: roomInfo["room_pic"].toString(),
        watching: roomInfo["room_biz_all"]["hot"].toString(),
        roomId: roomId,
        title: roomInfo["room_name"].toString(),
        nick: roomInfo["owner_name"].toString(),
        avatar: roomInfo["owner_avatar"].toString(),
        introduction: roomInfo["show_details"].toString(),
        area: roomInfo["cate_name"]?.toString() ?? '',
        notice: "",
        liveStatus: roomInfo["show_status"] == 1 ? LiveStatus.live : LiveStatus.offline,
        status: roomInfo["show_status"] == 1,
        danmakuData: roomInfo["room_id"].toString(),
        data: await getPlayArgs(crptext, roomInfo["room_id"].toString()),
        platform: Sites.douyuSite,
        link: "https://www.douyu.com/$roomId",
        isRecord: roomInfo["videoLoop"] == 1,
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
    var did = generateRandomString(32);
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/search/api/searchShow",
      queryParameters: {
        "kw": keyword,
        "page": page,
        "pageSize": 20,
      },
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did'
      },
    );
    if (result['error'] != 0) {
      throw Exception(result['msg']);
    }
    var items = <LiveRoom>[];

    var queryList = result["data"]["relateShow"] ?? [];
    for (var item in queryList) {
      var liveStatus = (int.tryParse(item["isLive"].toString()) ?? 0) == 1;
      var roomType = (int.tryParse(item["roomType"].toString()) ?? 0);
      var roomItem = LiveRoom(
        roomId: item["rid"].toString(),
        title: item["roomName"].toString(),
        cover: item["roomSrc"].toString(),
        area: item["cateName"].toString(),
        avatar: item["avatar"].toString(),
        liveStatus: liveStatus && roomType == 0 ? LiveStatus.live : LiveStatus.offline,
        status: liveStatus && roomType == 0,
        nick: item["nickName"].toString(),
        platform: Sites.douyuSite,
        watching: item["hot"].toString(),
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: queryList.length > 0, items: items);
  }

  //生成指定长度的16进制随机字符串
  String generateRandomString(int length) {
    var random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(16));
    StringBuffer stringBuffer = StringBuffer();
    for (var item in values) {
      stringBuffer.write(item.toRadixString(16));
    }
    return stringBuffer.toString();
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    var did = generateRandomString(32);
    var result = await HttpClient.instance.getJson(
      "https://www.douyu.com/japi/search/api/searchUser",
      queryParameters: {
        "kw": keyword,
        "page": page,
        "pageSize": 20,
        "filterType": 1,
      },
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did'
      },
    );

    var items = <LiveAnchorItem>[];
    for (var item in result["data"]["relateUser"]) {
      var liveStatus = (int.tryParse(item["anchorInfo"]["isLive"].toString()) ?? 0) == 1;
      var roomType = (int.tryParse(item["anchorInfo"]["roomType"].toString()) ?? 0);
      var roomItem = LiveAnchorItem(
        roomId: item["anchorInfo"]["rid"].toString(),
        avatar: item["anchorInfo"]["avatar"].toString(),
        userName: item["anchorInfo"]["nickName"].toString(),
        liveStatus: liveStatus && roomType == 0,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["relateUser"].isNotEmpty;
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus(
      {required String nick, required String platform, required String roomId, required String title}) async {
    var detail = await getRoomDetail(roomId: roomId, platform: platform, title: title, nick: nick);
    return detail.status!;
  }

  Future<String> getPlayArgs(String html, String rid) async {
    //取加密的js
    html = RegExp(r"(vdwdae325w_64we[\s\S]*function ub98484234[\s\S]*?)function", multiLine: true)
            .firstMatch(html)
            ?.group(1) ??
        "";
    html = html.replaceAll(RegExp(r"eval.*?;}"), "strc;}");

    var result = await HttpClient.instance
        .postJson("http://alive.nsapps.cn/api/AllLive/DouyuSign", data: {"html": html, "rid": rid});

    if (result["code"] == 0) {
      return result["data"].toString();
    }
    return "";
  }

  int parseHotNum(String hn) {
    try {
      var num = double.parse(hn.replaceAll("万", ""));
      if (hn.contains("万")) {
        num *= 10000;
      }
      return num.round();
    } catch (_) {
      return -999;
    }
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    //尚不支持
    return Future.value([]);
  }
}

class DouyuPlayData {
  final int rate;
  final List<String> cdns;
  DouyuPlayData(this.rate, this.cdns);
}
