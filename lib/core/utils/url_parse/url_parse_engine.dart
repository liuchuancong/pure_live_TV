import 'dart:developer';
import 'package:dio/dio.dart' as dio;
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/core/network/http_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_parse_engine.g.dart';

@riverpod
UrlParseEngine urlParseEngine(Ref ref) {
  return UrlParseEngine();
}

class UrlParseEngine {
  final HttpClient _client = HttpClient.instance;

  Future<List<String>> parse(String url) async {
    final urlRegExp = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
    );
    List<String?> urlMatches = urlRegExp.allMatches(url).map((m) => m.group(0)).toList();
    if (urlMatches.isEmpty) return [];
    String realUrl = urlMatches.first!;
    var id = "";
    realUrl = urlMatches.first!;
    if (realUrl.contains("bilibili.com")) {
      var regExp = RegExp(r"bilibili\.com/([\d|\w]+)");
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      return [id, Sites.bilibiliSite];
    }

    if (realUrl.contains("b23.tv")) {
      var btvReg = RegExp(r"https?:\/\/b23.tv\/[0-9a-z-A-Z]+");
      var u = btvReg.firstMatch(realUrl)?.group(0) ?? "";
      var location = await getLocation(u);
      return await parse(location);
    }

    if (realUrl.contains("douyu.com")) {
      var regExp = RegExp(r"douyu\.com/([\d|\w]+)");
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      return [id, Sites.douyuSite];
    }
    if (realUrl.contains("huya.com")) {
      var regExp = RegExp(r"huya\.com/([\d|\w]+)");
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";

      return [id, Sites.huyaSite];
    }
    if (realUrl.contains("live.douyin.com")) {
      var regExp = RegExp(r"live\.douyin\.com/([\d|\w]+)");
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      return [id, Sites.douyinSite];
    }
    if (realUrl.contains("www.douyin.com")) {
      realUrl = realUrl.split("?")[0];
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      Uri uri = Uri.parse(realUrl);
      return [uri.pathSegments.last, Sites.douyinSite];
    }
    if (realUrl.contains("v.douyin.com")) {
      final id = await getRealDouyinUrl(realUrl);
      return [id, Sites.douyinSite];
    }
    if (realUrl.contains("live.kuaishou.com")) {
      var regExp = RegExp(r"live\.kuaishou\.com/u/([a-zA-Z0-9]+)$");
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      return [id, Sites.kuaishouSite];
    }
    if (realUrl.contains("live.kuaishou.cn")) {
      var regExp = RegExp(r"live\.kuaishou\.cn/u/([a-zA-Z0-9]+)$");
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      return [id, Sites.kuaishouSite];
    }

    if (realUrl.contains("cc.163.com")) {
      var regExp = RegExp(r"cc\.163\.com/([a-zA-Z0-9]+)$");
      if (realUrl.endsWith('/')) {
        realUrl = realUrl.substring(0, realUrl.length - 1);
      }
      id = regExp.firstMatch(realUrl)?.group(1) ?? "";
      return [id, Sites.ccSite];
    }
    return [];
  }

  Future<String> getRealDouyinUrl(String url) async {
    final urlRegExp = RegExp(
      r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?",
    );
    List<String?> urlMatches = urlRegExp.allMatches(url).map((m) => m.group(0)).toList();
    String realUrl = urlMatches.first!;
    var headers = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
      "Accept": "*/*",
      "Accept-Encoding": "gzip, deflate, br, zstd",
      "Origin": "https://live.douyin.com",
      "Referer": "https://live.douyin.com/",
      "Sec-Fetch-Site": "cross-site",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Dest": "empty",
      "Accept-Language": "zh-CN,zh;q=0.9",
    };

    final dio.Response response = await _client.get(realUrl, header: headers);
    final liveResponseRegExp = RegExp(r"/reflow/(\d+)");
    String reflow = liveResponseRegExp.firstMatch(response.realUri.toString())?.group(0) ?? "";

    final liveResponse = await _client.getJson(
      "https://webcast.amemv.com/webcast/room/reflow/info/",
      queryParameters: {
        "room_id": reflow.split("/").last.toString(),
        'verifyFp': '',
        'type_id': 0,
        'live_id': 1,
        'sec_user_id': '',
        'app_id': 1128,
        'msToken': '',
        'X-Bogus': '',
      },
    );
    var room = liveResponse.data['data']['room']['owner']['web_rid'];
    return room.toString();
  }

  Future<String> getLocation(String url) async {
    try {
      if (url.isEmpty) return "";
      await _client.dio.get(url, options: dio.Options(followRedirects: false));
    } on dio.DioException catch (e) {
      if (e.response!.statusCode == 302) {
        var redirectUrl = e.response!.headers.value("Location");
        if (redirectUrl != null) {
          return redirectUrl;
        }
      }
    } catch (e) {
      log(e.toString(), name: "getLocation");
    }
    return "";
  }
}
