import 'dart:io';
import 'dart:convert';
import 'dart:io' as io;
import 'package:get/get.dart';
import 'package:dia/dia.dart';
import 'package:path/path.dart' as p;
import 'package:dia_cors/dia_cors.dart';
import 'package:dia_body/dia_body.dart';
import 'package:dia_static/dia_static.dart';
import 'package:pure_live/common/index.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dia_router/dia_router.dart' as dia_router;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';

class ContextRequest extends Context with dia_router.Routing, ParsedBody {
  ContextRequest(super.request);
}

final app = App((req) => ContextRequest(req));

class LocalHttpServer {
  final SettingsService settings = Get.find<SettingsService>();
  Future<void> readAssetsFiles() async {
    final assets = await rootBundle.loadString('AssetManifest.json');
    var assetList = jsonDecode(assets) as Map<String, dynamic>;
    assetList.removeWhere((key, value) => !key.startsWith('assets/pure_live_web'));
    final directory = await getApplicationCacheDirectory();
    for (final assetPath in assetList.keys) {
      final assetData = await rootBundle.load(assetPath);
      final file = File('${directory.path}/$assetPath');
      await file.create(recursive: true);
      await file.writeAsBytes(assetData.buffer.asUint8List());
    }
  }

  void startServer(String port) async {
    try {
      final connectivityResults = await (Connectivity().checkConnectivity());
      for (var connectivityResult in connectivityResults) {
        if (connectivityResult == ConnectivityResult.none) {
          SmartDialog.showToast('请在局域网下使用', displayTime: const Duration(seconds: 2));
          return;
        }
      }

      await readAssetsFiles();
      final directory = await getApplicationCacheDirectory();

      app.use(serve(p.join(directory.path, 'assets${Platform.pathSeparator}pure_live_web'),
          prefix: '/pure_live', index: 'index.html'));
      app.use(body());
      app.use(cors());
      final router = dia_router.Router('/api');
      router.get('/getSettings', (ctx, next) async {
        ctx.body = jsonEncode(settings.toJson());
      });
      router.post('/setSettings', (ctx, next) async {
        var settingStrings = ctx.query['settings'];
        ctx.body = settingStrings != null ? jsonEncode({'data': true}) : jsonEncode({'data': false});
        try {
          settings.fromJson(jsonDecode(settingStrings!));
          SmartDialog.showToast('同步成功', displayTime: const Duration(seconds: 4));
        } catch (e) {
          SmartDialog.showToast('同步失败', displayTime: const Duration(seconds: 4));
        }
      });
      router.post('/uploadFile', (ctx, next) async {
        try {
          ctx.body = jsonEncode({'data': true});
        } catch (e) {
          ctx.body = jsonEncode({'data': false});
        }
      });

      app.use(router.middleware);
      app.use((ctx, next) async {
        if (ctx.query['type'] != null) {
          String? type = ctx.query['type'];
          if (type == 'uploadM3u8File') {
            FileRecoverUtils().recoverM3u8BackupByWeb(ctx.parsed['file'], ctx.parsed['name']);
          } else if (type == 'uploadRecoverFile') {
            var dir = await getApplicationCacheDirectory();
            final file = File('${dir.path}${Platform.pathSeparator}${ctx.parsed['name']}');
            file.writeAsStringSync(ctx.parsed['file']);
            if (settings.recover(file)) {
              SmartDialog.showToast("恢复备份成功", displayTime: const Duration(seconds: 2));
            } else {
              SmartDialog.showToast("恢复备份失败", displayTime: const Duration(seconds: 2));
            }
          } else {
            next();
          }
        } else {
          next();
        }
      });

      app.listen(io.InternetAddress.anyIPv4.address, int.parse(port));
      settings.webPort.value = port;
      settings.webPortEnable.value = true;
    } catch (e) {
      settings.webPortEnable.value = false;
      settings.httpErrorMsg.value = e.toString();
    }
  }

  Future<void> closeServer() async {
    app.close();
  }
}
