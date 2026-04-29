import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';

class DouyinCookiePageController extends GetxController {
  final NativeTextFieldController cookieInputController = NativeTextFieldController();
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
    fullServerUrl.value = "http://$primaryIp:8081";
    startServer(primaryIp);
  }

  void startServer(String ip) async {
    try {
      // 绑定 8081 端口
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);
      log("局域网服务启动: http://$ip:8081");

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
                cookieInputController.text = rawContent;
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
      <title>PureLive 抖音TTwid设置</title>
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
        <p style="color: #666; font-size: 14px;">在下方粘贴抖音TTwid：</p>
        <textarea id="txt" placeholder="例如：ttwid=1%7C--0MPh3MpA0gX9yT-vHmlb_46cFNCnsiAlJOHRfr3YM%7C1773799086%7Cf473d61a0e2d798dd67f0b78e54606cfed48136a10c0ee2dcdba3f3cde518336"></textarea>
        <button onclick="send()">立即发送</button>
      </div>
      <script>
        function send() {
          const val = document.getElementById('txt').value;
          if(!val) return alert('内容不能为空');
          
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

  void setTTwid(String e) async {
    final SettingsService settings = Get.find<SettingsService>();
    settings.douyinCookie.value = e;
    ToastUtil.show("TTwid已设置");
  }
}
