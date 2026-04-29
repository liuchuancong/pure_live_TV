import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:pure_live/common/index.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';

class ToolBoxController extends GetxController {
  final NativeTextFieldController roomJumpToController = NativeTextFieldController();
  final RxString serverIp = "".obs;
  NetworkInfo networkInfo = NetworkInfo();
  HttpServer? _server;
  final RxString fullServerUrl = "".obs;
  @override
  void onInit() {
    super.onInit();
    initServer();
  }

  @override
  void onClose() {
    _server?.close();
    super.onClose();
  }

  // 获取稳健的局域网 IP
  Future<String> getLocalIP() async {
    var ip = await networkInfo.getWifiIP();
    if (ip == null || ip.isEmpty) {
      var interfaces = await NetworkInterface.list();
      var ipList = <String>[];
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // 排除回环地址、多播地址及 IPv6
          if (addr.type.name == 'IPv4' && !addr.address.startsWith('127') && !addr.isMulticast && !addr.isLoopback) {
            ipList.add(addr.address);
            break;
          }
        }
      }
      // 优先取第一个有效 IP
      ip = ipList.isNotEmpty ? ipList.first : "";
    }
    return ip;
  }

  void initServer() async {
    String ip = await getLocalIP();
    if (ip.isEmpty) {
      ToastUtil.show("无法获取局域网IP，请检查网络");
      return;
    }
    String primaryIp = ip.contains(';') ? ip.split(';').first : ip;
    fullServerUrl.value = "http://$primaryIp:8080";
    startServer(primaryIp);
  }

  void startServer(String ip) async {
    try {
      // 绑定 8080 端口
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      log("局域网服务启动: http://$ip:8080");

      _server!.listen((HttpRequest request) async {
        // 允许跨域
        request.response.headers.add("Access-Control-Allow-Origin", "*");

        if (request.method == 'GET') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(_buildWebHtml());
          await request.response.close();
        } else if (request.method == 'POST') {
          try {
            // 1. 直接读取全部原始 Body 文本，不进行 query 解析
            String rawContent = await utf8.decoder.bind(request).join();

            if (rawContent.isNotEmpty) {
              // 2. 回到主线程直接赋值给输入框
              Future.microtask(() {
                roomJumpToController.text = rawContent;
                ToastUtil.show("已同步远程内容");
                log("接收到的原始文本: $rawContent");
              });
            }

            request.response.statusCode = HttpStatus.ok;
            request.response.write("ok");
            await request.response.close();
          } catch (e) {
            log("接收数据失败: $e");
          }
        }
      });
    } catch (e) {
      log("服务器启动失败: $e");
    }
  }

  String _buildWebHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <title>PureLive 远程输入</title>
      <style>
        body { font-family: -apple-system, system-ui; padding: 20px; background: #f4f4f9; }
        .card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h2 { color: #333; margin-top: 0; }
        textarea { width: 100%; height: 120px; box-sizing: border-box; padding: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px; margin: 15px 0; outline: none; }
        button { width: 100%; padding: 15px; background: #007AFF; color: white; border: none; border-radius: 8px; font-size: 18px; font-weight: bold; cursor: pointer; }
        button:active { background: #0056b3; }
      </style>
    </head>
    <body>
      <div class="card">
        <h2>发送至电视</h2>
        <p style="color: #666; font-size: 14px;">在下方粘贴直播间链接或房间号：</p>
        <textarea id="txt" placeholder="在此输入..."></textarea>
        <button onclick="send()">立即发送</button>
      </div>
      <script>
        function send() {
          const val = document.getElementById('txt').value;
          if(!val) return alert('内容不能为空');
          
          // 关键：明确指定 Content-Type 为纯文本，避免浏览器按表单格式编码
          fetch('/', {
            method: 'POST',
            headers: {
              'Content-Type': 'text/plain; charset=utf-8'
            },
            body: val 
          }).then(res => alert('发送成功'));
        }
      </script>
    </body>
    </html>
    ''';
  }

  void jumpToRoom(String e) async {
    if (e.isEmpty) {
      ToastUtil.show("链接不能为空");
      return;
    }
    var parseResult = await parse(e);
    if (parseResult.isEmpty || parseResult.first == "") {
      ToastUtil.show("无法解析此链接");
      return;
    }
    String platform = parseResult[1];

    AppNavigator.toLiveRoomDetail(
      liveRoom: LiveRoom(
        roomId: parseResult.first,
        platform: platform,
        title: "",
        cover: '',
        nick: "",
        watching: '',
        avatar: "",
        area: '',
        liveStatus: LiveStatus.live,
        status: true,
        data: '',
        danmakuData: '',
      ),
    );
  }

  Future<List> parse(String url) async {
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
    dio.Response response = await dio.Dio().get(
      realUrl,
      options: dio.Options(followRedirects: true, headers: headers, maxRedirects: 100),
    );
    final liveResponseRegExp = RegExp(r"/reflow/(\d+)");
    String reflow = liveResponseRegExp.firstMatch(response.realUri.toString())?.group(0) ?? "";
    var liveResponse = await dio.Dio().get(
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
      await dio.Dio().get(url, options: dio.Options(followRedirects: false));
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
