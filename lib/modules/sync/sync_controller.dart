import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/plugins/local_http.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/common/services/settings_service.dart';

class SyncController extends BaseController {
  final settingServer = Get.find<SettingsService>();
  NetworkInfo networkInfo = NetworkInfo();
  var ipAddress = ''.obs;
  var port = '9527'.obs;
  var isFiretloader = true.obs;
  @override
  void onInit() {
    super.onInit();
    initIpAddresses();
    LocalHttpServer().startServer(port.value);
    Timer(const Duration(seconds: 2), () {
      isFiretloader.value = false;
    });
  }

  @override
  void onClose() {
    LocalHttpServer().closeServer();
    super.onClose();
  }

  Future<void> initIpAddresses() async {
    ipAddress.value = await getLocalIP();
    port.value = settingServer.webPort.value;
  }

  Future<String> getLocalIP() async {
    var ip = await networkInfo.getWifiIP();
    if (ip == null || ip.isEmpty) {
      var interfaces = await NetworkInterface.list();
      var ipList = <String>[];
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type.name == 'IPv4' && !addr.address.startsWith('127') && !addr.isMulticast && !addr.isLoopback) {
            ipList.add(addr.address);
            break;
          }
        }
      }
      ip = ipList.join(';');
    }
    return ip;
  }
}
