import 'cookie_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_controller.dart';

part 'cookie_controller.g.dart';

@riverpod
class CookieController extends _$CookieController {
  static CookieController get to => SettingsService.to.cookieManager;
  @override
  CookieModel build() {
    return CookieModel(
      bilibiliCookie: HivePrefUtil.getString('bilibiliCookie') ?? '',
      bilibiliUid: HivePrefUtil.getInt('bilibiliUid') ?? 0,
      huyaCookie: HivePrefUtil.getString('huyaCookie') ?? '',
      douyinCookie: HivePrefUtil.getString('douyinCookie') ?? '',
      kuaishouCookie: HivePrefUtil.getString('kuaishouCookie') ?? '',
    );
  }

  void updateCookies(CookieModel newCookies) {
    state = newCookies;
    _persist();
  }

  void clearAllCookies() {
    state = const CookieModel();
    _persist();
  }

  void _persist() {
    HivePrefUtil.setString('bilibiliCookie', state.bilibiliCookie);
    HivePrefUtil.setInt('bilibiliUid', state.bilibiliUid);
    HivePrefUtil.setString('huyaCookie', state.huyaCookie);
    HivePrefUtil.setString('douyinCookie', state.douyinCookie);
    HivePrefUtil.setString('kuaishouCookie', state.kuaishouCookie);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = CookieModel.fromJson(json);
    _persist();
    ref.read(bilibiliAccountControllerProvider.notifier).loadUserInfo();
  }
}
