import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_controller.dart';
import 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_model.dart';
import 'package:pure_live/services/cookie_manager/cookie_value.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Loads account info (versioned to avoid crosstalk), switches login state
/// and clears data on logout.
class BilibiliAccountService {
  BilibiliAccountService._();

  static final BilibiliAccountService instance = BilibiliAccountService._();

  int _loadRevision = 0;
  Future<bool>? _activeLoad;
  String? _activeLoadCookie;

  String get currentCookie => normalizeAccountCookie(SettingsService.to.cookieState.bilibiliCookie);

  bool get isLogined => currentCookie.isNotEmpty;

  /// Fetches and publishes account info. Concurrent loads for the same cookie
  /// are deduplicated into one request.
  Future<bool> loadUserInfo() {
    final cookie = currentCookie;
    if (cookie.isEmpty) {
      _loadRevision++;
      _clearLocalAccountState();
      return Future.value(false);
    }
    final activeLoad = _activeLoad;
    if (_activeLoadCookie == cookie && activeLoad != null) return activeLoad;

    final revision = ++_loadRevision;
    late final Future<bool> task;
    task = _loadAndCommit(cookie, revision).whenComplete(() {
      if (identical(_activeLoad, task)) {
        _activeLoad = null;
        _activeLoadCookie = null;
      }
    });
    _activeLoadCookie = cookie;
    _activeLoad = task;
    return task;
  }

  Future<bool> _loadAndCommit(String cookie, int revision) async {
    try {
      final result = await fetchAccountInfo(cookie);
      if (!_isCurrent(cookie, revision)) return false;
      if (result == null) return false;
      if (result['code'] != 0) {
        // Session expired: clear the local sign-in state.
        await logout();
        return false;
      }
      final rawData = result['data'];
      if (rawData is! Map) return false;
      final info = BilibiliUserInfo.fromJson(Map<String, dynamic>.from(rawData));
      if (!_isCurrent(cookie, revision)) return false;
      final accountName = info.uname?.trim() ?? '';
      if (accountName.isEmpty) return false;

      _commitState(BilibiliAccountModel(isLogined: true, name: accountName, uid: info.mid ?? 0));
      SettingsService.to.cookieManager.setBilibiliUid(info.mid ?? 0);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isCurrent(String cookie, int revision) => revision == _loadRevision && currentCookie == cookie;

  void _commitState(BilibiliAccountModel model) {
    final container = SettingsService.to.container;
    if (container == null) return;
    container.read(bilibiliAccountControllerProvider.notifier).applyState(model);
  }

  void _clearLocalAccountState() {
    _commitState(const BilibiliAccountModel());
    SettingsService.to.cookieManager.setBilibiliUid(0);
  }

  /// Stores the cookie and triggers an account info load.
  void setCookie(String cookie) {
    final normalized = normalizeAccountCookie(cookie);
    SettingsService.to.cookieManager.setBilibiliCookie(normalized);
    if (normalized.isNotEmpty) {
      // ignore: unawaited_futures
      loadUserInfo();
    } else {
      _loadRevision++;
      _clearLocalAccountState();
    }
  }

  /// Signs out: clears the cookie and resets local account state.
  Future<void> logout() async {
    _loadRevision++;
    SettingsService.to.cookieManager.setBilibiliCookie('');
    _clearLocalAccountState();
  }

  /// Requests the Bilibili account info endpoint.
  static Future<Map<String, dynamic>?> fetchAccountInfo(String cookie) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/member/web/account',
      header: {'Cookie': cookie},
    );
    if (result is! Map) return null;
    return Map<String, dynamic>.from(result);
  }
}
