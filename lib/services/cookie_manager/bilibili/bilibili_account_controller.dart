import '../cookie_controller.dart';
import 'package:pure_live/core/network/http_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/bilibili_user_info/bilibili_user_info.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_model.dart';

part 'bilibili_account_controller.g.dart';

@riverpod
class BilibiliAccountController extends _$BilibiliAccountController {
  @override
  BilibiliAccountModel build() {
    ref.listen(cookieControllerProvider, (prev, next) {
      if (prev?.bilibiliCookie != next.bilibiliCookie) {
        if (next.bilibiliCookie.isEmpty) {
          state = const BilibiliAccountModel();
        } else {
          loadUserInfo();
        }
      }
    });

    final cookie = ref.read(cookieControllerProvider).bilibiliCookie;
    if (cookie.isNotEmpty) loadUserInfo();

    return BilibiliAccountModel(isLogined: cookie.isNotEmpty);
  }

  Future<void> loadUserInfo() async {
    final cookie = ref.read(cookieControllerProvider).bilibiliCookie;
    if (cookie.isEmpty) return;

    try {
      final result = await HttpClient.instance.getJson(
        "https://api.bilibili.com/x/member/web/account",
        header: {"Cookie": cookie},
      );

      if (result == null || result["code"] != 0) {
        logout();
        return;
      }

      final info = BilibiliUserInfo.fromJson(result["data"]);
      state = state.copyWith(isLogined: true, name: info.uname ?? '未登录', uid: info.mid ?? 0);
    } catch (_) {
      // 处理错误
    }
  }

  void logout() async {
    ref.read(cookieControllerProvider.notifier).clearAllCookies();
    state = const BilibiliAccountModel();
  }
}
