import '../cookie_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_model.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_service.dart';

part 'bilibili_account_controller.g.dart';

/// 同步自 pure_live：B 站账号状态控制器（业务逻辑在 BilibiliAccountService）。
@riverpod
class BilibiliAccountController extends _$BilibiliAccountController {
  @override
  BilibiliAccountModel build() {
    ref.listen(cookieControllerProvider, (prev, next) {
      if (prev?.bilibiliCookie != next.bilibiliCookie) {
        if (next.bilibiliCookie.isEmpty) {
          state = const BilibiliAccountModel();
        } else {
          BilibiliAccountService.instance.loadUserInfo();
        }
      }
    });

    final cookie = ref.read(cookieControllerProvider).bilibiliCookie;
    if (cookie.isNotEmpty) {
      BilibiliAccountService.instance.loadUserInfo();
    }

    return BilibiliAccountModel(isLogined: cookie.isNotEmpty);
  }

  /// 由 BilibiliAccountService 提交最新的账号状态。
  void applyState(BilibiliAccountModel model) {
    if (state == model) return;
    state = model;
  }

  Future<bool> loadUserInfo() => BilibiliAccountService.instance.loadUserInfo();

  Future<void> logout() async {
    await BilibiliAccountService.instance.logout();
    state = const BilibiliAccountModel();
  }

  @visibleForTesting
  Map<String, dynamic>? parseAccountPayload(dynamic result) {
    if (result is! Map) return null;
    return Map<String, dynamic>.from(result);
  }
}
