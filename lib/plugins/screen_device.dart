import 'dart:io';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum Device { phone, pad, tv }

class ScreenDevice {
  static final deviceInfoPlugin = DeviceInfoPlugin();

  static Future<Device> getDeviceType() async {
    if (Platform.isWindows) return Device.tv;
    final deviceInfo = await deviceInfoPlugin.deviceInfo;
    final dm = deviceInfo.data['displayMetrics'];
    double x = math.pow(dm['widthPx'] / dm['xDpi'], 2).toDouble();
    double y = math.pow(dm['heightPx'] / dm['yDpi'], 2).toDouble();
    double screenInches = math.sqrt(x + y);
    if (screenInches > 18.0) {
      return Device.tv;
    } else if (screenInches > 7.0 && screenInches <= 18.0) {
      return Device.pad;
    }
    return Device.phone;
  }

  static autoStartWebServer() async {
    await const Duration(seconds: 2).delay();
    var device = await getDeviceType();
    if (Platform.isAndroid && device == Device.tv) {
      final SettingsService service = Get.find<SettingsService>();
      if (!service.webPortEnable.value) {
        service.webPortEnable.value = true;
      }
    }
  }
}
