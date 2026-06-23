import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pure_live/pagination/models/base_controller_state.dart';

mixin BaseControllerMixin {
  BaseControllerState controllerState = const BaseControllerState();

  Future<bool> checkNetworkBeforeRequest() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty) {
        handleError("network_disconnected");
        return false;
      }
    } catch (_) {
      return true;
    }
    return true;
  }

  void handleError(Object exception) {
    String msg = exceptionToString(exception);
    if (exception == "network_disconnected") {
      msg = "网络连接已断开，请检查网络设置";
    }

    final exceptionStr = exception.toString().toLowerCase();
    final isLoginIssue =
        exceptionStr.contains("loginrequired") || exceptionStr.contains("unauthorized") || exceptionStr.contains("未登录");

    controllerState = controllerState.copyWith(errorMsg: msg, notLogin: isLoginIssue, pageError: !isLoginIssue);
  }

  String exceptionToString(Object exception) {
    if (exception is String) return exception;
    String msg = exception.toString().replaceAll("Exception:", "").trim();
    if (msg.isEmpty) {
      msg = "未知错误，请重试";
    }
    return msg;
  }

  void onLogin() => controllerState = controllerState.copyWith(notLogin: false);
  void onLogout() => controllerState = controllerState.copyWith(notLogin: true);
}
